# $Id: Transaction.pm,v 1.3 2005/12/02 10:43:09 dk Exp $

package DBIx::Roles::Transaction;

# Allows nested begin_work/rollback/commit calls

use strict;
use vars qw(%defaults $VERSION);

$VERSION = '1.00';

sub initialize 
{  
	return {
		counter => 0,
		ok      => 1,
	};
}

sub begin_work
{
	my ( $self, $storage) = @_;
	return ( $storage->{counter}++) ? 1 : $self-> super;
}

sub rollback
{
	my ( $self, $storage) = @_;
	
	$storage->{counter}--;

	if ( $storage->{counter} > 0) {
		my $ok = $storage->{ok};
		$storage->{ok} = 0;
		return $ok;
	} else {
		$storage->{ok} = 1;
		return $self-> super;
	}
}

sub commit
{
	my ( $self, $storage) = @_;

	$storage->{counter}--;

	if ( $storage->{counter} > 0) {
		return $storage->{ok};
	} elsif ( $storage-> {ok}) {
		return $self-> super;
	} else {
		$storage->{ok} = 1;
		return $self-> rollback;
	}
}

1;

__DATA__

=pod

=head1 NAME

DBIx::Roles::Transaction - allow nested transactions.

=head1 DESCRIPTION

Wraps C<begin_work>, C<rollback>, and C<commit> calls so that these can be
called inside transactions. If an inner transaction calls C<rollback>, all
outer transactions fail. The original idea appeared in L<DBIx::Transactions> by
Tyler MacDonald.

=head1 SYNOPSIS

     use DBIx::Roles qw(Transaction);

     my $dbh = DBI-> connect(
           "dbi:Pg:dbname=template1",
	   "postgres",
	   "password",
     );
     sub do_something {
         my($dbh, $num) = @_;
         $dbh->begin_work;
         if($dbh->do("DO SOMETHING IN SQL WHERE num = $num")) {
            $dbh->commit;
         } else {
            $dbh->rollback;
         }
      }
      
      $dbh->begin_work;
      for my $i (1 .. 10) {
         do_something($dbh, $i);
      }
      
      if( $dbh->commit) {
         print "Every nested transaction worked and the database has been saved.\n";
      } else {
         print "A nested transaction rolled back, so nothing happened.\n";
      }

=head1 NOTES

The role is useful, if you planning a library where methods are required to be
transactions, but also might be called from within a transaction. For example,
a method changing user password can be implemented as a transaction, but also
can be called from the method that adds user data, which is in turn can be a
transaction too.

The role has nothing to do with the real nested transactions, that might be
implemented by a particular database engine, such as for example savepoints in 
PosgtreSQL.

=head1 SEE ALSO

L<DBI>, L<DBIx::Roles>, L<DBIx::Transaction>.

=head1 COPYRIGHT

Copyright (c) 2005 catpipe Systems ApS. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dmitry Karasik <dk@catpipe.net>

=cut
