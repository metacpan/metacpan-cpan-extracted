#line 1
package CGI::Session;

# $Id: Session.pm 353 2006-12-05 02:10:19Z markstos $

use strict;
use Carp;
use CGI::Session::ErrorHandler;

@CGI::Session::ISA      = qw( CGI::Session::ErrorHandler );
$CGI::Session::VERSION  = '4.20';
$CGI::Session::NAME     = 'CGISESSID';
$CGI::Session::IP_MATCH = 0;

sub STATUS_NEW      () { 1 }        # denotes session that's just created
sub STATUS_MODIFIED () { 2 }        # denotes session that needs synchronization
sub STATUS_DELETED  () { 4 }        # denotes session that needs deletion
sub STATUS_EXPIRED  () { 8 }        # denotes session that was expired.

sub import {
    my ($class, @args) = @_;

    return unless @args;

  ARG:
    foreach my $arg (@args) {
        if ($arg eq '-ip_match') {
            $CGI::Session::IP_MATCH = 1;
            last ARG;
        }
    }
}

sub new {
    my ($class, @args) = @_;

    my $self;
    if (ref $class) {
        #
        # Called as an object method as in $session->new()...
        #
        $self  = bless { %$class }, ref( $class );
        $class = ref $class;
        $self->_reset_status();
        #
        # Object may still have public data associated with it, but we
        # don't care about that, since we want to leave that to the
        # client's disposal. However, if new() was requested on an
        # expired session, we already know that '_DATA' table is
        # empty, since it was the job of flush() to empty '_DATA'
        # after deleting. How do we know flush() was already called on
        # an expired session? Because load() - constructor always
        # calls flush() on all to-be expired sessions
        #
    }
    else {
        #
        # Called as a class method as in CGI::Session->new()
        #
        $self = $class->load( @args );
        if (not defined $self) {
            return $class->set_error( "new(): failed: " . $class->errstr );
        }
    }
    my $dataref = $self->{_DATA};
    unless ($dataref->{_SESSION_ID}) {
        #
        # Absence of '_SESSION_ID' can only signal:
        # * Expired session: Because load() - constructor is required to
        #                    empty contents of _DATA - table
        # * Unavailable session: Such sessions are the ones that don't
        #                    exist on datastore, but are requested by client
        # * New session: When no specific session is requested to be loaded
        #
        my $id = $self->_id_generator()->generate_id(
                                                     $self->{_DRIVER_ARGS},
                                                     $self->{_CLAIMED_ID}
                                                     );
        unless (defined $id) {
            return $self->set_error( "Couldn't generate new SESSION-ID" );
        }
        $dataref->{_SESSION_ID} = $id;
        $dataref->{_SESSION_CTIME} = $dataref->{_SESSION_ATIME} = time();
        $self->_set_status( STATUS_NEW );
    }
    return $self;
}

sub DESTROY         {   $_[0]->flush()      }
sub close           {   $_[0]->flush()      }

*param_hashref      = \&dataref;
my $avoid_single_use_warning = *param_hashref;
sub dataref         { $_[0]->{_DATA}        }

sub is_empty        { !defined($_[0]->id)   }

sub is_expired      { $_[0]->_test_status( STATUS_EXPIRED ) }

sub is_new          { $_[0]->_test_status( STATUS_NEW ) }

sub id              { return defined($_[0]->dataref) ? $_[0]->dataref->{_SESSION_ID}    : undef }

# Last Access Time
sub atime           { return defined($_[0]->dataref) ? $_[0]->dataref->{_SESSION_ATIME} : undef }

# Creation Time
sub ctime           { return defined($_[0]->dataref) ? $_[0]->dataref->{_SESSION_CTIME} : undef }

sub _driver {
    my $self = shift;
    defined($self->{_OBJECTS}->{driver}) and return $self->{_OBJECTS}->{driver};
    my $pm = "CGI::Session::Driver::" . $self->{_DSN}->{driver};
    defined($self->{_OBJECTS}->{driver} = $pm->new( $self->{_DRIVER_ARGS} ))
        or die $pm->errstr();
    return $self->{_OBJECTS}->{driver};
}

sub _serializer     { 
    my $self = shift;
    defined($self->{_OBJECTS}->{serializer}) and return $self->{_OBJECTS}->{serializer};
    return $self->{_OBJECTS}->{serializer} = "CGI::Session::Serialize::" . $self->{_DSN}->{serializer};
}


sub _id_generator   { 
    my $self = shift;
    defined($self->{_OBJECTS}->{id}) and return $self->{_OBJECTS}->{id};
    return $self->{_OBJECTS}->{id} = "CGI::Session::ID::" . $self->{_DSN}->{id};
}

sub _ip_matches {
  return ( $_[0]->{_DATA}->{_SESSION_REMOTE_ADDR} eq $ENV{REMOTE_ADDR} );
}


# parses the DSN string and returns it as a hash.
# Notably: Allows unique abbreviations of the keys: driver, serializer and 'id'.
# Also, keys and values of the returned hash are lower-cased.
sub parse_dsn {
    my $self = shift;
    my $dsn_str = shift;
    croak "parse_dsn(): usage error" unless $dsn_str;

    require Text::Abbrev;
    my $abbrev = Text::Abbrev::abbrev( "driver", "serializer", "id" );
    my %dsn_map = map { split /:/ } (split /;/, $dsn_str);
    my %dsn  = map { $abbrev->{lc $_}, lc $dsn_map{$_} } keys %dsn_map;
    return \%dsn;
}

sub query {
    my $self = shift;

    if ( $self->{_QUERY} ) {
        return $self->{_QUERY};
    }
#   require CGI::Session::Query;
#   return $self->{_QUERY} = CGI::Session::Query->new();
    require CGI;
    return $self->{_QUERY} = CGI->new();
}


sub name {
    my $self = shift;
    
    if (ref $self) {
        unless ( @_ ) {
            return $self->{_NAME} || $CGI::Session::NAME;
        }
        return $self->{_NAME} = $_[0];
    }
    
    $CGI::Session::NAME = $_[0] if @_;
    return $CGI::Session::NAME;
}


sub dump {
    my $self = shift;

    require Data::Dumper;
    my $d = Data::Dumper->new([$self], [ref $self]);
    $d->Deepcopy(1);
    return $d->Dump();
}


sub _set_status {
    my $self    = shift;
    croak "_set_status(): usage error" unless @_;
    $self->{_STATUS} |= $_ for @_;
}


sub _unset_status {
    my $self = shift;
    croak "_unset_status(): usage error" unless @_;
    $self->{_STATUS} &= ~$_ for @_;
}


sub _reset_status {
    $_[0]->{_STATUS} = 0;
}

sub _test_status {
    return $_[0]->{_STATUS} & $_[1];
}


sub flush {
    my $self = shift;

    # Would it be better to die or err if something very basic is wrong here? 
    # I'm trying to address the DESTORY related warning
    # from: http://rt.cpan.org/Ticket/Display.html?id=17541
    # return unless defined $self;

    return unless $self->id;            # <-- empty session
    return if !defined($self->{_STATUS}) or $self->{_STATUS} == 0;    # <-- neither new, nor deleted nor modified

    if ( $self->_test_status(STATUS_NEW) && $self->_test_status(STATUS_DELETED) ) {
        $self->{_DATA} = {};
        return $self->_unset_status(STATUS_NEW, STATUS_DELETED);
    }

    my $driver      = $self->_driver();
    my $serializer  = $self->_serializer();

    if ( $self->_test_status(STATUS_DELETED) ) {
        defined($driver->remove($self->id)) or
            return $self->set_error( "flush(): couldn't remove session data: " . $driver->errstr );
        $self->{_DATA} = {};                        # <-- removing all the data, making sure
                                                    # it won't be accessible after flush()
        return $self->_unset_status(STATUS_DELETED);
    }

    if ( $self->_test_status(STATUS_NEW) || $self->_test_status(STATUS_MODIFIED) ) {
        my $datastr = $serializer->freeze( $self->dataref );
        unless ( defined $datastr ) {
            return $self->set_error( "flush(): couldn't freeze data: " . $serializer->errstr );
        }
        defined( $driver->store($self->id, $datastr) ) or
            return $self->set_error( "flush(): couldn't store datastr: " . $driver->errstr);
        $self->_unset_status(STATUS_NEW, STATUS_MODIFIED);
    }
    return 1;
}

sub trace {}
sub tracemsg {}

sub param {
    my ($self, @args) = @_;

    if ($self->_test_status( STATUS_DELETED )) {
        carp "param(): attempt to read/write deleted session";
    }

    # USAGE: $s->param();
    # DESC:  Returns all the /public/ parameters
    if (@args == 0) {
        return grep { !/^_SESSION_/ } keys %{ $self->{_DATA} };
    }
    # USAGE: $s->param( $p );
    # DESC: returns a specific session parameter
    elsif (@args == 1) {
        return $self->{_DATA}->{ $args[0] }
    }


    # USAGE: $s->param( -name => $n, -value => $v );
    # DESC:  Updates session data using CGI.pm's 'named param' syntax.
    #        Only public records can be set!
    my %args = @args;
    my ($name, $value) = @args{ qw(-name -value) };
    if (defined $name && defined $value) {
        if ($name =~ m/^_SESSION_/) {

            carp "param(): attempt to write to private parameter";
            return undef;
        }
        $self->_set_status( STATUS_MODIFIED );
        return $self->{_DATA}->{ $name } = $value;
    }

    # USAGE: $s->param(-name=>$n);
    # DESC:  access to session data (public & private) using CGI.pm's 'named parameter' syntax.
    return $self->{_DATA}->{ $args{'-name'} } if defined $args{'-name'};

    # USAGE: $s->param($name, $value);
    # USAGE: $s->param($name1 => $value1, $name2 => $value2 [,...]);
    # DESC:  updates one or more **public** records using simple syntax
    if ((@args % 2) == 0) {
        my $modified_cnt = 0;
	ARG_PAIR:
        while (my ($name, $val) = each %args) {
            if ( $name =~ m/^_SESSION_/) {
                carp "param(): attempt to write to private parameter";
                next ARG_PAIR;
            }
            $self->{_DATA}->{ $name } = $val;
            ++$modified_cnt;
        }
        $self->_set_status(STATUS_MODIFIED);
        return $modified_cnt;
    }

    # If we reached this far none of the expected syntax were
    # detected. Syntax error
    croak "param(): usage error. Invalid syntax";
}



sub delete {    $_[0]->_set_status( STATUS_DELETED )    }


*header = \&http_header;
my $avoid_single_use_warning_again = *header;
sub http_header {
    my $self = shift;
    return $self->query->header(-cookie=>$self->cookie, -type=>'text/html', @_);
}

sub cookie {
    my $self = shift;

    my $query = $self->query();
    my $cookie= undef;

    if ( $self->is_expired ) {
        $cookie = $query->cookie( -name=>$self->name, -value=>$self->id, -expires=> '-1d', @_ );
    } 
    elsif ( my $t = $self->expire ) {
        $cookie = $query->cookie( -name=>$self->name, -value=>$self->id, -expires=> '+' . $t . 's', @_ );
    } 
    else {
        $cookie = $query->cookie( -name=>$self->name, -value=>$self->id, @_ );
    }
    return $cookie;
}





sub save_param {
    my $self = shift;
    my ($query, $params) = @_;

    $query  ||= $self->query();
    $params ||= [ $query->param ];

    for my $p ( @$params ) {
        my @values = $query->param($p) or next;
        if ( @values > 1 ) {
            $self->param($p, \@values);
        } else {
            $self->param($p, $values[0]);
        }
    }
    $self->_set_status( STATUS_MODIFIED );
}



sub load_param {
    my $self = shift;
    my ($query, $params) = @_;

    $query  ||= $self->query();
    $params ||= [ $self->param ];

    for ( @$params ) {
        $query->param(-name=>$_, -value=>$self->param($_));
    }
}


sub clear {
    my $self    = shift;
    my $params  = shift;
    #warn ref($params);
    if (defined $params) {
        $params =  [ $params ] unless ref $params;
    }
    else {
        $params = [ $self->param ];
    }

    for ( grep { ! /^_SESSION_/ } @$params ) {
        delete $self->{_DATA}->{$_};
    }
    $self->_set_status( STATUS_MODIFIED );
}


sub find {
    my $class       = shift;
    my ($dsn, $coderef, $dsn_args);

    # find( \%code )
    if ( @_ == 1 ) {
        $coderef = $_[0];
    } 
    # find( $dsn, \&code, \%dsn_args )
    else {
        ($dsn, $coderef, $dsn_args) = @_;
    }

    unless ( $coderef && ref($coderef) && (ref $coderef eq 'CODE') ) {
        croak "find(): usage error.";
    }

    my $driver;
    if ( $dsn ) {
        my $hashref = $class->parse_dsn( $dsn );
        $driver     = $hashref->{driver};
    }
    $driver ||= "file";
    my $pm = "CGI::Session::Driver::" . ($driver =~ /(.*)/)[0];
    eval "require $pm";
    if (my $errmsg = $@ ) {
        return $class->set_error( "find(): couldn't load driver." . $errmsg );
    }

    my $driver_obj = $pm->new( $dsn_args );
    unless ( $driver_obj ) {
        return $class->set_error( "find(): couldn't create driver object. " . $pm->errstr );
    }

    my $dont_update_atime = 0;
    my $driver_coderef = sub {
        my ($sid) = @_;
        my $session = $class->load( $dsn, $sid, $dsn_args, $dont_update_atime );
        unless ( $session ) {
            return $class->set_error( "find(): couldn't load session '$sid'. " . $class->errstr );
        }
        $coderef->( $session );
    };

    defined($driver_obj->traverse( $driver_coderef ))
        or return $class->set_error( "find(): traverse seems to have failed. " . $driver_obj->errstr );
    return 1;
}

# $Id: Session.pm 353 2006-12-05 02:10:19Z markstos $

#line 632

# pass a true value as the fourth parameter if you want to skip the changing of
# access time This isn't documented more formally, because it only called by
# find().
sub load {
    my $class = shift;
    return $class->set_error( "called as instance method")    if ref $class;
    return $class->set_error( "Too many arguments")  if @_ > 4;

    my $self = bless {
        _DATA       => {
            _SESSION_ID     => undef,
            _SESSION_CTIME  => undef,
            _SESSION_ATIME  => undef,
            _SESSION_REMOTE_ADDR => $ENV{REMOTE_ADDR} || "",
            #
            # Following two attributes may not exist in every single session, and declaring
            # them now will force these to get serialized into database, wasting space. But they
            # are here to remind the coder of their purpose
            #
#            _SESSION_ETIME  => undef,
#            _SESSION_EXPIRE_LIST => {}
        },          # session data
        _DSN        => {},          # parsed DSN params
        _OBJECTS    => {},          # keeps necessary objects
        _DRIVER_ARGS=> {},          # arguments to be passed to driver
        _CLAIMED_ID => undef,       # id **claimed** by client
        _STATUS     => 0,           # status of the session object
        _QUERY      => undef        # query object
    }, $class;

    my ($dsn,$query_or_sid,$dsn_args,$update_atime);
    # load($query||$sid)
    if ( @_ == 1 ) {
        $self->_set_query_or_sid($_[0]);
    }
    # Two or more args passed:
    # load($dsn, $query||$sid)
    elsif ( @_ > 1 ) {
        ($dsn, $query_or_sid, $dsn_args,$update_atime) = @_;

        # Since $update_atime is not part of the public API
        # we ignore any value but the one we use internally: 0.
        if (defined $update_atime and $update_atime ne '0') {
            return $class->set_error( "Too many arguments");
         }

        if ( defined $dsn ) {      # <-- to avoid 'Uninitialized value...' warnings
            $self->{_DSN} = $self->parse_dsn($dsn);
        }
        $self->_set_query_or_sid($query_or_sid);

        # load($dsn, $query, \%dsn_args);

        $self->{_DRIVER_ARGS} = $dsn_args if defined $dsn_args;

    }

    $self->_load_pluggables();

    if (not defined $self->{_CLAIMED_ID}) {
        my $query = $self->query();
        eval {
            $self->{_CLAIMED_ID} = $query->cookie( $self->name ) || $query->param( $self->name );
        };
        if ( my $errmsg = $@ ) {
            return $class->set_error( "query object $query does not support cookie() and param() methods: " .  $errmsg );
        }
    }

    # No session is being requested. Just return an empty session
    return $self unless $self->{_CLAIMED_ID};

    # Attempting to load the session
    my $driver = $self->_driver();
    my $raw_data = $driver->retrieve( $self->{_CLAIMED_ID} );
    unless ( defined $raw_data ) {
        return $self->set_error( "load(): couldn't retrieve data: " . $driver->errstr );
    }
    
    # Requested session couldn't be retrieved
    return $self unless $raw_data;

    my $serializer = $self->_serializer();
    $self->{_DATA} = $serializer->thaw($raw_data);
    unless ( defined $self->{_DATA} ) {
        #die $raw_data . "\n";
        return $self->set_error( "load(): couldn't thaw() data using $serializer:" .
                                $serializer->errstr );
    }
    unless (defined($self->{_DATA}) && ref ($self->{_DATA}) && (ref $self->{_DATA} eq 'HASH') &&
            defined($self->{_DATA}->{_SESSION_ID}) ) {
        return $self->set_error( "Invalid data structure returned from thaw()" );
    }

    # checking if previous session ip matches current ip
    if($CGI::Session::IP_MATCH) {
      unless($self->_ip_matches) {
        $self->_set_status( STATUS_DELETED );
        $self->flush;
        return $self;
      }
    }

    # checking for expiration ticker
    if ( $self->{_DATA}->{_SESSION_ETIME} ) {
        if ( ($self->{_DATA}->{_SESSION_ATIME} + $self->{_DATA}->{_SESSION_ETIME}) <= time() ) {
            $self->_set_status( STATUS_EXPIRED );   # <-- so client can detect expired sessions
            $self->_set_status( STATUS_DELETED );   # <-- session should be removed from database
            $self->flush();                         # <-- flush() will do the actual removal!
            return $self;
        }
    }

    # checking expiration tickers of individuals parameters, if any:
    my @expired_params = ();
    while (my ($param, $max_exp_interval) = each %{ $self->{_DATA}->{_SESSION_EXPIRE_LIST} } ) {
        if ( ($self->{_DATA}->{_SESSION_ATIME} + $max_exp_interval) <= time() ) {
            push @expired_params, $param;
        }
    }
    $self->clear(\@expired_params) if @expired_params;

    # We update the atime by default, but if this (otherwise undocoumented)
    # parameter is explicitly set to false, we'll turn the behavior off
    if ( ! defined $update_atime ) {
        $self->{_DATA}->{_SESSION_ATIME} = time();      # <-- updating access time
        $self->_set_status( STATUS_MODIFIED );          # <-- access time modified above
    }
    
    return $self;
}


# set the input as a query object or session ID, depending on what it looks like.  
sub _set_query_or_sid {
    my $self = shift;
    my $query_or_sid = shift;
    if ( ref $query_or_sid){ $self->{_QUERY}       = $query_or_sid  }
    else                   { $self->{_CLAIMED_ID}  = $query_or_sid  }
}


sub _load_pluggables {
    my ($self) = @_;

    my %DEFAULT_FOR = (
                       driver     => "file",
                       serializer => "default",
                       id         => "md5",
                       );
    my %SUBDIR_FOR  = (
                       driver     => "Driver",
                       serializer => "Serialize",
                       id         => "ID",
                       );
    my $dsn = $self->{_DSN};
    foreach my $plug qw(driver serializer id) {
        my $mod_name = $dsn->{ $plug };
        if (not defined $mod_name) {
            $mod_name = $DEFAULT_FOR{ $plug };
        }
        if ($mod_name =~ /^(\w+)$/) {

            # Looks good.  Put it into the dsn hash
            $dsn->{ $plug } = $mod_name = $1;

            # Put together the actual module name to load
            my $prefix = join '::', (__PACKAGE__, $SUBDIR_FOR{ $plug }, q{});
            $mod_name = $prefix . $mod_name;

            ## See if we can load load it
            eval "require $mod_name";
            if ($@) {
                my $msg = $@;
                return $self->set_error("couldn't load $mod_name: " . $msg);
            }
        }
        else {
            # do something here about bad name for a pluggable
        }
    }
    return;
}

#line 947

*expires = \&expire;
my $prevent_warning = \&expires;
sub etime           { $_[0]->expire()  }
sub expire {
    my $self = shift;

    # no params, just return the expiration time.
    if (not @_) {
        return $self->{_DATA}->{_SESSION_ETIME};
    }
    # We have just a time
    elsif ( @_ == 1 ) {
        my $time = $_[0];
        # If 0 is passed, cancel expiration
        if ( defined $time && ($time =~ m/^\d$/) && ($time == 0) ) {
            $self->{_DATA}->{_SESSION_ETIME} = undef;
            $self->_set_status( STATUS_MODIFIED );
        }
        # set the expiration to this time
        else {
            $self->{_DATA}->{_SESSION_ETIME} = $self->_str2seconds( $time );
            $self->_set_status( STATUS_MODIFIED );
        }
    }
    # If we get this far, we expect expire($param,$time)
    # ( This would be a great use of a Perl6 multi sub! )
    else {
        my ($param, $time) = @_;
        if ( ($time =~ m/^\d$/) && ($time == 0) ) {
            delete $self->{_DATA}->{_SESSION_EXPIRE_LIST}->{ $param };
            $self->_set_status( STATUS_MODIFIED );
        } else {
            $self->{_DATA}->{_SESSION_EXPIRE_LIST}->{ $param } = $self->_str2seconds( $time );
            $self->_set_status( STATUS_MODIFIED );
        }
    }
    return 1;
}

# =head2 _str2seconds()
#
# my $secs = $self->_str2seconds('1d')
#
# Takes a CGI.pm-style time representation and returns an equivalent number
# of seconds.
#
# See the docs of expire() for more detail.
#
# =cut

sub _str2seconds {
    my $self = shift;
    my ($str) = @_;

    return unless defined $str;
    return $str if $str =~ m/^[-+]?\d+$/;

    my %_map = (
        s       => 1,
        m       => 60,
        h       => 3600,
        d       => 86400,
        w       => 604800,
        M       => 2592000,
        y       => 31536000
    );

    my ($koef, $d) = $str =~ m/^([+-]?\d+)([smhdwMy])$/;
    unless ( defined($koef) && defined($d) ) {
        die "_str2seconds(): couldn't parse '$str' into \$koef and \$d parts. Possible invalid syntax";
    }
    return $koef * $_map{ $d };
}


#line 1160

sub remote_addr {   return $_[0]->{_DATA}->{_SESSION_REMOTE_ADDR}   }

#line 1366

1;

