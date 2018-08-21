# NAME

CSV::Processor - Set of different methods that adds new columns in csv files

# VERSION

version 1.01

# SYNOPSIS

    use CSV::Processor;
    my $bot = CSV::Processor->new( file => 'test.csv', has_column_names => 1 );    
    $bot->add_email(5, 6, %params);            # 5 and 6 are column numbers where input and output data located
    
    $bot->add_email('URL', 'EMAIL');  # 'URL' 'EMAIL' are field names where data will be stored

# DESCRIPTION

Set of ready-to-use useful csv file processors based on [Text::AutoCSV](https://metacpan.org/pod/Text::AutoCSV) and other third-party modules

E.g. from the box you can add email by url using [Email::Extractor](https://metacpan.org/pod/Email::Extractor)

Pull requests are welcome ;)

Also this module includes command line utilitie, [csvprocess](https://metacpan.org/pod/csvprocess) and  [csvjoin](https://metacpan.org/pod/csvjoin)

# AUTHORS

Pavel Serkov <pavelsr@cpan.org>

# new

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

# rw\_wrapper

Wrapper under ["set\_walker\_ar" in Text::AutoCSV](https://metacpan.org/pod/Text::AutoCSV#set_walker_ar) / ["field\_add\_computed" in Text::AutoCSV](https://metacpan.org/pod/Text::AutoCSV#field_add_computed).
Helper for easy implementing new processor

    $self->rw_wrapper( $in_field, $out_field, sub {
        my $in_field_value = shift;
        return do_some( $in_field_value );
    }, %params );

# add\_email

Try to extract email by website column using ["search\_until\_attempts" in Email::Extractor](https://metacpan.org/pod/Email::Extractor#search_until_attempts) (wrapper for this method)

    $bot->add_email(5);
    $bot->add_email(5, 6);
    $bot->add_email('URL');
    $bot->add_email('URL', 'EMAIL');
    $bot->add_email('URL', 'EMAIL', attempts => 5, human_numbering => 1);

# add\_same

    $bot->add_same( $in_column, $out_column, value => $f );

Add same value to each row. Value is specified in `value` param

# AUTHOR

Pavel Serikov <pavelsr@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
