# ABSTRACT: Extract companies data from Yandex Maps to csv file

package App::ygeo;
$App::ygeo::VERSION = '0.02';


use strict;
use warnings;
use Text::CSV;
use Carp;
use Yandex::Geo;
use Yandex::Geo::Company;
use utf8;

use feature 'say';

$SIG{__DIE__} = sub {
    my $trace = Carp::longmess( $_[0] );
    $trace =~ s/^(.+\n)\s*at\s+.+\s+line\s+\d+\.\s*\n/$1/;
    die $trace;
};

sub new {
    my ( $class, %params ) = @_;
    croak "No yandex maps api key provided"
      unless defined $params{apikey} && length $params{apikey};
    bless {%params}, $class;
}

# Split array-like properties into separate column names
# Used for generation csv header or filling data

# it's impossible to analyse real data cause it can be undef

# Return
# array with new column names if column with array data must be splited to separate columns
# or just string with column name in other cases

# Only properties with ARRAY definition can be splited

sub _col_names_arr_if_split {
    my ( $p, $properties, $split_columns ) = @_;

    # Return name of column if its type is string
    if ( _isin( $p, $properties->{string} ) ) {
        return $p;
    }
    elsif ( _isin( $p, $properties->{array} ) ) {

        if ( defined $split_columns->{$p} ) {

            # Return name of column if column_split value is 1
            return $p if ( $split_columns->{$p} == 1 );

            my @a;
            for my $i ( 1 .. $split_columns->{$p} ) {
                push @a, $p . '_' . $i;
            }

            # Return array of new columns names if corresponded column_split
            return \@a;
        }

        # Return name of column if its type is array
        return $p;

    }
    else {
        croak
'Properties hash is passed bad, please check consistency of string and array keys';
    }
}

# Simple printing without header and each array-type property (e.g. phones and linkls) of L<Yandex::Geo::Company> in newline
# Uses L<Yandex::Company/to_array>
sub _print {
    my ( $text_csv, $fh, $items_array ) = @_;

    for my $company (@$items_array) {
        $text_csv->print( $fh, $company->to_array );
    }

    return 1;
}

# Print with headers and split phones column_split
# Order is like in L<Yandex::Geo::Company/properties> C<{all}>
# Return 0 if data in rows may be inconsistent

sub _print2 {
    my ( $text_csv, $fh, $items_array, $columns_split ) = @_;

    my $result_flag = 1;
    croak "Empty result, nothing to print" unless scalar @$items_array > 0;

    $columns_split = { phones => 3 } unless defined $columns_split;
    my $properties = Yandex::Geo::Company->properties;

    # TO-DO: + validate_properties

    # Print header
    my @header;
    for my $p ( @{ $properties->{all} } ) {
        my $cols = _col_names_arr_if_split( $p, $properties, $columns_split );
        push @header, $cols  if ( ref $cols eq '' );
        push @header, @$cols if ( ref $cols eq 'ARRAY' );
    }
    $text_csv->print( $fh, \@header );

    # Print data
    no warnings 'utf8';
    for my $company (@$items_array) {

        my @row;

        for my $p ( @{ $properties->{all} } ) {

            my $columns =
              _col_names_arr_if_split( $p, $properties, $columns_split );

            # Case: string column, e.g. phones
            if ( ref($columns) eq '' && ref( $company->$p ) eq '' ) {
                push @row, $company->$p;

# if defined $company->$p;
# push @row, undef        unless defined $company->$p;       # correct processing of empty values
                next;
            }

            # Case: column with array datatype but not splited, e.g. links
            if ( ref($columns) eq '' && ref( $company->$p ) eq 'ARRAY' ) {

                # you can define custom post-processors like
                if ( $p eq 'links' ) {
                    push @row, scalar @{ $company->$p };
                    next;
                }

                push @row, join( "\n", @{ $company->$p } );

         # if defined $company->$p;
         # push @row, undef                         unless defined $company->$p;
                next;
            }

            # Case: splited column
            if ( ref($columns) eq 'ARRAY' && ref( $company->$p ) eq 'ARRAY' ) {
                my $fact_size = scalar @{ $company->$p };    # check to not
                my $max_size_acc_split = scalar @$columns;

                my $size = _lower( $max_size_acc_split, $fact_size );
                push @row, $company->$p->[ $_ - 1 ] for ( 1 .. $size );

                if ( $fact_size < $max_size_acc_split ) {
                    my $l = $max_size_acc_split - $fact_size;
                    push @row, undef for ( 1 .. $l );
                }
                next;
            }

        }

        if ( scalar @header != scalar @row ) {
            carp "Row may be formatted wrong, there must be "
              . scalar @header
              . " columns, but it is "
              . scalar @row;
            $result_flag = 0;
        }

        $text_csv->print( $fh, \@row );

    }

    return $result_flag;
}

sub _isin($$) {
    my ( $val, $array_ref ) = @_;

    return 0 unless $array_ref && defined $val;
    for my $v (@$array_ref) {
        return 1 if $v eq $val;
    }

    return 0;
}

# Return lower value from two values
sub _lower {
    my ( $val1, $val2 ) = @_;
    return ( $val1 > $val2 ) ? $val2 : $val1;
}


sub get_and_print {
    my ( $self, %params ) = @_;

    my $text = $params{text};
    croak "No search text defined" unless defined $text && length $text;

    my $city         = $self->{city}         || $params{city};
    my $csv_filename = $params{csv_filename} || $params{text} . '.csv';

    my $csv = Text::CSV->new()
      or die "Cannot use CSV: " . Text::CSV->error_diag();
    $csv->eol("\012");
    $csv->sep_char(";");

    open my $fh, ">:encoding(utf8)", $csv_filename or die "$csv_filename: $!";

    my $yndx_geo = Yandex::Geo->new(
        apikey    => $self->{apikey},
        only_city => $city,
        results   => $params{results_limit} || 500
    );

    my $res = $yndx_geo->y_companies($text);

    no warnings 'utf8';
    say "Search: $text in city: $city"
      if ( $self->{verbose} || $params{verbose} );
    say "Yandex Maps API key: $self->{apikey}"
      if ( $self->{verbose} || $params{verbose} );
    say "Companies found: " . scalar @$res
      if ( $self->{verbose} || $params{verbose} );

    _print2( $csv, $fh, $res, { phones => 3 } );

    close $fh or die "$csv_filename: $!";

    no warnings 'utf8';
    say "Data was written in $csv_filename"
      if ( $self->{verbose} || $params{verbose} );

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ygeo - Extract companies data from Yandex Maps to csv file

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use App::ygeo;
    my $ygeo = App::ygeo->new( apikey => '12345', city => "ROV" );
    $ygeo->get_and_print(text => 'autoservice', city => 'ROV', csv_filename => 'auto.csv', verbose => 1);

=head1 DESCRIPTION

By default it:

get data about maximum 500 companies (Yandex API restriction)

Order of looking for apikey 

- provided params

- C<.ygeo> file (firsty it search C<.ygeo> file in current directory, then in home directory)

C<.ygeo> config has yaml syntax. You can reuse L<App::ygeo::yaml> in your own projects

=head2 get_and_print

    $ygeo->get_and_print(text => 'autoservice', city => 'ROV', csv_filename => 'auto.csv', verbose => 1);

Get and prints data in csv data

Params:

text - search text

city - city to search, e.g. ROV is Rostov-on-Don

csv_filename - name of output csv file

results_limit -number of results returned

Columns sequence is according L<Yandex::Geo::Company/to_array> method

Results are printed to csv like

    my $res = $yndx_geo->y_companies( $text );
    for my $company (@$res) {
        $csv->print( $fh, $company->to_array );
    }

Return 1 if finished fine

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
