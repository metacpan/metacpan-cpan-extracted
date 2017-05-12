# NAME

App::BigQuery::Importer::MySQL - BigQuery data importer from MySQL tables.

# SYNOPSIS

    use App::BigQuery::Importer::MySQL

# DESCRIPTION

App::BigQuery::Importer::MySQL is BigQuery data importer from MySQL tables.

**THE SOFTWARE IS ALPHA QUALITY. API MAY CHANGE WITHOUT NOTICE.**

# REQUIRED COMMANDS

    mysql client cli
    gcloud cli

## OPERATION VERIFICATION COMMAND VERSION

    $ mysql --version
    mysql  Ver 14.14 Distrib 5.5.40, for debian-linux-gnu (x86_64) using readline 6.3
    $ gsutil version
    gsutil version: 4.6
    $ bq version
    This is BigQuery CLI 2.0.22

# REQUIRED FILES

    ~/.my.cnf
    ~/.bigqueryrc

# LICENSE

Copyright (C) Tatsuro Hisamori.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Tatsuro Hisamori <myfinder@cpan.org>
