
=head1 NAME

DBIx::ShowCaller - adds a Perl caller info to the SQL command

=cut

use DBI;

package DBIx::ShowCaller;
use vars qw! @ISA $AUTOLOAD $VERSION !;
@ISA = qw! DBI !;

$VERSION = '0.80';

sub connect {
	my $class = shift;
	my ($dsn, $user, $password, $attrib) = @_;
	$attrib->{'RootClass'} = 'DBIx::ShowCaller';
	$class->SUPER::connect($dsn, $user, $password, $attrib);
	}
DBI::init_rootclass('DBIx::ShowCaller');

package DBIx::ShowCaller::db;
use vars qw! @ISA $AUTOLOAD !;
@ISA = qw! DBI::db !;

sub prepare {
	my ($self, $stmt) = ( shift, shift );

	my $comment = '/* no stack info found */ ';
	for (my $i = 0; ; $i++) {
		my ($package, $filename, $line) = caller $i;
		last unless defined $package;

		next if $package =~ /^(DB(Ix?\b|D::))/;
		$filename =~ s!\*/!*_/!g;
		$comment = "/* $filename at line $line */ ";
		last;
		}

	$self->SUPER::prepare($comment . $stmt, @_);
	}

package DBIx::ShowCaller::st;
use strict;
use vars qw! @ISA $AUTOLOAD !;
@ISA = qw! DBI::st !;

1;

=head1 SYNOPSIS

	use DBIx::ShowCaller;
	my $dbh = DBIx::ShowCaller->connect('dbi:Oracle:prod',
		'test', 'test', { 'RaiseError' => 1 });
	
	# and follow as with normal DBI
	$dbh->do('insert into jezek values (?)', {}, 45);
	# will call (and log in V$SQL)
		/* script.pl at line 7 */
		insert into jezek values (:p1)

=head1 DESCRIPTION

This module can be used instead of the DBI module. For each SQL command
that is prepared (both using $dbh->prepare and via do, selectall_* and
the like) it prepends a /* */ style comment containing information about
file and line that called that prepare/selectall_*/other method. Thus
it makes it easier to see where a particular SQL command came from.

Only database servers that log the whole SQL command (like Oracle or
MySQL) can make reasonable use of this. Also, if you call the same SQL
from different places of your code, the comment will be different and
the SQL server won't be able to reuse parsed info. Consider the speed
tradeoff here.

=head1 VERSION

0.80

=head1 AUTHOR

(c) 2000 Jan Pazdziora, adelton@fi.muni.cz,
http://www.fi.muni.cz/~adelton/
at Faculty of Informatics, Masaryk University in Brno, Czech Republic

All rights reserved. This package is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

DBI(1)

=cut

