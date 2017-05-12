package Database::Schema::Verification;

use 5.008007;
use strict;
use warnings;
use MIME::Lite;
use Class::ParmList qw(parse_parms);
use Time::Timestamp;

our $VERSION = '1.02';
use constant TABLE => 'verification';
use constant HARD_RETURN_LIMIT => 500; # hard coded hashref return limit, can be overridden locally

=head1 NAME

Database::Schema::Verification - Perl extension for storing and verifing various levels of information

=head1 SYNOPSIS

  use Database::Schema::Verification;

  my $v = Database::Schema::Verification->new(
  	-dbh => $dbh,
  	-type => 'my_type',
  	-type_id => 22,
  	-msg => $txtVerificationEmailMsg,
  );

  my $rv = $v->check();
  my $rv = $v->insert();
  my $rv = $v->isVerified();
  my $rv = $v->load();
  my $rv = $v->requestVerification();
  my $rv = $v->verifiy(-action => 1);
  my $rv = $v->remove();

  # returns array of Database::Schema::Verification objects
  # each of a hardcoded return limit of 500, wich can be overwritten
  my @ary = $v->returnUnprocessed();
  my @ary = $v->returnUnverified(); 
  

=head1 DESCRIPTION

The Verification module provides an easy storage interface for keeping track of what data has been verified, what has been surpressed and what needs verification. At it's core it provides a relation between it's master key (vid) and a combination of the type of data you are working with (usually associates with a table within your database) and it's master key. This module also provides you with a simple email tool that provides notification of an event requiring verification.

Accompanied within this is a 'contrib' directory. In there you'll find a CGI script. The purpose of this script is to allow authors the ability to place embedded links within the email notifications. These links can provide a set of parameters that will trigger any of the verification functions. This allows users to click the links in the email and verify or surpess data as it becomes avalible.

The basic concept is to allow authors to insert this where ever they need to. This can be it's own verification database where:

  type => 'databaseName.table',
  type_id => $databaseName.table.keyId

This would allow you to maintain one verification database for multiple databases or applications

OR it can be a simple table embeded into your program database

  type => 'table',
  type_id => $table.keyId

This allows you to scale it as you need it and apply verification to any level of data you are working with.

**Note: All string returns are in the format:

 return ('reason we bombed out...',[undef,0]);

This allows you to extract why the function failed with a:

 my ($str,$rv) = function->check(...);
 if(!defined($rv)){
 	die($str);
 }

=head1 OBJECT METHODS

=head2 new()

Default constructor

  my $v = Database::Schema::Verification->new(
	# required
  	-dbh => $dbh,
  	-type => 'my_type',
  	-type_id => 22,
  	-msg => $txtVerificationEmailMsg,

	# optional
	-vid		=> $vid,
	-dt_added	=> $dt_added, [see Time::Timestamp]
	-dt_updated	=> $dt_updated, [see Time::Timestamp]
	-verified	=> $verified, # see verified() for inputs
	-verified_by	=> $verified_by,
	-verified_by_ip	=> $verified_by_ip, [see Net::IP]
	-table		=> $table # default is 'verification'
  );

=over 4

=item dbh [DBI handle]

A DBI handle

=item vid [int]

This pre-specifies the verification id

=item type [string]

This is the type of data we are verifiying (usually use the database table we are targeting)

=item type_id [int]

The key id field for the table data we are verifing

=item msg [string]

Text to be included in the verification message

=item dt_added [int|string] (stored as Time::Timestamp obj)

Optional: Initial timestamp, automagically inserted if left blank

=item dt_updated [int|string] (stored as Time::Timestamp obj)

Optional: Last updated timestamp, automagically handled if left blank

=item verified [int]

Optional: Allows you to auto set the verification status (see verify() for list of inputs

=item verified_by [string]

Optional: Allows specification of the verifing source (who done did it)

=item verified_by_ip [string|int] (stores as Net::IP object)

Optional: Allows specification of the source ip who verified the data (who's box done did it)

=item table [string]

Option: Overrides the default base table definition # default is 'verification'

=back

=cut
sub new {
	my ($class,%parms) = @_;
	my $self = {};
	bless($self,$class);
	$self->init(%parms);
	return $self;
}

# INIT

sub init {
	my ($self,%parms) = @_;
	$parms{-table} = TABLE() if(!$parms{-table});
	$parms{-ignoreTypeCase} = 1 if(!$parms{-ignoreTypeCase});

	die 'We need a dbh!!' if(!$parms{-dbh});
	$self->dbh(		$parms{-dbh});
	$self->table(		$parms{-table});
	$self->vid(		$parms{-vid});
	$self->type_id(		$parms{-type_id});
	$self->type(		$parms{-type});
	$self->dt_added(	$parms{-dt_added});
	$self->dt_updated(	$parms{-dt_updated});
	$self->verified(	$parms{-verified});
	$self->verified_by(	$parms{-verified_by});
	$self->verified_by_ip(	$parms{-verified_by_ip});
	$self->msg(		$parms{-msg});
}

# METHODS

=head2 check()

This function checks to see if your key or key pair (type && type_id) already exist in the database. By default $v->vid(), $v->type() and $v->type_id() are taken in the function but can be overwritten with parms.

  $v->check(
  	# optional override of object properties
  	-type => $type,
  	-type_id => $type_id,
  	-vid => $vid,
  );

Returns:

  Errstr on failure
  1 on KeyExsits
  0 on keyNotExists

=cut

sub check {
	my $self = shift;

	my $parms = parse_parms({
		-parms => \@_,
		-required => [],
		-legal => [ qw(-type -type_id -vid) ],
		-defaults => {
			-type => $self->type(),
			-type_id => $self->type_id(),
			-vid => $self->vid(),
		}
	});

	return ("invalid parameters\n".Carp::longmess (Class::ParmList->error()),undef) unless(defined($parms));
	my ($type,$type_id,$vid) = $parms->get('-type','-type_id','-vid');
	return ("invalid params: [type,type_id|vid] required! \n",undef) unless(($type && $type_id) || $vid);

	my ($sql,@x);
	if($vid){
		$sql = 'SELECT id FROM `'.$self->table().'` WHERE `id` = ?';
		$x[0] = $vid;
	}
	else {
		$sql = 'SELECT id FROM `'.$self->table().'` WHERE `type_id` = ? and `type` = ?';
		@x = ($type_id,$type);
	}

	my $sth = $self->dbh->prepare($sql);
	my $rv = $sth->execute(@x);
	if($rv) {
		my @row = $sth->fetchrow_array();
		return (undef,1) if($row[0]);
		return 0;
	}
	return ('database failed: '.$self->dbh->errstr(),undef);
}

=head2 insert()

This function loads a verification object into the database (pre-checks the type && type_id first). By default $v->vid(),$v->type() and $v->type_id() are checked. These can be overwritten with params.

  $v->insert(
  	# optional override of object properties
  	-type => $type,
  	-type_id => $type_id,
  	-fork => 1,	# forks back a loaded object on insert completion

  	# vid can be set manually, but it's usually auto-incremented by the database
	# all other properties should be set by the new() or their accessors before this is called
  );

Returns:

 0 on KeyExists
 $objectRef [-forkOnExists]
 Errstr on failure
 ($vid,1) on success
 ($objectRef,1) on success [with fork parm]

=cut

sub insert {
	my $self = shift;

	my $parms = parse_parms({
		-parms => \@_,
		-required => [qw(-type -type_id)],
		-legal => [qw(-type -type_id -vid -fork -forkOnExist -msg )],
		-defaults => {
			-type => $self->type(),
			-type_id => $self->type_id(),
			-vid => $self->vid(),
			-msg => $self->msg(),
		}
	});
	return ("invalid parameters\n".Carp::longmess (Class::ParmList->error()),undef) unless(defined($parms));
	my ($vid,$type,$type_id,$fork,$forkOnExist,$msg) = $parms->get('-vid','-type','-type_id','-fork','-forkOnExist','-msg');

	$self->dt_added(time()) unless($self->dt_added());
	$self->dt_updated(time());

	if($self->check(-type => $type, -type_id => $type_id, -vid => $vid) == 1){
		return ('check: keys already exist',0) unless($forkOnExist);
		return (undef,$self->load(-vid => $vid, -type => $type, -type_id => $type_id, -fork => 1));
	}

	my $sql = 'INSERT INTO `'.$self->table().'` (`id`,`type_id`,`type`,`dt_added`,`dt_updated`,`msg`) VALUES (?,?,?,?,?,?)';
	my $sth = $self->dbh->prepare($sql);
	my $rv = $sth->execute($vid,$type_id,$type,$self->dt_added->epoch(),$self->dt_updated->epoch(),$msg);
	return ('insert failed: '.$self->dbh->errstr(),undef) unless($rv);

	return ($self->returnVid(),1) unless($fork);
	return (undef,$self->load(-type=> $type, -type_id => $type_id, -fork => 1));
}

=head2 requestVerification()

Function takes in MIME::Lite parms and submits a notification for review. It can become particularly useful when coupled with a cgi script (see contrib directory). Embedding links into these messages allows you to verify or suppress verification by clicking a link in the email.

  my $msg = 'Please Verify Me!!!!';
  $v->requestVerification(
  	-to => 'myself@you.com',
  	-from => 'root@localhost',
  	-msg => $msg,
  	-subject => 'Verification required!!',

  	# optional
  	-update => 1, # default
  );

Returns:

  Errstr on failure
  1 on success

=over 4

=item update

By default, a call to requestVerification() will update our 'verified' status in the table to 0 (notified, but unverified). If for some reason we need to suppress it, setting -update => 0 (NOT UNDEF!) will do override it for us.

=item debug

This will print the email to screen will cause our database to NOT be updated (no matter what).

  $v-requestVerification(
  	...,
  	...,
  	-debug => 1,
  );

=back

Supported Email Args:

  -to,-from,-cc,-bcc,-subject,-type,-msg

See MIME::Lite for more info

Returns:

  Errstr on failure
  1 on success

=cut

sub requestVerification {
	my $self = shift;

	my $parms = parse_parms({
		-parms => \@_,
		-required => [ qw(-to -from -subject -msg) ],
		-defaults => {
			-msg => $self->msg(),
			-cc => '',
			-bcc => '',
			-update => 1,
		}
	});

	return "invalid parameters\n".Carp::longmess (Class::ParmList->error()) unless(defined($parms));

	my ($to,$from,$cc,$bcc,$subject,$type,$msg,$update,$debug) = $parms->get('-to','-from','-cc','-bcc','-subject','-type','-msg','-update','-debug');
	my $email = MIME::Lite->new(
		From	=> $from,
		To	=> $to,
		Cc	=> $cc,
		Bcc	=> $bcc,
		Subject	=> $subject,
		Type	=> $type,
		Data	=> $msg,
	);
	return (print $email->as_string()."\n") if($debug);
	my $rv = $email->send();
	if($rv){
		return (undef,1) unless($update);
		 $self->verify(-action => 0);
	}
	return ('msg failed to send: '.$rv,undef);
}

=head2 isVerified()

Method checks to see the verified status of the VID or keypair (type && type_id).

  my $rv = $v->isVerified(
  	# optional override of object properties
  	-type => $type,
  	-type_id => $type_id,
  	-vid => $vid,
  );

Returns:

  Errstr on failure
  verified status on success (see verifiy() for more details)

=cut

sub isVerified {
	my $self = shift;

	my $parms = parse_parms({
		-parms => \@_,
		-required => [],
		-legal => [ qw(-type -type_id -vid) ],
		-defaults => {
			-type => $self->type(),
			-type_id => $self->type_id(),
			-vid => $self->vid(),
		}
	});

	return ("invalid parameters\n".Carp::longmess (Class::ParmList->error()),undef) unless(defined($parms));
	my ($type,$type_id,$vid) = $parms->get('-type','-type_id','-vid');
	return ("invalid params: [type,type_id|vid] required!\n",undef) unless(($type && $type_id) || $vid);

	return ("check failed\n",undef) if($self->check(-type => $type, -type_id => $type_id, -vid => $vid) != 1);

	my ($sql,@x);
	if($vid) {
		$sql = 'SELECT `verified`, `verified_by` FROM `'.$self->table().'` WHERE id = ?';
		@x = ($vid);
	}
	else {
		$sql = 'SELECT `verified`, `verified_by` FROM `'.$self->table().'` WHERE type_id = ? AND type = ?';
		@x = ($type_id,$type);
	}

	my $sth = $self->dbh->prepare($sql);
	my $rv = $sth->execute(@x);
	return ('isVerified Failed: '.$self->dbh->errstr(),undef) unless($rv);

	my @row = $sth->fetchrow_array();
	return ($row[0]);
}

=head2 returnVid()

Returns the vid for a given pair of (type && type_id) assuming $v->vid() is not set.

  my $vid = $v->returnVid(
  	# optional override of object properties
  	-type => $type,
  	-type_id => $type_id,
  );

Returns:

  Errstr on failure
  vid on succeess

=cut

sub returnVid {
	my $self = shift;

	my $parms = parse_parms({
		-parms => \@_,
		-required => [ qw(-type -type_id) ],
		-defaults => {
			-type => $self->type(),
			-type_id => $self->type_id(),
		}
	});
	return ("invalid parameters\n".Carp::longmess (Class::ParmList->error()),undef) unless(defined($parms));
	my ($type,$type_id) = $parms->get('-type','-type_id');
	
	my $sql = 'SELECT id FROM `'.$self->table().'` WHERE `type` = ? and `type_id` = ?';
	my $sth = $self->dbh->prepare($sql);
	my $rv = $sth->execute($type,$type_id);
	my @row = $sth->fetchrow_array();
	return $row[0] if($row[0]);
	return ('no vid found',undef);
}

=head2 load()

Loads a verification record into our object or returns a fully loaded forked object.

  $v->load(
  	# optional override of object properties
  	-type => $type,
  	-type_id => $type_id,
  );

  my $newObject = $v->load(
  	# optional override of object properties
  	-vid => $vid,
  	-fork => 1,
  );

Returns:

  Errstr on failure
  1 on success and not forked
  New Object if forked

=cut

sub load {
	my $self = shift;

	my $parms = parse_parms({
		-parms => \@_,
		-legal => [qw(-type -type_id -vid -fork)],
		-defaults => {
			-type => $self->type(),
			-type_id => $self->type_id(),
			-vid => $self->vid(),
		}
	});
	return ("invalid parameters\n".Carp::longmess (Class::ParmList->error()),undef) unless(defined($parms));
	my ($type,$type_id,$vid,$fork) = $parms->get('-type','-type_id','-vid','-fork');
	return ("invalid params: [-type,-type_id|-vid] required!\n",undef) unless($vid || ($type && $type_id));

	my $sql = 'SELECT * FROM `'.$self->table().'` WHERE ';
	my @x;

	if($vid){ $sql .=  '`id` = ?'; $x[0] = $vid; }
	else { $sql .= '`type` = ? AND `type_id` = ?'; $x[0] = $type; $x[1] = $type_id; }

	my $sth = $self->dbh->prepare($sql);
	my $rv = $sth->execute(@x);
	return ('load failed: '.$self->dbh->errstr(),undef) unless($rv);

	my $hr = $sth->fetchrow_hashref();
	return ('no records found',undef) unless(keys %$hr);

	return ref($self)->new(
		-dbh 		=> $self->dbh,
		-vid		=> $hr->{id},
		-msg 		=> $hr->{msg},
		-dt_added 	=> $hr->{dt_added},
		-dt_updated 	=> $hr->{dt_updated},
		-type		=> $hr->{type},
		-type_id	=> $hr->{type_id},
		-verified	=> $hr->{verified},
		-id		=> $hr->{id},
		-verified_by	=> $hr->{verified_by},
		-verified_by_ip	=> $hr->{verified_by_ip},
	) if($fork);

	$self->vid(		$hr->{id});
	$self->type_id(		$hr->{type_id});
	$self->type(		$hr->{type});
	$self->verified(	$hr->{verified});
	$self->dt_added(	$hr->{dt_added});
	$self->dt_updated(	$hr->{dt_updated});
	$self->verified_by(	$hr->{verified_by});
	$self->verified_by_ip(	$hr->{verified_by_ip});
	$self->msg(		$hr->{msg});
	return (undef,1);
}

=head2 verify()

Sets the verification status of the object.

  $v->verify(
  	# required
  	-action => $action,

  	# optional override of object properties
  	-type => $type,
  	-type_id => $type_id,
  	-vid => $vid,
  	-verified_by => $verified_by,
  	-verified_by_ip => $vip,
  );

=cut

# action hashref
my $ACTIONS = {
	'UNVERIFIED'	=> 0,	# unverified but notification has been sent
	'VERIFY'	=> 1,	# duh
	'SUPPRESS'	=> 2,	# its what jcmurphy likes to call a 'false positive'
	'UNDEFINE'	=> 3,	# reset so the notification can be triggered again
	'REMOVE'	=> 4,	# get rid of the evidence
};

=pod

Actions [and or status]:

  0 - UNVERIFIED	# unverified but notification has been sent [set status to 'wait']
  1 - VERIFY		# duh
  2 - SUPPRESS		# its what jcmurphy likes to call a 'false positive'
  3 - UNDEFINE		# reset so the notification can be triggered again
  4 - REMOVE		# get rid of the evidence

Actions can be sent as strings or ints, it will figure out which automagically.

Returns:

  Errstr on failure
  1 on success

=cut

sub verify {
	my $self = shift;

	my $parms = parse_parms({
		-parms => \@_,
		-required => [qw(-verified_by -action)],
		-legal => [qw(-type -type_id -vid -verified_by -action -verified_by_ip)],
		-defaults => {
			-type => $self->type(),
			-type_id => $self->type_id(),
			-vid => $self->vid(),
			-verified_by => $self->verified_by(),
			-verified_by_ip => $self->verified_by_ip(),
		}
	});
	return ("invalid parameters\n".Carp::longmess (Class::ParmList->error()),undef) unless(defined($parms));
	my ($vid,$type,$type_id,$verified_by,$action,$verified_by_ip) = $parms->get('-vid','-type','-type_id','-verified_by','-action','-verified_by_ip');
	return ("missing parmaeters\n",undef) unless(($vid) || ($type && $type_id));

	return ('check failed',undef) if(!$self->check(-type => $type, -type_id => $type_id, -vid => $vid));
	my $status = $self->isVerified();
	return ('already processed',undef) if(defined($status) && $status > 0);
	my $a = $action;
	$action = $ACTIONS->{uc($action)} if(!($action =~ /^\d+$/)); # change to int if they sent a string
	
	return ('invalid action: '.uc($a),undef) unless(defined($action) && $action =~ /^[0-3]$/);
	return $self->remove() if($action == 4);
	$action = undef if($action == 3);

	my @x; $x[0] = $action; $x[1] = $verified_by; $x[2] = time();
	my $sql = 'UPDATE `'.$self->table().'` SET `verified` = ?, `verified_by` = ?, `dt_updated` = ?';

	if($self->verified_by_ip){
		$sql .= ', verified_by_ip = '.$self->dbh->quote($self->verified_by_ip->intip());
	}

	if($vid){
		$sql .= ' WHERE id = ?';
		$x[3] = $vid;
	}
	else{
		$sql .= ' WHERE type_id = ? AND type = ?';
		$x[3] = $type_id; $x[4] = $type;
	}

	my $sth = $self->dbh->prepare($sql);
	my $rv = $sth->execute(@x);
	return (undef,1) if($rv);
	return ('Verification failed: '.$self->dbh->errstr(),undef);
}

=head2 remove()

Removes the record from our table that this object represents.

  $v->remove(
  	# optional override of object properties
  	-vid => $vid,
  	-type => $type,
  	-type_id => $type_id,
  );

Returns:

  Errstr on failure
  1 on success

=cut

sub remove {
	my $self = shift;

	my $parms = parse_parms({
		-parms => \@_,
		-defaults => {
			-vid => $self->vid(),
			-type => $self->type(),
			-type_id => $self->type_id(),
		}
	});
	return ("invalid parameters\n".Carp::longmess (Class::ParmList->error()),undef) unless(defined($parms));
	my ($vid,$type,$type_id) = $parms->get('-vid','-type','-type_id');
	return ('missing required parameters: [vid || type && type_id]',undef) unless($vid || ($type && $type_id));

	my ($sql,@x);

	if($vid) {
		$sql = 'DELETE FROM `'.$self->table().'` WHERE `id` = ?';
		$x[0] = $vid;
	}
	else {
		$sql = 'DELETE FROM `'.$self->table().'` WHERE `type` = ? AND `type_id` = ?';
		$x[0] = $type;
		$x[1] = $type_id;
	}

	my $sth = $self->dbh->prepare($sql);
	my $rv = $sth->execute(@x);

	return (undef,1) unless(!$rv);
	return ('remove failed: '.$self->dbh->errstr(),undef);
}

=head2 returnUnverified()

By default this method returns an array of unverified objects from the database. Optionally a parm can override this and force the function to return a raw hashref too. There is a HARD_RETURN_LIMIT on the number of keys that can be accessed. This can also be overridden.

  my @aryOfObjects = $v->returnUnverified(
  	# optional overrides
  	-type => $type
  );

  my $hashref = $v->returnUnverified(
  	-limit => 1000,
  	-hashref => 1,
  );

=over 4

=item limit

This will override the hard coded limit of 500. Setting -limit => 0 will return ALL records (use with caution on large databases). Because of this, if the hard limit is set, the query will return the data in desc order.

=item hashref

This will return a raw hashref instead of an array of objects (set to 1).

=back

Returns:

  Errstr on failure
  HASHREF or OBJECT on success

=cut

sub returnUnverified {
	my $self = shift;

	my $parms = parse_parms({
		-parms =>\@_,
		-legal => [qw(-type -limit -hashref)],
		-defaults => {
			-type => $self->type(),
			-limit => HARD_RETURN_LIMIT(),
		}
	});
	return ("invalid parameters\n".Carp::longmess (Class::ParmList->error()),undef) unless(defined($parms));
	my ($type,$limit,$hashref) = $parms->get('-type','-limit','-hashref');

	my $sql = 'SELECT * FROM `'.$self->table().'` WHERE verified = 0';
	$sql .= ' AND type = '.$self->dbh->quote($type) if($type);
	$sql .= ' ORDER BY id DESC';
	$sql .= ' LIMIT '.$limit if($limit != 0);

	my $sth = $self->dbh->prepare($sql);
	my $rv = $sth->execute();

	return ('QueryFailed: '.$self->dbh->errstr(),undef) unless($rv);

	my $hr = $sth->fetchall_hashref('id');
	return $hr if($hashref);

	my @a;
	foreach my $x (keys %$hr){
		push(@a,ref($self)->new(
			-dbh 		=> $self->dbh(),
			-vid		=> $hr->{$x}->{id},
			-msg 		=> $hr->{$x}->{msg},
			-dt_added 	=> $hr->{$x}->{dt_added},
			-dt_updated 	=> $hr->{$x}->{dt_updated},
			-type		=> $hr->{$x}->{type},
			-type_id	=> $hr->{$x}->{type_id},
			-verified	=> $hr->{$x}->{verified},
			-id		=> $hr->{$x}->{id},
			-verified_by	=> $hr->{$x}->{verified_by},
			-verified_by_ip	=> $hr->{$x}->{verified_by_ip},
			)
		)
	}
	return @a;	
}

=head2 returnUnprocessed()

See returnUnVerified().

This returns anything that has verified set to NULL (ie: no notifications have been sent yet).

=cut

sub returnUnprocessed {
	my $self = shift;

	my $parms = parse_parms({
		-parms => \@_,
		-legal => [qw(-type -limit -hashref)],
		-defaults => {
			-type => $self->type(),
			-limit => HARD_RETURN_LIMIT(),
		}
	});

	return ("invalid parameters\n".Carp::longmess (Class::ParmList->error()),undef) unless(defined($parms));
	my ($type,$limit,$hashref) = $parms->get('-type','-limit','-hashref');

	my $sql = 'SELECT * FROM `'.$self->table().'` WHERE verified IS NULL';
	$sql .= ' AND type = '.$self->dbh->quote($type) if($type);
	$sql .= ' ORDER BY id DESC';
	$sql .= ' LIMIT '.$limit if($limit != 0);

	my $sth = $self->dbh->prepare($sql);
	my $rv = $sth->execute();

	return ('QueryFailed: '.$self->dbh->errstr(),undef) unless($rv);
	my $hr = $sth->fetchall_hashref('id');
	return $hr if($hashref);

	my @a;
	foreach my $x (keys %$hr){
		push(@a,ref($self)->new(
			-dbh 		=> $self->dbh(),
			-vid		=> $hr->{$x}->{id},
			-msg 		=> $hr->{$x}->{msg},
			-dt_added 	=> $hr->{$x}->{dt_added},
			-dt_updated 	=> $hr->{$x}->{dt_updated},
			-type		=> $hr->{$x}->{type},
			-type_id		=> $hr->{$x}->{type_id},
			-verified	=> $hr->{$x}->{verified},
			-id		=> $hr->{$x}->{id},
			-verified_by	=> $hr->{$x}->{verified_by},
			-verified_by_ip	=> $hr->{$x}->{verified_by_ip},
			)
		)
	}
	return @a;	
}

=pod

=head1 OBJECT ACCESSORS and MODIFIERS

=head2 dbh()

Sets and Retrieves dbh handle

=cut

sub dbh {
	my ($self,$v) = @_;
	$self->{_dbh} = $v if(defined($v));
	return $self->{_dbh};
}

=head2 table()

Sets and Retrieves the default table to use in our lookups

=cut

sub table {
	my ($self,$v) = @_;
	$self->{_table} = $v if(defined($v));
	return $self->{_table};
}

=head2 vid()

Sets and Retrieves the Verification ID

=cut

sub vid {
	my ($self,$v) = @_;
	$self->{_vid} = $v if(defined($v));
	return $self->{_vid};
}

=head2 type()

Sets and Retrieves the type of data we are working with (usually the other table name).

=cut

sub type {
	my ($self,$v) = @_;
	$self->{_type} = $v if(defined($v));
	return $self->{_type};
}


=head2 type_id()

Sets and Retrieves the key id for the type of data we are working with (the key in the other table).

=cut

sub type_id {
	my ($self,$v) = @_;
	$self->{_type_id} = $v if(defined($v));
	return $self->{_type_id};
}

=head2 verified()

Sets and Retrieves the objects verification status

=cut

sub verified {
	my ($self,$v) = @_;
	$self->{_verified} = $v if(defined($v));
	return $self->{_verified};
}

=head2 dt_added()

Sets and Retrieves the date our vid was added. Returns a Time::Timestamp object

=cut

sub dt_added {
	my ($self,$v) = @_;
	$self->{_dt_added} = Time::Timestamp->new(ts => $v) if(defined($v));
	return $self->{_dt_added};
}

=head2 dt_updated()

Sets and Retrieves the date our vid was last updated. Returns a Time::Timestamp object

=cut

sub dt_updated {
	my ($self,$v) = @_;
	$self->{_dt_updated} = Time::Timestamp->new(ts => $v) if(defined($v));
	return $self->{_dt_updated};
}

=head2 verified_by()

Sets and Retrieves who last set our verified field

=cut

sub verified_by {
	my ($self,$v) = @_;
	$self->{_verified_by} = $v if(defined($v));
	return $self->{_verified_by};
}

=head2 verified_by_ip()

Sets and Retrieves what ip was used to set our last verified field. Returns a Net::IP object. Accepts Big::Int's.

=cut

sub verified_by_ip {
	my ($self,$v) = @_;
	if($v){
		$v = Net::IP::bintoip(Net::IP::inttobin($v)) if($v =~ /^\d+$/);
		$self->{_verified_by_ip} = Net::IP->new($v);
	}
	return $self->{_verified_by_ip};
}

=head2 msg()

Sets and Retrieves an optional msg that explains what needs verifying (ie: the body used to be sent in a $self->requestVerification() email.

=cut

sub msg {
	my ($self,$v) = @_;
	$self->{_msg} = $v if(defined($v));
	return $self->{_msg};
}

1;
__END__

=head1 SEE ALSO

Database::Wrapper,MIME::Lite,Time::Timestamp,Net::IP

=head1 AUTHOR

Wes Young, E<lt>saxguard9-cpan@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Wes Young

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut