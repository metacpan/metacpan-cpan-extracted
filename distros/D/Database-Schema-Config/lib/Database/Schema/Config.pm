package Database::Schema::Config;

use 5.008007;
use strict;
use warnings;
use Class::ParmList qw(parse_parms);
use Time::Timestamp;

our $VERSION = '.02';
use constant TABLE => 'config';

=head1 NAME

Database::Schema::Config - Perl extension for storing generic config strings with revision control in a table

=head1 SYNOPSIS

This is an interface module to our database. All SQL queries should be done at this level and only leave the actual config parsing to the upper level modules.

*Note: All references to timestamp or date/time are usually stored as Time::Timestamp objects, see Time::Timestamp for output options.

=head1 DESCRIPTION

An API for storing and manipulating configuration files RCS-style using a database backend. This allows the author to utilize any Config module they wish (config::General, Config::Simple, etc...).

=head1 SQL Table [mysql]

  -- 
  -- Table structure for table `config`
  -- 

  CREATE TABLE `config` (
    `rev` int(11) NOT NULL auto_increment,
    `xlock` tinyint(4) NOT NULL default '0',
    `dt` int(11) NOT NULL default '0',
    `user` varchar(32) NOT NULL default '',
    `config` text NOT NULL,
    `log` text,
    PRIMARY KEY  (`rev`)
  ) ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=2 ;

=head1 OBJECT METHODS

=head2 new()

Constructor

  my $cfg = Database::Schema::Config->new(
  	-dbh => $myDBI_handler,
  	-str => $configString,
  	-user => $user,
  	-table => 'myConfigTable',
  );

Returns:

  (undef,$obj) on success

=cut

sub new {
	my ($class,%parms) = @_;
	die('No DBH Defined!') if(!$parms{-dbh});
	$parms{-table} = TABLE() if(!$parms{-table});
	my $self = {};
	bless($self,$class);
	$self->init(%parms);
	return (undef,$self);
}

# INIT

sub init {
	my ($self,%parms) = @_;
	$self->table(	$parms{-table});
	$self->dbh(	$parms{-dbh});
	$self->string(	$parms{-string});
}

# METHODS

=head2 listConfigs()

Fetch a listing of all of the stored configs. The listing will contain the rev, timestamp, lock status, and user. If you want the  log and config, use getConfig().

Returns:

 (errstr,undef) something failed with the DB
 (undef,HASHREF) on success containing keys: "rev", "timestamp","lock", "user". Each of those point to ARRAYREFs.

So the revision of the first config in the list (which should be the oldest) is $hr->{'rev'}->[0]

=cut

sub listConfigs {
    	my $self = shift;
    	my $sql  = 'SELECT rev, dt AS timestamp, xlock, user FROM config ORDER BY rev ASC';
    	my $rv   = $self->dbh->selectall_arrayref($sql);

	return ("db failure ".$self->dbh->errstr(),undef) unless(ref($rv eq 'ARRAY') || ($#{$rv} > -1));

    	my $hv   = { 'rev' => [], 'timestamp' => [], 'lock' => [], 'user' => [] };
    	foreach my $row (@$rv) {
	    	push @{$hv->{'rev'}},       $row->[0];
	    	push @{$hv->{'timestamp'}}, Time::Timestamp->new(ts => $row->[1]);
	    	push @{$hv->{'lock'}},      $row->[2];
	   	push @{$hv->{'user'}},      $row->[3];
    	}
    	return (undef,$hv);
}

=head2 isConfigLocked()

Check to see if the latest config is currently locked. If it is, return information about the lock.

  $cfg->isConfigLocked();

Returns

  (errstr,undef) on failure
  (undef,HASHREF) locked. see keys for details.
  (undef,0) not locked

=cut

sub isConfigLocked {
    	my $self = shift;

   	my $sql = 'SELECT rev, user FROM config WHERE xlock = 1';
    	my $rv  = $self->dbh->selectall_arrayref($sql);

	return ('db failure: '.$self->dbh->errstr(),undef) unless($rv);
        return ('multiple locks on config detected.',undef) if(@$rv > 1);
    	return ('config is not locked',0) if(@$rv == 0);  # no locks
    	return (undef,{
		'rev'  => $rv->[0]->[0],
             	'user' => $rv->[0]->[1],
	});
}

=head2 lockConfig()

Lock the configuration so other people know we are editting it. A note will be appended to the "log" for the configuration.  The latest configuration will be "locked" unless "rev" is specified. This should be called from the getConfig() method, not directly.

Accepts:

  -rev => [int], defaults to 0
  -user => [string],

  $cfg->lockConfig(-rev => $rev, -user => $username);

Returns:

  (errstr,undef) on failure
  ('lock failed',0) if already locked
  (undef,$rev) on success

=cut

sub lockConfig {
    	my $self = shift;

    	my $parms = parse_parms({
		-parms => \@_,
		-required => [qw(-rev -user)],
		-legal => [qw(-lo)],
		-defaults => {
			-rev => 0,
		}
	});

    	return ("invalid parameters\n".Carp::longmess (Class::ParmList->error()),undef) unless(defined($parms));

	my ($r,$u,$lo) = $parms->get('-rev','-user','-lo');

	return ('invalid parameters (rev)',undef) unless($r >= 0);
	return ('invalid parameters (user)',undef) unless($u ne '');

	my $isLocked = $self->isConfigLocked();
	return ('lock failed: already Locked rev='.$isLocked->{rev}.' user='.$isLocked->{user},undef) unless(ref($isLocked) ne 'HASH');

   	my $sql = 'UPDATE config SET xlock = 1, user = '.$self->dbh->quote($u).' WHERE rev = '.$self->dbh->quote($r);
    	my $rv  = $self->dbh->do($sql);

	return ('db failure: '.$self->dbh->errstr(),undef) unless(defined($rv));

	my $err;
    	($err,$rv) = $self->appendLogToConfig(
		-rev => $r,
		-user => $u,
		-log => ['config locked'],
	);
	return ($err,$rv) unless($rv);
    	return (undef,$r);
}

=head2 unlockConfig()

Unlock the configuration. Both parameters are required. Should be called by the getConfig() method, not directly.

Accepts:

  -rev => [int], defaults to 0
  -user => [string],

  $cfg->unlockConfig(-rev => $rev, -user => $username);

Returns:

  (errstr,undef) on failure
  (undef,1) on success

=cut

sub unlockConfig {
    	my $self = shift;

    	my $parms = parse_parms({
		-parms => \@_,
		-required => [qw(-rev -user)],
		-defaults => {
			-rev => 0,
		}
	});

	return ("invalid parameters\n".Carp::longmess (Class::ParmList->error()),undef) unless(defined($parms));

	my ($r, $u) = $parms->get('-rev', '-user');
	$r = 0 if(!defined($r));

	return ('invalid parameters (rev)',undef) unless($r >= 0);
	return ('invalid parameters (rev)',undef) unless(defined($u) && $u ne '');
	my ($err,$rv) = $self->isConfigLocked();
	return ($err,$rv) unless($rv);

	($err,$rv) = $self->appendLogToConfig(
		-rev => $r,
		-user => $u,
		-log => ['config unlocked'],
	);
    	return ($err,$rv) unless($rv);

    	my $sql = 'UPDATE config SET xlock = 0 WHERE rev = '.$self->dbh->quote($r).' AND user = '.$self->dbh->quote($u);
    	$rv = $self->dbh->do($sql);
    	return ('db failure: '.$self->dbh->errstr(),undef) unless($rv);
    	return (undef,1);
}

=head2 appendLogToConfig()

Accepts:

  # required
  -user => undef,
  -rev => 0,
  -log => [],

  $cfg->appendLogToConfig(-rev => rev, -user => username, -log => ['myLogEntry']);

Add a log entry to the given config revision.

Returns

  (errstr,undef) on failure
  (undef,1) on success

=cut

sub appendLogToConfig {
	my $self = shift;

    	my $parms = parse_parms({
		-parms => \@_,
		-required => [ qw(-rev -user -log) ],
		-defaults => {
			-rev    => 0,
			-log    => []
		}
	});

	return ("invalid parameters\n".Carp::longmess (Class::ParmList->error()),undef) unless(defined($parms));

	my ($r, $u, $l) = $parms->get('-rev', '-user', '-log');

	return ('invalid parameters (rev)',undef) unless($r > 0);
	return ('invalid parameters (user)',undef) unless(defined($u) && $u ne '');
	return ('log empty',0) unless((ref($l) eq 'ARRAY') && ($#{$l} >= 0)); #empty?

	my $sql = 'SELECT `log` FROM `config` WHERE `rev` = '.$self->dbh->quote($r);
	my $rv = $self->dbh->selectall_arrayref($sql);

	return ('db failure: '.$self->dbh->errstr(),undef) unless(ref($rv) eq 'ARRAY');

	if ($#{$rv} == -1) {
	    	# the revision didnt exist. we dont throw an error tho.
	    	return ('revision doesnt exist',undef);
    	}

	$rv->[0]->[0] ||= '';

	my $l2  = join('', scalar(localtime())." $u\n", @$l, "\n", $rv->[0]->[0]);

	$sql = 'UPDATE config SET log = ? WHERE rev = ?';
	my $sth = $self->dbh->prepare($sql);
	$rv = $sth->execute($l2,$r);

	return ('db failure: '.$self->dbh->errstr(),undef) if(!$rv);
	return (undef,1);
}

=head2 getConfig()

Fetch the specified configuration from the database. If "rev" is not give, fetch the highest (latest) config from the database. If "lock" is "1", place an advisory lock on the configuration so that other people can't edit it without a warning.

  $cfg->getConfig(-rev => integer, -user => $username, -lock => [0|1]);

Accepts:

  # required
  -rev => [int], defaults to 0
  -user => [string],

  # legal
  -lock => [0|1], default is 0 # lock for editing?

Returns:

  (errstr,undef) on failure
  (undef,HASHREF) containing keys:

  	{
  		'config'    => ARRAYREF,
  		'log'       => ARRAYREF,
  		'timestamp' => integer,
  		'rev'       => integer,
  		'user'      => scalar string
  	}

=cut

sub getConfig {
    	my $self = shift;

    	my $parms = parse_parms({
		-parms => \@_,
		-required => [ qw(-rev -user) ],
		-legal => [qw(-rev -user -lock)],
		-defaults => {
			-rev    => 0,
			-user 	=> '',
			-lock   => 0,
		}
	});

	return ("invalid parameters\n".Carp::longmess (Class::ParmList->error()),undef) unless(defined($parms));

    	my ($r,$l,$u) = $parms->get('-rev','-lock','-user');

    	return ('invalid parameters (rev)',undef) unless($r >= 0);
    	return ('invalid parameters (lock)',undef) unless($l == 0 || $l == 1);
    	return ('invalid parameters (user)',undef) if(($l == 1) && ($u eq ''));

    	my $sql = 'SELECT rev,xlock,dt as Timestamp,user,config,log FROM `'.$self->table().'`';
    	$sql .= ' WHERE rev = '.$self->dbh->quote($r) if $r;
    	$sql .= ' WHERE rev = (select MAX(rev) FROM `'.$self->table().'`)' if ($r == 0);

	my ($err,$rv);
    	$rv = $self->dbh->selectall_arrayref($sql);

    	return ('db failure '.$self->dbh->errstr(),undef) unless(ref($rv) eq 'ARRAY');
	return ('db empty',undef) unless($rv->[0]);

    	if($l){
		my $rv2;
	    	($err,$rv2) = $self->lockConfig(-rev => $rv->[0]->[0], -user => $u);
	    	return ($err,$rv2) unless($rv2);
    	}
	
    	return (undef,{
		'rev'       	=> $rv->[0]->[0],
		'xlock'		=> $rv->[0]->[1],
		'timestamp' 	=> Time::Timestamp->new(ts => $rv->[0]->[2]),
		'user'      	=> $rv->[0]->[3],
		'config'    	=> [ split("\n", $rv->[0]->[4]) ],
	      	'log'       	=> [ split("\n", $rv->[0]->[5]) ],
	});
}

=head2 putConfig()

Insert a new configuration file into the database ("config" table). It's up to the calling application to "notice" the config rev was updated.

  $cfg->putConfig(
  	-config => ARRAYREF, # or ['string for array ref'] or [qw(my super cool string)]
  	-user => [string],
  	-log => ARRAYREF,
  	-autounlock => [0|1], # default is to unlock the config if isConfigLocked() == true
  	-init => [1|0], default is 0 # truncates the table and posts a blank config to rev 1. When you save, it becomes rev2
  );

Returns

  (errstr,undef) on failure
  (undef,1) on success

=cut

sub putConfig {
	my $self = shift;

	my $parms = parse_parms({
		-parms => \@_,
		-required => [qw(-config -user)],
		-legal => [qw(-config -user -autounlock -init)],
		-defaults => {
			-config => [],
			-log => [],
			-autounlock => 1,
			-init => 0,
		}
	});

	return ("invalid parameters\n".Carp::longmess (Class::ParmList->error()),undef) if (!defined($parms));

	my ($c,$u,$l,$au,$i) = $parms->get('-config','-user','-log','-autounlock','-init');

	return ('invalid parameters (config empty)',undef) unless(ref($c) eq 'ARRAY' && $#{$c} >= 0);
	return ('invalid parameters (user empty)',undef) if($u eq '');
	my ($err,$rv,$rev);
	if($i){
		$rv = $self->dbh->do('DELETE FROM `'.$self->table().'`');
		return ('db failure: '.$self->dbh->errstr(),undef) unless($rv);
		$rv = $self->dbh->do('TRUNCATE TABLE `'.$self->table().'`');
		return ('db failure: '.$self->dbh->errstr(),undef) unless($rv);
	}
	else {
		my $hr = $self->isConfigLocked();
		return ('no lock on previous config',undef) unless(ref($hr) eq 'HASH');
		return ('Someone else has already locked this config: user='.$hr->{user}.' rev='.$hr->{rev},undef) if($hr->{user} ne $u);
	}

	my $ts = Time::Timestamp->new(ts => time());
	my $sql = 'INSERT INTO `'.$self->table().'` (rev,dt,user,config) VALUES (?,?,?,?)';
	my $sth = $self->dbh->prepare($sql);
	$rv = $sth->execute($rev,$ts->epoch(),$u,@$c);

	return ('db failure: '.$self->dbh->errstr(),undef) unless($rv);

	$sql = 'SELECT rev FROM config WHERE user = ? AND dt = ?';
	$sth = $self->dbh->prepare($sql);
	$rv = $sth->execute($u,$ts->epoch());

	return ('db failure: '.$self->dbh->errstr(),undef) unless($rv);

	my @row = $sth->fetchrow_array();

	# append initial message
	my $rv2;
	($err,$rv2) = $self->appendLogToConfig(
		-rev 	=> $row[0],
		-user	=> $u,
		-log 	=> ['created'],
	);
	return ($err,$rv2) if(!$rv2);	

	($err,$rv) = $self->unlockConfig(-user => $u, -rev => ($row[0]-1)) unless(!$au || $i);
	return ($err,$rv) unless($rv);

	# append the users log message
	($err,$rv) = $self->appendLogToConfig(
		-rev	=> $row[0],
		-user	=> $u,
		-log	=> $l,
	);
	return ('db failure: '.$self->dbh->errstr(),undef) if(!defined($rv));
	return (undef,1);
}

=head2 resetLocks()

This function resets the xLock in the event that something screws up.

Accepts:

  -rev # optional, default is 'clear all locks'

Returns:

  (errstr,undef) on failure
  (undef,1) on success

=cut

sub resetLocks {
	my $self = shift;

	my $parms = parse_parms({
		-parms => \@_,
		-legal => [qw(-rev)],
	});

	return ("invalid parameters\n".Carp::longmess (Class::ParmList->error()),undef) if (!defined($parms));
	my ($rev) = $parms->get('-rev');

	my $sql = 'UPDATE `'.$self->table().'` SET xlock = 0';
	$sql .= ' WHERE rev = '.$self->dbh->quote($rev) if($rev);

	my $rv = $self->dbh->do($sql);
	return ('database failed: '.$self->dbh->errstr(),undef) unless($rv);
	return (undef,1);
}

# ACCESSORS / MODIFIERS

=head2 dbh()

Sets and returns the Database handle

=cut

sub dbh {
	my ($self,$v) = @_;
	$self->{_dbh} = $v if(defined($v));
	return $self->{_dbh};
}

=head2 table()

Sets and returns the base config table

=cut

sub table {
	my ($self,$v) = @_;
	$self->{_table} = $v if(defined($v));
	return $self->{_table};
}

=head2 string()

Sets and returns the config string

=cut

sub string {
	my ($self,$v) = @_;
	$self->{_string} = $v if(defined($v));
	return $self->{_string};
}

1;
__END__

=head1 SEE ALSO

Time::Timestamp

sourceforge://netpass

=head1 AUTHOR'S

Original Author - Jeff Murphy - E<lt>jcmurphy@buffalo.eduE<gt>

Stolen By - Wes Young - E<lt>saxguard9-cpan@yahoo.comE<gt>

=head1 LICENSE

   (c) 2006 University at Buffalo.
   Available under the "Artistic License"
   http://www.gnu.org/licenses/license-list.html#ArtisticLicense

=cut

# Jeff, you're still a wanker..... ;-)
