package App::OverWatch::Config;
# ABSTRACT: Config object

use strict;
use warnings;
use utf8;

use Moo;
use namespace::clean;

has db_type   => ( is => 'ro' );
has dsn       => ( is => 'ro' );
has user      => ( is => 'ro' );
has password  => ( is => 'ro' );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::OverWatch::Config - Config object

=head1 VERSION

version 0.003

=head1 ATTRIBUTES

=head2 db_type

The type of backend database: mysql, postgres, sqlite

=head2 dsn

DSN used by DBI to connect to the database.

=head2 user

Database user (if required)

=head2 password

Database password (if required)

=head1 AUTHOR

Chris Hughes <chrisjh@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chris Hughes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
