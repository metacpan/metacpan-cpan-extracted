[![Build Status](https://travis-ci.org/tokuhirom/DBIx-Tracer.svg?branch=master)](https://travis-ci.org/tokuhirom/DBIx-Tracer)
# NAME

DBIx::Tracer - Easy tracer for DBI

# SYNOPSIS

    use DBIx::Tracer;

    my $tracer = DBIx::Tracer->new(
        sub {
            my %args = @_;
            say $args{dbh};
            say $args{time};
            say $args{sql};
            say "Bind: $_" for @{$args{bind_params}};
        }
    );

# DESCRIPTION

DBIx::Tracer is easy tracer for DBI. You can trace a SQL queries without 
modifying configuration in your application.

You can insert snippets using DBIx::Tracer, and profile it.

# GUARD OBJECT

DBIx::Tracer uses Scope::Guard-ish guard object strategy.

`DBIx::Tracer->new` installs method modifiers, and `DBIx::Tracer->DESTROY` uninstall method modifiers.

You must keep the instance of DBIx::Trace in the context.

# METHODS

- DBIx::Tracer->new(CodeRef: $code)

        my $tracer = DBIx::Tracer->new(
            sub { ... }
        );

    Create instance of DBIx::Tracer. Constructor takes callback function, will call on after each queries executed.

    You must keep this instance you want to logging. Destructor uninstall method modifiers.

# CALLBACK OPTIONS

DBIx::Tracer passes following parameters to callback function.

- dbh

    instance of $dbh.

- sql

    SQL query in string.

- bind\_params : ArrayRef\[Str\]

    binded parameters for the query in arrayref.

- time

    Elapsed times for query in floating seconds.

# FAQ

- Why don't you use Callbacks feature in DBI?

    I don't want to modify DBI configuration in my application for tracing.

# AUTHOR

Tokuhiro Matsuno &lt;tokuhirom AAJKLFJEF@ GMAIL COM>

# THANKS TO

xaicron is author of [DBIx::QueryLog](https://metacpan.org/pod/DBIx::QueryLog). Most part of DBIx::Tracer was taken from DBIx::QueryLog.

# SEE ALSO

[DBIx::QueryLog](https://metacpan.org/pod/DBIx::QueryLog)

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
