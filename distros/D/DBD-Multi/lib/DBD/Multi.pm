package DBD::Multi;
our $VERSION   = '1.01';
package DBD::Multi::dr;
our $VERSION   = '1.01';
package DBD::Multi::db;
our $VERSION   = '1.01';
package DBD::Multi::st;
our $VERSION   = '1.01';
package DBD::Multi::Handler;
our $VERSION   = '1.01';

package DBD::Multi;
use strict;

use DBI;
DBI->setup_driver('DBD::Multi');

use vars qw[$err $errstr $sqlstate $drh];

$err       = 0;        # DBI::err
$errstr    = "";       # DBI::errstr
$sqlstate  = "";       # DBI::state
$drh       = undef;

sub driver {
    return $drh if $drh;
    my($class, $attr) = @_;
    $class .= '::dr';

    $drh = DBI::_new_drh($class, {
        Name        => 'Multi',
        Version     => $VERSION,
        Err         => \$DBD::Multi::err,
        Errstr      => \$DBD::Multi::errstr,
        State       => \$DBD::Multi::sqlstate,
        Attribution => 'DBD::Multi, pair Networks Inc.',
    });
    DBD::Multi::db->install_method('multi_do_all');
    return $drh;
}

#######################################################################
package DBD::Multi::dr;
use strict;

$DBD::Multi::dr::imp_data_size = 0;
use DBD::File;

sub DESTROY { shift->STORE(Active => 0) }

sub connect {
    my($drh, $dbname, $user, $auth, $attr) = @_;
    my $dbh = DBI::_new_dbh(
      $drh => {
               Name         => $dbname,
               USER         => $user,
               CURRENT_USER => $user,
              },
    );
    my @dsns =   $attr->{dsns} && ref($attr->{dsns}) eq 'ARRAY'
               ? @{$attr->{dsns}}
               : ();

    if ( $dbname =~ /dsn=(.*)/ ) {
        push @dsns, ( -1, [$1, $user, $auth] );
    }

    my $handler = DBD::Multi::Handler->new({
        dsources => [ @dsns ],
    });
    $handler->failed_max($attr->{failed_max})
      if exists $attr->{failed_max};
    $handler->failed_expire($attr->{failed_expire})
      if exists $attr->{failed_expire};

    $dbh->STORE(_handler => $handler);
    $dbh->STORE(handler => $handler); # temporary
    $drh->{_handler} = $handler;
    $dbh->STORE(Active => 1);
    return $dbh;
}

sub data_sources { shift->FETCH('_handler')->all_sources }

#######################################################################
package DBD::Multi::db;
use strict;

$DBD::Multi::db::imp_data_size = 0;

sub prepare {
    my ($dbh, $statement, @attribs) = @_;

    # create a 'blank' sth
    my ($outer, $sth) = DBI::_new_sth($dbh, { Statement => $statement });

    my $handler = $dbh->FETCH('_handler');
    $sth->STORE(_handler => $handler);

    my $_dbh = $handler->dbh;
    my $_sth;
    until ( $_sth ) {
        $_sth = $_dbh->prepare($statement, @attribs);
        unless ( $_sth ) {
            $handler->dbh_failed;
            $_dbh = $handler->dbh;
        }
    }

    $sth->STORE(NUM_OF_PARAMS => $_sth->FETCH('NUM_OF_PARAMS'));
    $sth->STORE(_dbh => $_dbh);
    $sth->STORE(_sth => $_sth);

    return $outer;
}

sub multi_do_all {
    my $dbh = shift;
    my $handler = $dbh->FETCH('_handler');
    return $handler->multi_do_all( @_ );
}

sub disconnect {
    my ($dbh) = @_;
    $dbh->STORE(Active => 0);
    1;
}

sub commit {
    my ($dbh) = @_;
    if ( $dbh->FETCH('Active') ) {
        return $dbh->FETCH('_dbh')->commit if $dbh->FETCH('_dbh');
    }
    return;
}

sub rollback {
    my ($dbh) = @_;
    if ( $dbh->FETCH('Active') ) {
        return $dbh->FETCH('_dbh')->rollback if $dbh->FETCH('_dbh');
    }
    return;
}

sub get_info {
    my($dbh, $info_type) = @_;

    # return info from current connection
    my $handler = $dbh->FETCH('_handler');
    my $_dbh = $handler->dbh;
    return $_dbh->get_info($info_type);
}

sub STORE {
    my ($self, $attr, $val) = @_;
    $self->{$attr} = $val;
}

sub DESTROY { shift->disconnect }

#######################################################################
package DBD::Multi::st;
use strict;

$DBD::Multi::st::imp_data_size = 0;

use vars qw[@METHODS @FIELDS];
@METHODS = qw[
    bind_param
    bind_param_inout
    bind_param_array
    execute_array
    execute_for_fetch
    fetch
    fetchrow_arrayref
    fetchrow_array
    fetchrow_hashref
    fetchall_arrayref
    fetchall_hashref
    bind_col
    bind_columns
    dump_results
];

@FIELDS = qw[
    NUM_OF_FIELDS
    CursorName
    ParamValues
    RowsInCache
];

sub execute {
    my $sth  = shift;
    my $_sth = $sth->FETCH('_sth');
    my $params =   @_
                 ? $sth->{f_params} = [ @_ ]
                 : $sth->{f_params};

    $sth->finish if $sth->FETCH('Active');
    $sth->{Active} = 1;
    my $rc = $_sth->execute(@{$params});

    for my $field ( @FIELDS ) {
        my $value = $_sth->FETCH($field);
        $sth->STORE($field => $value)
          unless    ! defined $value
                 || defined $sth->FETCH($field);
    }

    return $rc;
}

sub FETCH {
    my ($sth, $attrib) = @_;
    $sth->{'_sth'}->FETCH($attrib) || $sth->{$attrib};
}

sub STORE {
    my ($self, $attr, $val) = @_;
    $self->{$attr} = $val;
}

sub rows { shift->FETCH('_sth')->rows }

sub finish {
    my ($sth) = @_;
    $sth->STORE(Active => 0);
    return $sth->FETCH('_sth')->finish;
}

foreach my $method ( @METHODS ) {
    no strict;
    *{$method} = sub { shift->FETCH('_sth')->$method(@_) };
}

#######################################################################
package DBD::Multi::Handler;
use strict;

use base qw[Class::Accessor::Fast];
use Sys::SigAction qw(timeout_call);
use List::Util qw(shuffle);

=begin ImplementationNotes

dsources - This thing changes from an arrayref to a hashref during construction.  :(

  Initially, when data is passed in during construction, it's an arrayref
  containing the 'dsns' param from the user's connect() call.

  Later, when _configure_dsources gets called, it turns into a multi-dimension
  hashref:

       $dsources->{$pri}->{$dsource_id} = 1;

  The first key is the priority number, the second key is the data source index
  number.  The value is always just a true value.

nextid - A counter.  Stores the index number of the next data source to be added.

all_dsources - A hashref.  Maps index number to the connect data.

current_dsource - The most recent chosen datasource index number.

used - A hashref.  Keys are index numbers.  Values are true when the datasource
has been previously assigned and we want to prefer other datasources of the
same priority (for round-robin load distribution).

failed - A hashref.   Keys are index numbers.   Values are counters indicating
how many times the data source has failed.

failed_last - A hashref.   Keys are index number.   Values are unix timestamp
indicating the most recent time a data source failed.

failed_max - A scalar value.   Number of times a datasource may fail before we
stop trying it.

failed_expire - A scalar value.   Number of seconds since we stopped trying a
datasource before we'll try it again.

timeout - A scalar value.   Number of seconds we try to connect to a datasource
before giving up.

=end ImplementationNotes

=cut

__PACKAGE__->mk_accessors(qw[
    dsources
    nextid
    all_dsources
    current_dsource
    used
    failed
    failed_last
    failed_max
    failed_expire
    timeout
]);

sub new {
    my ($class, $args) = @_;
    my $self     = $class->SUPER::new($args);
    $self->nextid(0) unless defined $self->nextid;
    $self->all_dsources({});
    $self->used({});
    $self->failed({});
    $self->failed_last({});
    $self->failed_max(3) unless defined $self->failed_max;
    $self->failed_expire(60*5) unless defined $self->failed_expire;
    $self->timeout( 5 ) unless defined $self->timeout;
    $self->_configure_dsources;
    return $self;
}

sub all_sources {
    my ($self) = @_;
    return values %{$self->all_dsources};
}

sub add_to_pri {
    my ($self, $pri, $dsource) = @_;
    my $dsource_id = $self->nextid;
    my $dsources   = $self->dsources;
    my $all        = $self->all_dsources;

    $all->{$dsource_id} = $dsource;
    $dsources->{$pri}->{$dsource_id} = 1;

    $self->nextid($dsource_id + 1);
}

sub dbh {
    my $self = shift;
    my $dbh = $self->_connect_dsource; 
    return $dbh if $dbh;
    $self->dbh_failed;
    $self->dbh;
}

sub dbh_failed {
    my ($self) = @_;

    my $current_dsource = $self->current_dsource;
    $self->failed->{$current_dsource}++;
    $self->failed_last->{$current_dsource} = time;
}

sub _purge_old_failures {
    my ($self) = @_;
    my $now = time;
    my @all = keys %{$self->all_dsources};
    
    foreach my $dsource ( @all ) {
        next unless $self->failed->{$dsource};
        if ( ($now - $self->failed_last->{$dsource}) > $self->failed_expire ) {
            delete $self->failed->{$dsource};
            delete $self->failed_last->{$dsource};
        }
    }
}

sub _pick_dsource {
    my ($self) = @_;
    $self->_purge_old_failures;
    my $dsources = $self->dsources;
    my @pri      = sort { $a <=> $b } keys %{$dsources};

    foreach my $pri ( @pri ) {
        my $dsource = $self->_pick_pri_dsource($dsources->{$pri});
        if ( defined $dsource ) {
            $self->current_dsource($dsource);
            return;
        }
    }

    $self->used({});
    return $self->_pick_dsource
      if (grep {$self->failed->{$_} >= $self->failed_max} keys(%{$self->failed})) < keys(%{$self->all_dsources});
    die("All data sources failed!");
}

### _pick_pri_dsource
#  Given a list of data sources, all of the same priority, choose one to use.
#  Passed in a structure like this:
#  _pick_pri_dsource( $self, { 3 => 1, 4 => 1, 5 => 1 } )
#  Where the keys 3,4,5 are dsource id's, and the values are always true.
sub _pick_pri_dsource {
    my ($self, $dsources) = @_;
    my @dsources = sort { $a <=> $b } keys %{$dsources};  # Indexes of data sources to try.
    my @used     = grep { exists $self->used->{$_} } @dsources; # List of data sources already used. 
    my @failed   = grep { exists($self->failed->{$_}) && $self->failed->{$_} >= $self->failed_max } @dsources;  # List of data sources that won't be tried.

    # We've used them all and they all failed. Escallate.
    return if @used == @dsources && @failed == @dsources;
    
    # We've used them all but some are good. Purge and reuse.
    delete @{$self->used}{@dsources} if @used == @dsources;

    foreach my $dsource ( shuffle @dsources ) {
        next if    $self->failed->{$dsource}
                && $self->failed->{$dsource} >= $self->failed_max;
        next if $self->used->{$dsource};

        $self->used->{$dsource} = 1;
        return $dsource;
    }
    return;
}

sub _configure_dsources {
    my ($self) = @_;
    my $dsources = $self->dsources;
    $self->dsources({});

    while ( my $pri = shift @{$dsources} ) {
        my $dsource = shift @{$dsources} or last;
        $self->add_to_pri($pri => $dsource);
    }
}

sub _connect_dsource {
    my ($self, $dsource) = @_;
    unless ( $dsource ) {
        $self->_pick_dsource;
        $dsource = $self->all_dsources->{$self->current_dsource};
    }

    # Support ready-made handles
    return $dsource if UNIVERSAL::isa($dsource, 'DBI::db');

    # Support code-refs which return handles
    if (ref $dsource eq 'CODE') {
        my $handle = $dsource->();
        return $handle if UNIVERSAL::isa($handle, 'DBI::db');
        return undef; # Connect by coderef failed.
    }

    my $dbh;
    local $ENV{DBI_AUTOPROXY};
    if (timeout_call( $self->timeout, sub { $dbh = DBI->connect_cached(@{$dsource}) } )) {
        #warn "Timeout[", $self->current_dsource, "] at ", time, "\n";
    }
    return $dbh;
}

sub connect_dsource {
    my ($self, $dsource) = @_;
    $self->_connect_dsource($dsource);
}

sub multi_do_all {
    my ($self, $code) = @_;

    my @all = values %{$self->all_dsources};

    foreach my $source ( @all ) {
        my $dbh = $self->connect_dsource($source);
        next unless $dbh;
        if ( $dbh->{handler} ) {
            $dbh->{handler}->multi_do_all($code, $source);
            next;
        }
        $code->($dbh);
    }
}

1;
__END__

=head1 NAME

DBD::Multi - Manage Multiple Data Sources with Failover and Load Balancing

=head1 SYNOPSIS

  use DBI;

  my $other_dbh = DBI->connect(...);

  my $dbh = DBI->connect( 'dbi:Multi:', undef, undef, {
      dsns => [ # in priority order
          10 => [ 'dbi:SQLite:read_one.db', '', '' ],
          10 => [ 'dbi:SQLite:read_two.db', '', '' ],
          20 => [ 'dbi:SQLite:master.db',   '', '' ],
          30 => $other_dbh,
          40 => sub {  DBI->connect },
      ],
      # optional
      failed_max    => 1,     # short credibility
      failed_expire => 60*60, # long memory
      timeout       => 10,    # time out connection attempts after 10 seconds.
  });

  $dbh->prepare(...);  # Works like any other DBI handle.


  $dbh->multi_do_all(  # Loops through every single DB handle.
    sub {
        my $dbh = shift;
        ...
    } );

=head1 DESCRIPTION

This software manages multiple database connections for failovers and also
simple load balancing.  It acts as a proxy between your code and your database
connections, transparently choosing a connection for each query, based on your
preferences and present availability of the DB server.

This module is intended for read-only operations (where some other application
is being used to handle replication).

This software does not prevent write operations from being executed.  This is
left up to the user. See L<SUGGESTED USES> below for ideas.

The interface is nearly the same as other DBI drivers except that it allows you
to specify multiple connections for a single handle.

=head1 CONFIGURING CONNECTIONS

=head2 Configuring DSNs

Specify an attribute to the C<connect()> constructor, C<dsns>. This is a list
of DSNs to configure. The configuration is given in pairs. First comes the
priority of the DSN. Second is the DSN.

The priorities specify which connections should be used first (lowest to
highest).  As long as the lowest priority connection is responding, the higher
priority connections will never be used.  If multiple connections have the same
priority, then one connection will be chosen randomly for each operation.  Note
that the random DB is chosen when the statement is prepared.   Therefore
executing multiple queries on the same prepared statement handle will always
run on the same connection.

The second parameter can a DBI object, a code ref which returns a DBI object,
or a list of parameters to pass to the DBI C<connect()> instructor.   If a set
of parameters or a code ref is given, then DBD::Multi will be able to attempt
re-connect in the event that the connection is lost.   If a DBI object is used,
the DBD::Multi will give up permanently once that connection is lost.

These connections are lazy loaded, meaning they aren't made until they are
actually used. 

=head2 Configuring Failures

By default, after a data source fails three times, it will not be tried again
for 5 minutes.  After that period, the data source will be tried again for
future requests until it reaches its three failure limit (the cycle repeats
forever).

To change the maximum number of failures allowed before a data source is
deemed failed, set the C<failed_max> parameter. To change the amount of
time we remember a data source as being failed, set the C<failed_expire>
parameter in seconds.

=head2 Timing out connections.

By default, if you attempt to connect to an IP that isn't answering, DBI will
hang for a very long period of time.   This behavior is not desirable in a
multi database setup.   Instead, it is better to give up on slow connections
and move on to other databases quickly.

DBD::Multi will give up on connection attempts after 5 seconds and then try
another connection.   You may set the C<timeout> parameter to change the
timeout time, or set it to 0 to disable the timeout feature completely.

=head1 EXTRA METHODS

=head2 multi_do_all

Loops through every database handle, executing an arbitrary coderef passing the
current database handle as the first parameter and the original connection
parameters as the second parameter.

If a database is unreachable, multi_do_all will skip over it.


    use Data::Dumper;
    my $expected_value = ...;
    $dbh->multi_do_all(
        sub {
            my $dbh = shift;
            my $source = shift;
            my($value) = $dbh->selectrow_array("SELECT ...");
            unless ( $value eq $expected_value ) {
                die "Unexpected value, $value found. (Expected $expected_value).  Data Source:\n", Dumper( $source );
            }
        } );

=head1 SUGGESTED USES

Here are some ideas on how to use this module effectively and safely. 

It is important to remember that C<DBD::Multi> is not intended for read-write
operations.  One suggestion to prevent accidental write operations is to make
sure that the user you are connecting to the databases with has privileges
sufficiently restricted to prevent updates. 

Read-write operations should happen through a separate database handle that
will somehow trigger replication to all of your databases.  For example, your
read-write handle might be connected to the master server that replicates
itself to all of the subordinate servers.

Read-only database calls within your application would be updated to explicitly
use the read-only (DBD::Multi) handle. It is not necessary to find every single
call that can be load balanced, since they can safely be sent through the
read/write handle as well.

=head1 TODO

There really isn't much of a TODO list for this module at this time.  Feel free
to submit a bug report to L<github|https://github.com/dwright/DBD-Multi/issues>
if you think there is a feature missing.

Although there is some code intended for read/write operations, this should be
considered not supported and not actively developed at this time.  The actual
read/write code remains un-documented because in the event that I ever do
decide to work on supporting read/write operations, the API is not guaranteed
to stay the same.  The focus of this module is presently limited to read-only
operations.

=head1 TESTING

DBD::Multi has it's own suite of regression tests.   But, suppose you want to
verify that you can slip DBD::Multi into whatever application you already have
written without breaking anything.

Thanks to a feature of DBI, you can regression test DBD::Multi using any
existing tests that already use DBI without having to update any of your code.
Simply set the environment variable DBI_AUTOPROXY to 'dbi:Multi:' and then run
your tests.  DBD::Multi should act as a silent pipe between your application
and whatever database driver you were previously using.  This will help you
verify that you aren't currently using some feature of the DBI that breaks
DBD::Multi (If you are, please do me a favor and submit a bug report so I can
fix it).

=head1 SEE ALSO

There are other modules that have similar, but different objectives.  Depending
on your specific needs these may be more or less suitable for your task:

=over

=item L<CGI::Application::Plugin::DBH> 

A plugin for the L<CGI::Application> framework which makes it easy to support
two database handles, and also supports lazy-loading.

=item L<DBD::Multiplex>

The original inspiration for this module.  It doesn't support as many
connection configurations options at this module.   It does try to support
write options in a single master, mutliple slave configuration.   It does this
by parsing your SQL and trying to decide if you were doing a read or write
operation.

=item L<DBIx::HA>

Written after this module.  Built for high availability rather than load
balancing.   It purposely ignores some DBI features in favor of producing the
fastest results for the most common operations.  It doesn't utilize the
standard DBI->connect() API, which means it will not work as a drop-in auto
proxy.

=back

L<DBI>, L<perl> - You should probably already know about these before using
this module.

=head1 AUTHOR

Initially written by Casey West and Dan Wright for pair Networks, Inc.
(www.pair.com)

Maintained by Dan Wright.  <F<DWRIGHT@CPAN.ORG>>.

=cut

