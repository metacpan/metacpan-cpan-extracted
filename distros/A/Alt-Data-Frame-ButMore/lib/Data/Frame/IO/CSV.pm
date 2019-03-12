package Data::Frame::IO::CSV;

# ABSTRACT: Partial class for data frame's conversion from/to CSV

use Data::Frame::Role;
use namespace::autoclean;

use PDL::Core qw(pdl null);
use PDL::Primitive ();
use PDL::Factor    ();
use PDL::SV        ();
use PDL::DateTime  ();
use PDL::Types     ();

use Data::Munge qw(elem);
use Package::Stash;
use Ref::Util qw(is_plain_arrayref is_plain_hashref);
use Scalar::Util qw(openhandle looks_like_number);
use Type::Params;
use Types::Standard qw(Any ArrayRef CodeRef Enum HashRef Map Maybe Str);
use Types::PDL qw(Piddle);
use Text::CSV;

use Data::Frame::Util qw(guess_and_convert_to_pdl);
use Data::Frame::Types qw(DataType);


classmethod from_csv ($file, :$header=true, :$sep=",", :$quote='"',
                      :$na=[qw(NA BAD)], :$col_names=undef, :$row_names=undef,
                      Map[Str, DataType] :$dtype={},
                      :$strings_as_factors=false
  ) {
    state $check = Type::Params::compile(
        ( ArrayRef [Str] )->plus_coercions( Any, sub { [$_] } ) );
    ($na) = $check->($na);

    # TODO
    my $check_name = sub {
        my ($name) = @_;
        return $name;
    };

    my $csv = Text::CSV->new(
        {
            binary    => 1,
            auto_diag => 1,
            sep       => $sep,
            quote     => $quote
        }
    );

    my $fh = openhandle($file);
    unless ($fh) {
        open $fh, "<:encoding(utf8)", "$file" or die "$file: $!";
    }
    my @col_names;
    if ( defined $col_names ) {
        @col_names = $col_names->flatten;
    }
    else {
        if ($header) {
            eval {
                # suppress possible warning message on parsing header
                $csv->auto_diag(0);
                $csv->header( $fh, { munge_column_names => 'none' } );
                @col_names = $csv->column_names;
            };
            $csv->auto_diag(1);    # restore auto_diag
            if ($@) {

                # rewind as first line read by $csv->header
                seek( $fh, 0, 0 );
                my $first_row = $csv->getline($fh);
                @col_names = @$first_row;
            }
        }
    }

    # if first column has no header, we take this first column as row names.
    my $row_names_from_first_column = ( length( $col_names[0] ) == 0 );
    if ($row_names_from_first_column) {
        shift @col_names;
    }
    @col_names = map { $check_name->($_) } @col_names;

    my %columns = map { $_ => [] } @col_names;

    my @row_names;
    my $rows = $csv->getline_all($fh);
    for my $row (@$rows) {
        my $offset = 0;
        if ($row_names_from_first_column) {
            push @row_names, $row->[0];
            $offset = 1;
        }
        for my $i ( 0 .. $#col_names ) {
            my $col = $col_names[$i];
            push @{ $columns{$col} }, $row->[ $i + $offset ];
        }
    }

    if ($row_names_from_first_column) {
        $row_names = \@row_names;
    }
    else {
        if ( defined $row_names ) {
            if ( looks_like_number($row_names) ) {
                my $col_index = int($row_names);
                $row_names = $columns{ $col_names[$col_index] };
            }
        }
    }

    state $additional_type_to_piddle = {
        datetime => sub { PDL::DateTime->new_from_datetime($_[0]) },
        factor   => sub { PDL::Factor->new($_[0]) },
        logical  => sub { PDL::Logical->new($_[0]) },
    };
    my $package_pdl_core = Package::Stash->new('PDL::Core');
    my $to_piddle = sub {
        my ($name) = @_;
        my $x = $columns{$name};

        if ( my $type = $dtype->{$name} ) {
            my $f_new = $additional_type_to_piddle->{$type}
              // $package_pdl_core->get_symbol("&$type");
            if ($f_new) {
                return $f_new->($x);
            }
            else {
                die "Invalid data type '$type'";
            }
        }
        else {
            return guess_and_convert_to_pdl(
                $x,
                na                 => $na,
                strings_as_factors => $strings_as_factors
            );
        }
    };

    my $df = $class->new(
        columns => [
            map {
                $_ => $to_piddle->($_),
            } @col_names
        ],
        ( $row_names ? ( row_names => $row_names ) : () ),
    );

    return $df;
}


method to_csv ($file, :$sep=',', :$quote='"', :$na='NA',
               :$col_names=true, :$row_names=true) {
    my $csv = Text::CSV->new(
        {
            binary    => 1,
            auto_diag => 1,
            sep       => $sep,
            quote     => $quote,
            eol       => "\n",
        }
    );

    my $fh = openhandle($file);
    unless ($fh) {
        open $fh, ">", "$file" or die "$file: $!";
    }

    my $row_names_data = $row_names ? $self->row_names : undef;
    if ($col_names) {
        my @header = ( ( $row_names ? '' : () ), @{ $self->names } );
        $csv->print( $fh, \@header );
    }

    # a hash to store isbad info for each column
    my %is_bad = map { $_ => $self->at($_)->isbad; } ( $self->names->flatten );

    for ( my $i = 0 ; $i < $self->nrow ; $i++ ) {
        my @row = (
            ( $row_names ? $row_names_data->at($i) : () ),
            (
                map { $is_bad{$_}->at($i) ? $na : $self->at($_)->at($i); }
                  @{ $self->names }
            )
        );
        $csv->print( $fh, \@row );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Frame::IO::CSV - Partial class for data frame's conversion from/to CSV

=head1 VERSION

version 0.0041

=head1 METHODS

=head2 from_csv

    from_csv($file, :$header=true, :$sep=',', :$quote='"',
             :$na=[qw(NA BAD)], :$col_names=undef, :$row_names=undef, 
             Map[Str, DataType] :$dtype={},
             :$strings_as_factors=false)

Create a data frame object from a CSV file. For example, 

    my $df = Data::Frame->from_csv("foo.csv");

Some of the parameters are explained below,

=over 4

=item *

C<$file> can be a file name string, a Path::Tiny object, or an opened file

handle.

=item *

C<$dtype> is a hashref associating column names to their types. Types

can be the PDL type names like C<"long">, C<"double">, or names of some PDL's
derived class like C<"PDL::SV">, C<"PDL::Factor">, C<"PDL::DateTime">. If a
column is not specified in C<$dtype>, its type would be automatically
decided.

=back

=head2 to_csv

    to_csv($file, :$sep=',', :$quote='"', :$na='NA',
           :$col_names=true, :$row_names=true)

Write the data frame to a csv file.

=head1 AUTHORS

=over 4

=item *

Zakariyya Mughal <zmughal@cpan.org>

=item *

Stephan Loyd <sloyd@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014, 2019 by Zakariyya Mughal, Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
