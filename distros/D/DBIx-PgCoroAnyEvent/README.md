# DBD::Pg module for unblocking DBI connections in Coro + AnyEvent environment

# SYNOPSIS

```perl
  use DBI;
  $dbh = DBI->connect(
         "dbi:Pg:dbname=$dbname", $username, $auth, 
         { RootClass =>"DBIx::PgCoroAnyEvent",  %rest_attr}
  );
```
