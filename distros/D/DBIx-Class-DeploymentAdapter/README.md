# NAME

DBIx::Class::DeploymentAdapter - Deployment handler adapter to your DBIC app, which offers some candy

# SYNOPSIS

    use DBIx::Class::DeploymentAdapter;

    my $args = {
        schema              => $schema,
        script_directory    => './share/migrations',
        databases           => ['MySQL'],
        sql_translator_args => { mysql_enable_utf8 => 1 },
    };

    $args->{to_version}      = $to_version      if $to_version;
    $args->{force_overwrite} = $force_overwrite if $force_overwrite;

    my $da = DBIx::Class::DeploymentAdapter->new($args);

# DESCRIPTION

Deployment handler adapter to your DBIC app, which offers some candy

## install

Installs the schema files to the given Database

    $da->install;

## prepare

Summarize all prepares from [DBIx::Class::DeploymentHandler](https://metacpan.org/pod/DBIx::Class::DeploymentHandler) in one Command

    $da->prepare;

## status

Returns the Status of database and schema versions as string

    $da->status;

## upgrade\_incremental

Upgrade the database version step by step, if anything wents wrong, it dies with the specific database error.

You can give a target version to the method to make it stop there

    $da->upgrade_incremental;
    $da->upgrade_incremental(112);

# LICENSE

Copyright (C) Patrick Kilter.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Patrick Kilter <pk@gassmann.it>
