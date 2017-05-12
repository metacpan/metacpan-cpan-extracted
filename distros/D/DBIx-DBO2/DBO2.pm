package DBIx::DBO2;

require 5.005;
use strict;

use vars qw( $VERSION );
$VERSION = 0.008;

########################################################################

use DBIx::SQLEngine;

use DBIx::DBO2::RecordSet;
use DBIx::DBO2::Record;

use DBIx::DBO2::Schema;

use DBIx::DBO2::Fields;

########################################################################

1;

__END__

########################################################################

=head1 NAME

DBIx::DBO2 - Objects mapping to SQL relational structures

=head1 SYNOPSIS

  package MyRecord;
  use DBIx::DBO2::Record '-isasubclass';
  
  my $sql_engine = DBIx::SQLEngine->new( $dsn, $user, $pass );
  MyRecord->table( $sql_engine->table('myrecords') );
  
  package main;
  my $results = MyRecord->fetch_all;
  foreach my $record ( $results->records ) {
    if ( $record->{age} > 20 ) {
      $record->{status} = 'adult';
      $record->save_row;
    }
  }

=head1 DESCRIPTION

DBIx::DBO2 is an object-relational mapping framework that facilitates the development of Perl classes whose objects are stored in a SQL database table.

The following classes are included:

  Schema
  Record	RecordSet
  Fields

Each Schema object represents a collection of Record classes. 

Each Record object represents a single row in a SQL table.

The Fields class generates accessor methods for Record classes.

The RecordSet class provides methods on blessed arrays of Records.



=head1 SEE ALSO

See L<DBIx::DBO2::Record>, L<DBIx::DBO2::Fields>, L<DBIx::DBO2::Table>, and L<DBIx::DBO2::TableSet> for key interfaces.

See L<DBIx::DBO2::ReadMe> for distribution and license information.



=head1 CREDITS AND COPYRIGHT

=head2 Author

Developed by Matthew Simon Cavalletto at Evolution Softworks.

You may contact the author directly at C<evo@cpan.org> or
C<simonm@cavalletto.org>. More free Perl software is available at
C<www.evoscript.org>.

=head2 Contributors 

Many thanks to the kind people who have contributed code and other feedback:

  Eric Schneider, Evolution Online Systems
  E. J. Evans, Evolution Online Systems
  Matthew Sheahan, Evolution Online Systems
  Eduardo Iturrate, Evolution Online Systems

=head2 Copyright

Copyright 2002, 2003, 2004 Matthew Cavalletto. 

Portions copyright 1997, 1998, 1999, 2000, 2001 Evolution Online Systems, Inc.

=head2 License

You may use, modify, and distribute this software under the same terms as Perl.

=cut
