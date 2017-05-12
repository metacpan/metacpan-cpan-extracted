package Class::AutoDB::Connect;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use DBI;
use Class::AutoClass;
use File::Spec;
use Hash::AutoHash::Args;
use Class::AutoDB::Serialize;
@ISA = qw(Class::AutoClass);

# Mixin for Class::AutoDB. Handles database connection
@AUTO_ATTRIBUTES=qw(dbh user password 
		    _needs_disconnect);
@OTHER_ATTRIBUTES=qw(dbd dsn database host socket port timeout);
%SYNONYMS=(server=>'host', sock=>'socket',pass=>'password');
%DEFAULTS=(user=>$ENV{USER});
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  $self->_connect($args);	       # NG 09-12-06: added $args so _connect can be smarter
}
my @connection_attributes=grep !/^_/,@AUTO_ATTRIBUTES,@OTHER_ATTRIBUTES,keys %SYNONYMS;
sub connect {
  my($self,@args)=@_;
  return $self->dbh if $self->dbh;              # if dbh set, then already connected
  my $args=new Hash::AutoHash::Args(@args);
  # NG 09-12-06: changed to use @connection_attributes defined above
  # $self->Class::AutoClass::set_attributes([qw(dbh dsn dbd host server user password)],$args);
  $self->Class::AutoClass::set_attributes(\@connection_attributes,$args);
  $self->_connect($args);              # NG 09-12-06: added $args so _connect can be smarter
}
sub disconnect {
  my($self,$args)=@_;
  $self->_disconnect($args);	# does everything except clear dbh
  $self->dbh(undef);
}
# NG 09-12-06: changed to always disconnect. why not??
sub reconnect {
  my($self,@args)=@_;
  my $args=new Hash::AutoHash::Args(@args);
  $self->Class::AutoClass::set_attributes(\@connection_attributes,$args);
  $self->_disconnect($args);	# disconnect by leave dbh set in case _connect needs it
  $self->_connect($args);	# ...and reconnect
}
sub is_connected {$_[0]->dbh;}
sub ping {
  my $self=shift;
  my $dbh=$self->dbh or return undef;
  $dbh->ping();
}
# # disconnect and connect if new params not consistent with old
# our @reconnect_params=qw(database host sock user password);
# sub reconnect {
#   my($self,@args)=@_;
#   my $args=new Hash::AutoHash::Args(@args);
#   my(%new_params,%old_params);
#   # NG 09-03-19: changed to use HASH notation instead of deprecated version 0 methods
#   # @new_params{@reconnect_params}=$args->get_args(@reconnect_params);
#   @new_params{@reconnect_params}=@$args{@reconnect_params};
#   if (my $dsn=$args->dsn) {	# copy dsn values into params
#     ($new_params{database})=$dsn=~/database=(\w*)/;
#     ($new_params{host})=$dsn=~/host=(\w*)/;
#     ($new_params{sock})=$dsn=~/mysql_socket=(\w*)/;
#   }
#   @old_params{@reconnect_params}=$self->get(@reconnect_params);
#   if (grep {$new_params{$_} ne $old_params{$_}} @reconnect_params) { 
#     $self->disconnect;	   # some params don't match, so disconnect...
#     $self->connect($args); # ...and reconnect
#   }
# }

sub _connect {
  my($self,$args)=@_;
  my $dbd=lc($self->dbd)||'mysql';
  $self->throw("-dbd must be 'mysql' at present") if $dbd && $dbd ne 'mysql';
  my $dsn=$self->dsn;
  if ($dsn) {                   # parse off the dbd, database, host elements
    $dsn = "DBI:$dsn" unless $dsn=~ /^dbi/i;
  } else {
    my $database=$self->database;
    return undef unless $database;
    my $host=$self->host || 'localhost';
    my $sock=$self->sock;
    my $port=$self->port;
    my @props=("database=$database","host=$host");
    push(@props,"port=$port") if defined $port;
    # NG 13-07-28: using wrong prop! should be mysql_socket
    # push(@props,"sock=$sock") if defined $sock;
    if (defined $sock) {
      $sock=File::Spec->rel2abs($sock);
      push(@props,"mysql_socket=$sock");
    }
    my $props=join(';',@props);
    $dsn="DBI:$dbd:$props";
  }
  # Try to establish connection with data source.
  # NG 09-120=-06: added mysql_auto_reconnect
  my $dbh = DBI->connect($dsn,$self->user,$self->password,
                         {AutoCommit=>1, ChopBlanks=>1, PrintError=>0, PrintWarn=>0, Warn=>0,
			  mysql_auto_reconnect=>1});
  $self->throw("DBI::connect failed for dsn=$dsn, user=".$self->user.": ".DBI->errstr) unless $dbh;
  $self->dbh($dbh);
  # NG 09-12-05: now computed as needed
  #  $self->dsn($dsn);
  #  $self->dbd($dbd);		# NG 09-12-05: dunno why this was missing...
  $self->_needs_disconnect(1);
  Class::AutoDB::Serialize->dbh($dbh); # TODO: this will change when Serialize changes
  # NG 09-12-06: rewrote next paragraph to use 'timeout' method
  #              moved to end of sub so 'dbh' set
  #              MySQL default now 28800 (8 hours). don't set to smaller value!
  #              added 'elsif' to really set timeout
  if (defined $DB::IN) {        # running in debugger, so set long timeout
    # NG 09-12-06: rewrote to use 'timeout' method
    # $dbh->do('set session wait_timeout=3600');
    $self->timeout(28800) if $self->timeout<28800;
  } elsif ($args->timeout) {	# really set timeout now that 'dbh' is set
    $self->timeout($args->timeout);
  }
  return $dbh;
}
sub _disconnect {
  my($self)=@_;
  my $dbh=$self->dbh or return undef;
  $self->dbh->disconnect;
  $self->_needs_disconnect(0);
}

# NG 09-12-05: get connection parameters from dbh if defined
sub dbd {
  my $self=shift;
  return $self->{dbd}=$_[0] if @_;
  my $dbh=$self->dbh;
  $self->{dbd}=$dbh->{Driver}->{Name} if $dbh;
  $self->{dbd};
}
sub dsn {
  my $self=shift;
  return $self->{dsn}=$_[0] if @_;
  my $dbh=$self->dbh;
  $self->{dsn}='DBI:'.$self->dbd.':'.$dbh->{Name} if $dbh;
  $self->{dsn};
}
sub database {
  my $self=shift;
  return $self->{database}=$_[0] if @_;
  my $dbh=$self->dbh;
  $self->{database}=_dbh_prop($dbh,'database') if $dbh;
  $self->{database};
}
sub host {
  my $self=shift;
  return $self->{host}=$_[0] if @_;
  my $dbh=$self->dbh;
  $self->{host}=_dbh_prop($dbh,'host') if $dbh;
  $self->{host};
}
sub socket {
  my $self=shift;
  return $self->{socket}=$_[0] if @_;
  my $dbh=$self->dbh;
  $self->{socket}=_dbh_prop($dbh,'mysql_socket') if $dbh;
  $self->{socket};
}
sub port {
  my $self=shift;
  return $self->{port}=$_[0] if @_;
  my $dbh=$self->dbh;
  $self->{port}=_dbh_prop($dbh,'port') if $dbh;
  $self->{port};
}
# NG 09-12-06: added timeout
sub timeout {
  my $self=shift;
  my $dbh=$self->dbh;
  if (@_) {
    my $timeout=$self->{timeout}=$_[0];
    # set session variable if connected
    $dbh->do(qq(SET SESSION wait_timeout=$timeout)) if $dbh;
  }
  if ($dbh) {
    my @timeout=$dbh->selectrow_array(qq(SHOW VARIABLES WHERE Variable_Name='wait_timeout'));
    $self->{timeout}=$timeout[1]; # @timeout is ('wait_timeout',<value>)
  }
  $self->{timeout};
}
sub _dbh_prop {
  my($dbh,$propname)=@_;
  my @props=split(';',$dbh->{Name}); # $dbh->{Name} gives property list
  my %props=map {/(.*)=(.*)/} @props;
  $props{$propname};
}

1;
