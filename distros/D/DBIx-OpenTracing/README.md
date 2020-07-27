# COPYRYGHT NOTICE

'DBIx::OpenTracing' is Copyright (C) 2020, Perceptyx Inc, Szymon Nieznański

# DBIx::OpenTracing
Automatically create OpenTracing spans around DBI queries

## Usage

```perl

use DBI;
use DBIx::OpenTracing;

# use DBI as usual
my $dbh = DBI->connect(...);
$dbh->do(...);

DBIx::OpenTracing->disable();
$dbh->do($secret_query);
DBIx::OpenTracing->enable();

sub process_secrets {
    DBIx::OpenTracing->suspend();
    ...
}

```

## About

This module overrides L<DBI> methods to create spans around all queries.
It will also try to extract information like the query SQL and the number
of rows returned. L<OpenTracing::GlobalTracer> is used to accomplish this,
so make sure you set your tracer there.

# LICENSE INFORMATION
 
'DBIx::OpenTracing' is Copyright (C) 2020, Perceptyx Inc
 
This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.
 
This package is distributed in the hope that it will be useful, but it is
provided "as is" and without any express or implied warranties.
 
For details, see the full text of the license in the file LICENSE.
