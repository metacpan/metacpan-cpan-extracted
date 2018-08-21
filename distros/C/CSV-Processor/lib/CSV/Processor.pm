package CSV::Processor;
$CSV::Processor::VERSION = '1.01';

#ABSTRACT: Set of different methods that adds new columns in csv files


use Text::AutoCSV;
use Email::Extractor;
use Regexp::Common;
use Carp;
use CSV::Processor::Utils qw( insert_after_index make_prefix);
use Data::Dumper;
use feature 'say';


sub new {
    my ( $class, %param ) = @_;

    my $prefix = $param{prefix} || 'p_';

    die "No input file defined" unless ( $param{file} || $param{in_file} );
    $param{in_file} = $param{file} unless defined $param{in_file};

    # $param{file} processor

    my $csv = Text::AutoCSV->new(
        in_file  => $param{in_file},
        encoding => $param{encoding} || 'UTF-8',    # || 'windows1251',
        out_file => $param{out_file} || make_prefix( $param{in_file}, $prefix ),
        out_encoding => 'UTF-8',
        verbose      => $param{verbose} || 0
    );

    $param{auto_csv} = $csv;
    $param{human_numbering} = 0 if !defined $params{human_numbering};

    bless {%param}, $class;
}

sub auto_csv {
    shift->{auto_csv};
}


sub rw_wrapper {
    my ( $self, $in_field, $out_field, $callback, %params ) = @_;

    $params{verbose} = $self->auto_csv->{verbose} || $self->{verbose}
      if !defined $params{verbose};

    if ( $in_field =~ /$RE{num}{int}/ && $out_field =~ /$RE{num}{int}/ ) {

        say
          "Assuming that you specified column numbers at in and out parameters"
          if $params{verbose};

        if ( $self->{human_numbering} || $params{human_numbering} ) {
            say "Human numbering in use, first column index is 1 not 0"
              if $params{verbose};
            $in_field++;
            $out_field++;
        }

        my $row_number = 0;

        $self->auto_csv->set_walker_ar(
            sub {
                # do some stuff with $_[0]->[$in_field];
                my $row_arrayed = $_[0];
                print "Row $row_number\t";

                if ( $row_arrayed->[$in_field] ne '' ) {
                    print 'In: ' . $row_arrayed->[$in_field] . "\t"
                      if $params{verbose};
                    my $res = $callback->( $row_arrayed->[$in_field], );
                    print 'Out : ' . $res . "\n" if $params{verbose};
                    insert_after_index( $out_field - 1, $res, $row_arrayed );

                }
                else {
                    print "In: undef\tOut: undef\n" if $params{verbose};
                }
                $row_number++;
                return $row_arrayed;
            }
        )->write();

    }
    else {

        # try to detect field names automatically
        my @fields = $self->auto_csv->get_fields_names();

        say "Assuming that you specified column names at in and out parameters"
          if $params{verbose};
        say "Auto detected field names : " . join( ',', @fields )
          if $params{verbose};

        $self->auto_csv->field_add_computed(
            $out_field,
            sub {
                my $hr = $_[1];
                print 'In: ' . $hr->{$in_field} . "\t" if $params{verbose};
                $hr->{$out_field} = $callback->( $hr->{$in_field} );
                print 'Out : ' . $hr->{$out_field} . "\n" if $params{verbose};
                return $hr->{$out_field};
            }
        )->write();

    }

    # $self->auto_csv->write();
}


sub add_email {
    my ( $self, $in_field, $out_field, %params ) = @_;

    $params{attempts} = 5       if !defined $params{attempts};
    $in_field         = 'URL'   if !defined $in_field;
    $out_field        = 'EMAIL' if !defined $out_field;

    $self->rw_wrapper(
        $in_field,
        $out_field,
        sub {
            my $url = shift;
            my $crawler = Email::Extractor->new( verbose => $params{verbose} );
            my $emails =
              $crawler->search_until_attempts( $url, $params{attempts} );
            my $emails_str = join( ',', @$emails );
            return $emails_str;
        }
    );

}


sub add_same {
    my ( $self, $in_field, $out_field, %params ) = @_;
    die "Output field is not specified" unless defined $params{value};
    $self->rw_wrapper( $in_field, $out_field, sub { return $params{value} } );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CSV::Processor - Set of different methods that adds new columns in csv files

=head1 VERSION

version 1.01

=head1 SYNOPSIS

    use CSV::Processor;
    my $bot = CSV::Processor->new( file => 'test.csv', has_column_names => 1 );    
    $bot->add_email(5, 6, %params);            # 5 and 6 are column numbers where input and output data located
    
    $bot->add_email('URL', 'EMAIL');  # 'URL' 'EMAIL' are field names where data will be stored

=head1 DESCRIPTION

Set of ready-to-use useful csv file processors based on L<Text::AutoCSV> and other third-party modules

E.g. from the box you can add email by url using L<Email::Extractor>

Pull requests are welcome ;)

Also this module includes command line utilitie, L<csvprocess> and  L<csvjoin>

=head1 AUTHORS

Pavel Serkov <pavelsr@cpan.org>

=head1 new

Constructor

parameters

    C<file>
    C<encoding>
    C<column_names>
    C<human_numbering>
    C<eol>
    C<sep_char>
    C<prefix>
    C<verbose>

=head1 rw_wrapper

Wrapper under L<Text::AutoCSV/set_walker_ar> / L<Text::AutoCSV/field_add_computed>.
Helper for easy implementing new processor

    $self->rw_wrapper( $in_field, $out_field, sub {
        my $in_field_value = shift;
        return do_some( $in_field_value );
    }, %params );

=head1 add_email

Try to extract email by website column using L<Email::Extractor/search_until_attempts> (wrapper for this method)

    $bot->add_email(5);
    $bot->add_email(5, 6);
    $bot->add_email('URL');
    $bot->add_email('URL', 'EMAIL');
    $bot->add_email('URL', 'EMAIL', attempts => 5, human_numbering => 1);

=head1 add_same

    $bot->add_same( $in_column, $out_column, value => $f );

Add same value to each row. Value is specified in C<value> param

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
