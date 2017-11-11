package DBD::Cego;
use strict;

use DBI;

use vars qw($err $errstr $state $drh $VERSION @ISA);
$VERSION = '1.4.0';

use DynaLoader();
@ISA = ('DynaLoader');

__PACKAGE__->bootstrap($VERSION);

$err = 0;
$errstr = "";
$state = "";

$drh = undef;

sub driver {
    return $drh if $drh;
    my ($class, $attr) = @_;

    $class .= "::dr";

    $drh = DBI::_new_drh($class, {
        Name        => 'Cego',
        Version     => $VERSION,
        Err         => \$DBD::Cego::err,
        Errstr      => \$DBD::Cego::errstr,
        State       => \$DBD::Cego::state,
        Attribution => 'DBD::Cego',				  
    });

    return $drh;
}

package DBD::Cego::dr;

sub connect {
    my ($drh, $connection, $user, $auth, $attr) = @_;

    my $dbh = DBI::_new_dbh($drh, {
        Name => $connection,
        USER => $user,
        CURRENT_USER => $user,
        });

    my $tableset = $connection;

    if ($connection =~ /=/) {
      foreach my $attrib (split(/;/, $connection)) {
	my ($k, $v) = split(/=/, $attrib, 2);
	if ($k eq 'tableset')  {
	  $tableset = $v;
	}
	else  {	  
	  $dbh->STORE($k, $v);
	}
      }
    }
  
    DBD::Cego::db::_login($dbh, $tableset, $user, $auth)
        or return undef;

    return $dbh;
}

package DBD::Cego::db;

sub prepare {
    my ($dbh, $statement, @attribs) = @_;

    my $sth = DBI::_new_sth($dbh, {
        Statement => $statement,
    });

    DBD::Cego::st::_prepare($sth, $statement, @attribs)
        or return undef;

    return $sth;
}

1;
__END__

=head1 NAME

DBD::Cego - Perl database DBD interface for Cego

=head1 SYNOPSIS

  use DBI;
  my $dbh = DBI->connect("dbi:Cego:tableset=<name>;hostname=<server>;port=<portnumber>","<user>","<password>");

=head1 DESCRIPTION

Cego is a relational database system available as opensource.
For more information, please look at www.lemke-it.com

Before building and using the Cego DBD interface, you have to install
the required Cego C+ library  ( plus friends ).

Thanks to Matt Sergeant and his DBD implemenation for SQLite.
This code was used as a starting base and helped very much 
to implement this driver very quickly.

See the README in the installation package for more information.

=head1 API

This is the standard DBI API. Please see L<DBI> for more details about core features.


=head1 BUGS

There are no known bugs

=head1 AUTHOR

Bjoern Lemke, lemke@lemke-it.com

=head1 SEE ALSO

L<DBI>.

=cut
