AnyEvent::PgRecvlogical
=======================

[![Build Status](https://travis-ci.org/mydimension/AnyEvent-PgRecvlogical.svg?branch=master)](https://travis-ci.org/mydimension/AnyEvent-PgRecvlogical)
[![Coverage Status](https://coveralls.io/repos/github/mydimension/AnyEvent-PgRecvlogical/badge.svg?branch=master)](https://coveralls.io/github/mydimension/AnyEvent-PgRecvlogical?branch=master)
[![CPAN version](https://badge.fury.io/pl/AnyEvent-PgRecvlogical.svg)](https://badge.fury.io/pl/AnyEvent-PgRecvlogical)

`AnyEvent::PgRecvlogical` provides perl bindings of similar functionality to that of
[`pg_recvlogical`](https://www.postgresql.org/docs/current/static/app-pgrecvlogical.html).
The reasoning being that `pg_recvlogical` does afford the consuming process the opportunity to emit feedback to
PostgreSQL. This results is potentially being sent more data than you can handle in a timely fashion.

Copyright
=========

Copyright (c) 2107-2018 William Cox

License
=======

This library is free software and may be distributed under [the same terms as perl itself](http://dev.perl.org/licenses/).
