package DBIx::Class::Helper::ResultSet::Explain;
$DBIx::Class::Helper::ResultSet::Explain::VERSION = '2.036000';
# ABSTRACT: Get query plan for a ResultSet

use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

use DBIx::Introspector;

sub _introspector {
   my $d = DBIx::Introspector->new(drivers => '2013-12.01');

   $d->decorate_driver_connected(MSSQL => splain => 'GETUTCDATE()');
   $d->decorate_driver_connected(
      SQLite => splain => sub {
         sub {
            my ($dbh, $query) = @_;
            my ($sql, @bind)  = @{$$query};

            $sql =~ s/\s*\((.*)\)\s*/$1/;

            shift->selectall_arrayref("EXPLAIN $sql", undef, @bind)
         },
      },
   );
   $d->decorate_driver_connected(
      Pg => splain => sub {
         sub {
            my ($dbh, $query) = @_;
            my ($sql, @bind)  = @{$$query};
            shift->selectall_arrayref("EXPLAIN ANALYZE $sql", undef, @bind)
         },
      },
   );

   $d->decorate_driver_connected(
      mysql => splain => sub {
         sub {
            my ($dbh, $query) = @_;
            my ($sql, @bind)  = @{$$query};
            shift->selectall_arrayref("EXPLAIN EXTENDED $sql", undef, @bind)
         },
      },
   );

   return $d;
}

use namespace::clean;

my $i;

sub explain {
   $i ||= _introspector();

   my $self = shift;

   my $storage = $self->result_source->storage;
   $storage->ensure_connected;
   my $dbh = $storage->dbh;

   $i->get($dbh, undef, 'splain')->($dbh, $self->as_query)
}

1;

__END__

=pod

=head1 NAME

DBIx::Class::Helper::ResultSet::Explain - Get query plan for a ResultSet

=head1 SYNOPSIS

This module mostly makes sense to be used without setting as a component:

 use Devel::Dwarn;
 Dwarn DBIx::Class::ResultSet::Explain::explain($rs)

But as usual, if you prefer to use it as a component here's how:

 package MyApp::Schema::ResultSet::Foo;

 __PACKAGE__->load_components(qw{Helper::ResultSet::Explain});

 ...

 1;

And then in a script or something:

 use Devel::Dwarn;
 Dwarn $rs->explain;

=head1 DESCRIPTION

This is just a handy little tool that gives you the query plan for a given
ResultSet.  The output is in no way normalized, so just treat it as a debug tool
or something.  The only supported DB's are those listed below.  Have fun!

See L<DBIx::Class::Helper::ResultSet/NOTE> for a nice way to apply it
to your entire schema.

=head1 EXAMPLE OUTPUT FROM SUPPORTED DB's

=head2 SQlite

 [
   [
     0,
     "Init",
     0,
     10,
     0,
     "",
     "00",
     undef,
   ],
   [
     1,
     "OpenRead",
     0,
     3,
     0,
     4,
     "00",
     undef,
   ],
   [
     2,
     "Rewind",
     0,
     9,
     0,
     "",
     "00",
     undef,
   ],
   [
     3,
     "Rowid",
     0,
     1,
     0,
     "",
     "00",
     undef,
   ],
   [
     4,
     "Column",
     0,
     1,
     2,
     "",
     "00",
     undef,
   ],
   [
     5,
     "Column",
     0,
     2,
     3,
     "",
     "00",
     undef,
   ],
   [
     6,
     "Column",
     0,
     3,
     4,
     "",
     "00",
     undef,
   ],
   [
     7,
     "ResultRow",
     1,
     4,
     0,
     "",
     "00",
     undef,
   ],
   [
     8,
     "Next",
     0,
     3,
     0,
     "",
     "01",
     undef,
   ],
   [
     9,
     "Halt",
     0,
     0,
     0,
     "",
     "00",
     undef,
   ],
   [
     10,
     "Transaction",
     0,
     0,
     17,
     0,
     "01",
     undef,
   ],
   [
     11,
     "Goto",
     0,
     1,
     0,
     "",
     "00",
     undef,
   ],
 ]

=head2 Pg

 [
   [
     "Seq Scan on \"Gnarly\" me  (cost=0.00..16.20 rows=620 width=100) (actual time=0.002..0.002 rows=0 loops=1)",
   ],
   [
     "Planning time: 0.182 ms",
   ],
   [
     "Execution time: 0.037 ms",
   ],
 ]

=head2 mysql

 [
   [
     1,
     "SIMPLE",
     "me",
     "ALL",
     undef,
     undef,
     undef,
     undef,
     1,
     100,
     "",
   ],
 ]

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
