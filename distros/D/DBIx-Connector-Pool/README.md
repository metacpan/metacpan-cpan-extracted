# NAME

DBIx::Connector::Pool - A pool of DBIx::Connector or its subclasses for asynchronous environment

# SYNOPSIS

    use Coro;
    use AnyEvent;
    use Coro::AnyEvent;
    use DBIx::Connector::Pool;
    
    my $pool = DBIx::Connector::Pool->new(
      initial    => 1,
      keep_alive => 1,
      max_size   => 5,
      tid_func   => sub {"$Coro::current" =~ /(0x[0-9a-f]+)/i; hex $1},
      wait_func => sub        {Coro::AnyEvent::sleep 0.05},
      attrs     => {RootClass => 'DBIx::PgCoroAnyEvent'}
    );
    
    async {
      my $connector = $pool->get_connector;
      $connector->run(
        sub {
          my $sth = $_->prepare(q{select isbn, title, rating from books});
          $sth->execute;
          my ($isbn, $title, $rating) = $sth->fetchrow_array;
          # ... 
        }
      );
    };

# Description

[DBI](https://metacpan.org/pod/DBI) is great and [DBIx::Connector](https://metacpan.org/pod/DBIx::Connector) is a nice interface with good features 
to it. But when it comes to work in some asynchronous environment like
[AnyEvent](https://metacpan.org/pod/AnyEvent) you have to use something another with callbacks if you don't want
to block your event loop completely waiting for data from DB. This module 
(together with [DBIx::PgCoroAnyEvent](https://metacpan.org/pod/DBIx::PgCoroAnyEvent) for PostgreSQL or some another alike) 
was developed to overcome this inconvenience. You can write your "normal" DBI
code without blocking your event loop. 

This module requires some threading model and I know about only one really 
working [Coro](https://metacpan.org/pod/Coro). 

# Methods

- **new**

        my $pool = DBIx::Connector::Pool->new(
          initial    => 1,
          keep_alive => 1,
          max_size   => 5,
          tid_func   => sub {"$Coro::current" =~ /(0x[0-9a-f]+)/i; hex $1},
          wait_func => sub        {Coro::AnyEvent::sleep 0.05},
          attrs     => {RootClass => 'DBIx::PgCoroAnyEvent'}
        );

    Creates new pool. Possible parameters:

    - **initial**

        Initial number of connected connectors. This means also minimum of of
        connected connectors. It throws error if this minimum can not be met.

    - **keep\_alive**

        How long connector can live after it becomes unused. Initial connectors will
        live forever. `-1` means no limit. `0` means collect it immediate. Positive 
        number means seconds.

    - **max\_size**

        Maximum pool capacity. `-1` means unlimited.

    - **user**
    - **password**
    - **dsn**
    - **attrs**

        Data for `DBIx::Connector->new` function. This is the same as for 
        `DBI->connect`. Usually you want to add some unblocking DBI subclass
        as `RootClass` attribute. Like `RootClass => 'DBIx::PgCoroAnyEvent'`
        for PostgreSQL.  

    - **tid\_func**

        Thread identification function. Must return number. Good choice for [Coro](https://metacpan.org/pod/Coro) is

            sub {"$Coro::current" =~ /(0x[0-9a-f]+)/i; hex $1}

    - **wait\_func**

        This function put **get\_connector** into sleep to wait for a free connector 
        in pool.

    - **connector\_base**

        In case you use some subclass of [DBIx::Connector](https://metacpan.org/pod/DBIx::Connector) you have to point it out.

- **get\_connector**

    Returns available connector. Returned object is a subclass of 
    [DBIx::Connector](https://metacpan.org/pod/DBIx::Connector) or subclass of **connector\_base**. 

    The same thread will get the same already used connector until it's free. 
    Function always wait for an available connector, it can't return undef. 

    When new connection can not be established an error is thrown 
    or if **max\_size** is greater than **intial** or equal to `-1` then
    **max\_size** will be automatically lowered to actually possible size.

- **collect\_unused**

    Method marks unused and disconnects timed out connectors. It keeps minimum 
    **initial** number of connectors connected. Intended to be used from timers 
    events. 

- **connected\_size**

    Returns number of currently connected connectors.

- **$DBIx::Connector::Pool::Item::not\_in\_use\_event**

    This package variable is a subroutine referenc which is called when connectors
    object is not in use anymore. You can use it together with **wait\_func** to 
    wake up a waiting for a free connector **get\_connector**.

# SEE ALSO

- [DBIx::Connector](https://metacpan.org/pod/DBIx::Connector)
- [DBI](https://metacpan.org/pod/DBI)
- [DBIx::PgCoroAnyEvent](https://metacpan.org/pod/DBIx::PgCoroAnyEvent)
- [DBD::Pg](https://metacpan.org/pod/DBD::Pg)
- [Coro](https://metacpan.org/pod/Coro)
- [AnyEvent](https://metacpan.org/pod/AnyEvent)

# BUGS

Currently this module tested only for PostgreSQL + Coro + AnyEvent.

# AUTHOR

This module was written and is maintained by Anton Petrusevich.

# Copyright and License

Copyright (c) 2016 Anton Petrusevich. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
