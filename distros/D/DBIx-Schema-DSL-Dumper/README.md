# NAME

DBIx::Schema::DSL::Dumper - DBIx::Schema::DSL generator

# SYNOPSIS

    use DBIx::Schema::DSL::Dumper;

    print DBIx::Schema::DSL::Dumper->dump(
        dbh => $dbh,
        pkg => 'Foo::DSL',

        # Optional. Default values is same as follows.
        default_not_null => 0,
        default_unsigned => 0,

        # Optional.
        table_options => +{
            'mysql_table_type' => 'InnoDB',
            'mysql_charset'    => 'utf8',
        }
    );

    # or

    print DBIx::Schema::DSL::Dumper->dump(
        dbh    => $dbh,
        tables => [qw/foo bar/],
    );

# DESCRIPTION

This module generates the Perl code to generate DBIx::Schema::DSL.

# SEE ALSO

[DBIx::Schema::DSL](https://metacpan.org/pod/DBIx::Schema::DSL), [Teng::Schema::Dumper](https://metacpan.org/pod/Teng::Schema::Dumper)

# LICENSE

Copyright (C) Kenta, Kobayashi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kenta, Kobayashi <kentafly88@gmail.com>
