# NAME

App::ygeo - Extract companies data from Yandex Maps to csv file

# VERSION

version 0.02

# SYNOPSIS

    use App::ygeo;
    my $ygeo = App::ygeo->new( apikey => '12345', city => "ROV" );
    $ygeo->get_and_print(text => 'autoservice', city => 'ROV', csv_filename => 'auto.csv', verbose => 1);

# DESCRIPTION

By default it:

get data about maximum 500 companies (Yandex API restriction)

Order of looking for apikey 

\- provided params

\- `.ygeo` file (firsty it search `.ygeo` file in current directory, then in home directory)

`.ygeo` config has yaml syntax. You can reuse [App::ygeo::yaml](https://metacpan.org/pod/App::ygeo::yaml) in your own projects

## get\_and\_print

    $ygeo->get_and_print(text => 'autoservice', city => 'ROV', csv_filename => 'auto.csv', verbose => 1);

Get and prints data in csv data

Params:

text - search text

city - city to search, e.g. ROV is Rostov-on-Don

csv\_filename - name of output csv file

results\_limit -number of results returned

Columns sequence is according ["to\_array" in Yandex::Geo::Company](https://metacpan.org/pod/Yandex::Geo::Company#to_array) method

Results are printed to csv like

    my $res = $yndx_geo->y_companies( $text );
    for my $company (@$res) {
        $csv->print( $fh, $company->to_array );
    }

Return 1 if finished fine

# AUTHOR

Pavel Serikov <pavelsr@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
