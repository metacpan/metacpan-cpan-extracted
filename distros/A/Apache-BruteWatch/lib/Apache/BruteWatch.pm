# $Header: /cvsroot/Apache-BruteWatch/lib/Apache/BruteWatch.pm,v 1.13 2003/08/11 14:22:28 rbowen Exp $
package Apache::BruteWatch;
use strict;
use vars qw($VERSION);
use Apache::Constants qw( :common );
use DBI;
use Mail::Sendmail qw();

$VERSION = qw($Revision: 1.13 $) [1];

=head1 NAME

Apache::BruteWatch - Watch the Apache logs and notify of bruteforce password attacks

=head1 VERSION

 $Revision: 1.13 $

=head1 SYNOPSIS

Place the following in your C<httpd.conf>

    PerlLogHandler Apache::BruteWatch

    PerlSetVar BruteDatabase     DBI:mysql:brutelog
    PerlSetVar BruteDataUser     username
    PerlSetVar BruteDataPassword password

    PerlSetVar BruteMaxTries     10
    PerlSetVar BruteMaxTime      30
    PerlSetVar BruteNotify       rbowen@example.com
    PerlSetVar BruteForgive      300

=head1 DESCRIPTION

C<mod_perl> log handler for warning you when someone is attempting a
brute-force password attack on your web site.

=head1 Variables

The following variables can be set in your Apache configuration file:

=head2 BruteDatabase

The DBI database name, such as C<DBI:mysql:brutelog>

=head2 BruteDataUser

The database username

=head2 BruteDataPassword

The database password

=head2 BruteMaxTries and BruteMaxTime

Allow this many failed attempts in this much time. After that,
notification will be sent. Time is in seconds.

=head2 BruteNotify

Email address to which notifications will be sent

=head2 BruteForgive

Failed login attempts will be cleaned up after they are this old. Units
are seconds.

=cut

sub handler {
    my $r = shift;

    # We only care about unauthorized
    return OK unless $r->status == 401;

    my $user  = $r->dir_config('BruteDataUser');
    my $pass  = $r->dir_config('BruteDataPassword');
    my $dbase = $r->dir_config('BruteDatabase');

    my $dbh =
      DBI->connect( $dbase, $user, $pass,
        { RaiseError => 1, AutoCommit => 1, PrintError => 1 } )
      or die $DBI::errstr;

    my $time     = time;
    my $username = $r->user;
    my $sth      = $dbh->prepare(
        "INSERT into bruteattempt (ts ,
        username) values (?,?)"
    );
    $sth->execute( $time, $username );
    $sth->finish;

    my $count = attacks( $r, $username, $time, $dbh );

    my $maxtries = $r->dir_config('BruteMaxTries');
    if ( $count > $maxtries ) {
        warn(
"Apache::BruteWatch : It appears that $username is under attack. Notification sent."
        );
        notify( $r, $username, $dbh );
    }

    return OK;
}

sub attacks {
    my ( $r, $username, $time, $dbh ) = @_;
    my $count;

    my $old = $r->dir_config('BruteMaxTime');
    my $sth = $dbh->prepare(
        "select count(ID) from bruteattempt where
                username = ? and ts > $time - $old"
    );
    $sth->execute($username);
    $sth->bind_columns( \$count );
    $sth->fetch;
    $sth->finish;

    my $forgive = $r->dir_config('BruteForgive');
    $sth = $dbh->prepare(
        "delete from bruteattempt where 
                          ts > $time - $forgive"
    );
    $sth->execute;
    $sth->finish;

    return $count;
}

sub notify {
    my ( $r, $username, $dbh ) = @_;
    my $count;

    warn "Attempting to notify";

    # Have they already been notified?
    my $sth = $dbh->prepare(
        "select count(ID) from brutenotified
        where username = ?"
    );
    $sth->execute($username);
    $sth->bind_columns( \$count );
    $sth->fetch;
    $sth->finish;

    return if $count;

    my $notify = $r->dir_config('BruteNotify');

    my $message = qq~
    Apache::BruteWatch

    It appears that the username $username is under a brute-force
    password attack.
    ~;

    my %mail = (
        To      => $notify,
        From    => $notify,
        Subject => "User $username under attack",
        Message => $message,
    );
    Mail::Sendmail::sendmail(%mail);

    $sth = $dbh->prepare(
        "insert into brutenotified
        (username, ts )
        values
        (?,?) "
    );
    $sth->execute( $username, time );
    $sth->finish;

    return;
}

=head1 Database

The following is a mysql database table create statement. You'll need to
make the appropriate change to run this on some other database.

  CREATE TABLE bruteattempt (
  ID int(11) NOT NULL auto_increment,
  ts int(11) default NULL,
  username varchar(255) default NULL,
  PRIMARY KEY  (ID)
 ) TYPE=MyISAM;

 CREATE TABLE brutenotified (
  ID int(11) NOT NULL auto_increment,
  username varchar(255) default NULL,
  ts int(11) default NULL,
  PRIMARY KEY  (ID)
 ) TYPE=MyISAM;

=head1 AUTHOR

	Rich Bowen
	rbowen@rcbowen.com
	http://www.cre8tivegroup.com
 
=head1 DATE

	$Date: 2003/08/11 14:22:28 $

=cut

1;

