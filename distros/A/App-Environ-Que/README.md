# App-Environ-Que

Perl library to enqueue tasks in [Ruby Que queuing library for
PostgreSQL](https://github.com/chanks/que).

This library is based on App::Environ.

Main deal of this library: enqueue tasks in perl code and process them in
go code with [que-go](https://github.com/bgentry/que-go).
