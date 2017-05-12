#!/usr/bin/perl
#
# Don't be affraid to aggressively refactor this.
# It is a first start and will no doubt need an actual design as it gets bigger!
#
# vim: softtabstop=4 tabstop=4 shiftwidth=4 ft=perl smarttab
#

use strict;
use warnings;

# so i can hack on the server and on my local machine
BEGIN {
    if (-d '/root/dean/lib') {
        eval q|use lib '/root/dean/lib'|;
    }
}

use lib '/usr/lib/nagios/perl'; # OIE::Nagios

use v5.10; # i like 'say'
use BZ::Client;
use BZ::Client::Bug;
use BZ::Client::Bug::Comment;
use BZ::Client::Bugzilla;
use Path::Tiny;
use Try::Tiny; # nb this is slow. see http://perladvent.org/2016/2016-12-12.html
use Sys::Hostname qw/ hostname /;
use Log::Log4perl;
use DateTime;
use Nagios::Cmd; # replace nagios_command
use Data::Dumper;
$Data::Dumper::Indent = 0;
$Data::Dumper::Sortkeys = 0;

# use 0 when debugging, 1 will delete the notice files from spool
my $delete = 1;
# use 1 when debugging to close *everything* after opening
my $closeplease = 0;

my $closetime = 24 * 7; #hours
my $acktime   = 24 * 1; #hours
my $stirtime  = 24 * 2; #hours

# alias template for sprintf
#my $aliastmpl = 'TESTaaaSERVICEPROBLEMID%d'; # use something for development
my $aliastmpl = 'SERVICEPROBLEMID%d';
my $nagiosuri = 'http://nagios.domain.com/nagios';

if (hostname() =~ m/lab/) {
    $aliastmpl = 'LAB' . $aliastmpl; # FIXME get this from a config file
    $nagiosuri = 'http://nagios.lab.domain.com/nagios';
}

# use this for debugging too
#my %team = (
#    product   => 'Internet Services Engineering',
#    component => 'AOP',
#    version   => 'unspecified',
#    op_sys    => 'other',
#    platform  => 'Other',
#    priority  => 'P1',
#    status    => 'NEW',
#);

# team details and other bug defaults
my %team = ( # FIXME get this from a config file
    product   => 'IPSP',
    component => 'Hardware',
    version   => 'Production',
    op_sys    => 'other',
    platform  => 'Other',
    status    => 'NEW',
    keywords  => ['nagiosgenerated'],
);
$team{keywords} = ['nagiosgeneratedlab']
    if hostname() =~ m/lab/;

# list of files
my $spool = '/var/spool/nagios/notify-by-bugzilla';

# nagios pipe
my $nagiospipe = '/usr/local/nagios/var/rw/cmd.pipe';
my $cmd = Nagios::Cmd->new( $nagiospipe );

# fire up logging
Log::Log4perl->init('talktobugzilla-log4perl.conf');
my $log = Log::Log4perl->get_logger('N2B');

$log->info('BEGIN');
$log->info("Spool: $spool");
$log->info("AliasTmpl : $aliastmpl");
$log->info("NagiosUri : $nagiosuri");
$log->info("NagiosPipe : $nagiospipe");

# talk to bugzilla
my $client = BZ::Client->new(
    url      => 'https://bugzilla.domain.com',
    api_key => 'XXXXXXXXX PUT YOUR KEY HERE XXXXXXXX', #dean

    connect => { verify_SSL => 1 },

#    logDirectory => '/tmp/bz', # dumps requests and responses
);

try {
    $client->login();
}
catch {
    $log->logdie( 'Failed at login().', Dumper( $_ ) );
};

$log->logdie( 'Logged in to bugzilla, but not actually logged in?' )
    unless $client->is_logged_in();

# check the connection and health of the server by asking for version
try {
    my $version = BZ::Client::Bugzilla->version( $client );
    $log->info("Server version is $version");
}
catch {
    $log->logdie('Failed to retrieve server version? ' . Dumper($_))
};

# Wrapper of Nagios::Cmd
sub nagios_command {
    my $line = shift or return;
    return $cmd->nagios_cmd(sprintf '[%s] %s', time(), $line);
}

# Generate the bug alias
sub bugalias {
    return sprintf( $aliastmpl, $_[0] )
}

# Bring the key=value lines in to our hash
sub decode {
    my @content = @_;
    return unless @content;
    return
      map { my ( $foo, $bar ) = $_ =~ m/^([^=]+)=([^=]*)/; +( $foo => $bar ) }
      @content
}

my @pleaseclose;

{

# keep track of new bugs so we can tag them
my @newbugs;

# keep track of updated bugs so we can tag them
my @updatedbugs;

# tags are private to the user, so they arent useful
sub tag_bugs {

    unless (@newbugs or @updatedbugs) {
        $log->debug('No bugs to tag');
        return 1
    }

    try {
        BZ::Client::Bug->update_tags( $client,
                { ids => [ @newbugs, @updatedbugs ], tags => { add => [ 'nagiosgenerated' ] } } );
    }
    catch {
        $log->warn('Failed to tag bugs, error: ' . Dumper( $_ ) );
    };

    $log->info("Tagged new bugs @newbugs with 'nagiosgenerated'") if @newbugs;
    $log->info("Tagged bugs @updatedbugs with 'nagiosgenerated'") if @updatedbugs;

    return 1

}

# adds a comment in nagios
sub nagios_comment {
    my ($host, $service, $bugid) = @_;

    $log->info( 'Telling nagios about new bug ' . $bugid );

    #  ADD_SVC_COMMENT;<host_name>;<service_description>;<persistent>;<author>;<comment>
    nagios_command(
        sprintf('ADD_SVC_COMMENT;%s;%s;1;bugzilla;%s',
            $host, $service, 'Auto-Bz http://bugzilla.domain.com/show_bug.cgi?id='.$bugid )
    );

    $log->info( 'Nagios was told about new bug ' . $bugid );

    return 1

}

# problems we have already observed
my %problems;

sub create_bug {

    my $f = shift;
    my $alias = shift;
    my $params = shift;

    $log->info("Lets create a bug for $alias");

    $log->debug('Bug params: ' . Dumper( $params )) if $log->is_debug;

    my $summary = sprintf q|Server: '%s', Fault: '%s'|,
      @{$params}{qw( HOSTNAME SERVICEDESC )};

    my $severity = 'major';
    my $priority = 'P2';
    if ( $params->{SERVICESTATE} eq 'CRITICAL' ) {
        $severity = 'critical';
        $priority = 'P1';
    };

    my $description = sprintf(
        <<'EOF', $0, hostname(), $nagiosuri, @{$params}{qw( HOSTNAME SERVICEDESC SERVICESTATE SERVICEOUTPUT )}, join( "\n", map { "$_=$params->{$_}" } sort keys %$params ) );

A fault has been detected by Nagios. Your urgent action is required.

Alert Details:

Hostname: %4$s
Service: %5$s
Status: %6$s
Information: %7$s

Status Details for this Host:
%3$s/cgi-bin/status.cgi?host=%4$s

Note:

Whilst this Bz remains open (or is reopened), this automation
will provide additional updates to the fault status as Nagios
detects changes.

If this Bz is marked resolved or closed (including resolved as a
duplicate), then this automation will provide no additional updates
and make no further changes.

Raw details provided by Nagios:

----BEGIN RAW----
%8$s
----END RAW----

This bug was automatically generated by %1$s running on %2$s

EOF

    my %bug = (

        %team,

        summary     => $summary,
        severity    => $severity,
        priority    => $priority,
        alias       => $alias,
        description => $description,

        # assigned_to, ommit so it goes to default
        # cc, we can cc people

    );

    $log->debug('Bug will contain: ' . Dumper( \%bug )) if $log->is_debug;

    my $newbug = try {
        return BZ::Client::Bug->create( $client, \%bug );
    }
    catch {
        $log->logdie('Failed to create new bug, error: ' . Dumper( $_ ) );
    };

    $log->info("Bug for $alias is $newbug");

    my $get = try {
        return BZ::Client::Bug->get( $client, { ids => [ $newbug ] } );
    }
    catch {
        $log->logdie('Failed to retrieve newly created bug, with error: ' . Dumper( $_ ));
    };

    push @newbugs, $newbug;

    $problems{ $alias } = $get->[0];
    try { if ($delete) { $log->debug('Removing file: ' .$f->basename); $f->remove() }}
    catch { $log->warn(sprintf 'Failed to delete %s because: %s', $f->basename, $_) };

    # telling nagios
    nagios_comment( @{$params}{qw( HOSTNAME SERVICEDESC )}, $newbug );

    return 1

}

sub update_bug {

    my $f = shift;
    my $bug = shift;
    my $params = shift;

    # ignore closed bugs
    unless ( $bug->is_open() ) {

        $log->info('Bug is closed, not updating');

        try { if ($delete) { $log->debug('Removing file: ' .$f->basename); $f->remove() }}
        catch { $log->warn(sprintf 'Failed to delete %s because: %s', $f->basename, $_) };

        return
    }

    my $lastalias = $bug->alias
        or $log->logdie(sprintf('Bug %d has no alias so it cannot be updated, how did we even get here?', $bug->id()));
    my $newalias = bugalias($params->{SERVICEPROBLEMID});

    $log->info('Lets update a bug for ' . $bug->alias);
    $log->debug('Bug params: ' . Dumper( $params )) if $log->is_debug;

    my $comment = 'Nagios has updated this alert';

    # aliase handling
    if ($lastalias ne $newalias) {
        $log->info("Changing alias from $lastalias to $newalias");
        $comment .= "\n\n". sprintf('Changed service problem ID: %d -> %d',
                               $params->{LASTSERVICEPROBLEMID}, $params->{SERVICEPROBLEMID});
    }

# FIXME
#    my $summary = sprintf q|Server: '%s', Fault: '%s'|,
#      @{$params}{qw( HOSTNAME SERVICEDESC )};

    my $severity = 'major';
    my $priority = 'P2';
    if ( $params->{SERVICESTATE} eq 'CRITICAL' ) {
        $severity = 'critical';
        $priority = 'P1';
    };

    # highlight the change in severity
    if ($severity ne $bug->severity() ) {
        if ($severity eq 'critical') { # upgraded to 'critical'
            $comment .= "\nSeverity upgraded to: $severity"
        }
    }

    # highlight the change in priority
    if ($priority ne $bug->priority() ) {
        if ($priority eq 'P1') { # upgraded to 'P1'
            $comment .= "\nPriority now: $severity"
        }
    }

    $comment .= sprintf(
        <<'EOF', $0, hostname(), join( "\n", map { "$_=$params->{$_}" } sort keys %$params ) );

Raw details provided by Nagios:

----BEGIN RAW----
%3$s
----END RAW----

UPDATEBUG: By %1$s running on %2$s
EOF

    my %bug = (

        #summary => $summary,
        severity => $severity,
        priority => $priority,
        ids      => $lastalias,
        alias    => { add => [ $newalias ], },
        comment  => { body => $comment },

        keywords => { add => $team{keywords}, },

        # assigned_to, ommit so it goes to default
        # cc, we can cc people

    );

    $log->debug('Bug update: ' . Dumper( \%bug )) if $log->is_debug;

    my $updatedbugs = try {
        return BZ::Client::Bug->update( $client, \%bug );
    }
    catch {
        $log->logdie('Failed to update bug, error: ' . Dumper( $_ ) );
    };

    $log->info('Updated: ' . scalar @$updatedbugs);

    # FIXME, this assumes just one update. which should be correct but you never know
    my $get = try {
        return BZ::Client::Bug->get( $client, { ids => [ $updatedbugs->[0]->{id} ] } );
    }
    catch {
        $log->logdie('Failed to retrieve just updated bug, with error: ' . Dumper( $_ ));
    };

    $problems{ $newalias } = $get->[0];
    $problems{ $lastalias } = $get->[0] if $lastalias ne $newalias;

    push @updatedbugs, $updatedbugs->[0]->{id};

    try { if ($delete) { $log->debug('Removing file: ' .$f->basename); $f->remove() }}
    catch { $log->warn(sprintf 'Failed to delete %s because: %s', $f->basename, $_) };

    return 1

}

### Handle problem notices ###
sub handle_problems {

    $log->info( 'Handling problems' );

    # handle problems, sort by mtime so we do the oldest first
    my @list = try { # Catch exceptions from path()
        return
            sort { $a->stat->mtime <=> $b->stat->mtime }
            grep { $_->stat->size }
            grep { $_->is_file }
            grep { $_ =~ m/_PROBLEM_/ }
            path($spool)->children();
    }
    catch {
        $log->logdie( "Something bad happened listing $spool:" . $_ );
    };

    if ($log->is_debug()) {
        if (@list) {
            $log->debug("Found @list")
        }
        else {
            $log->debug('Found (none)')
        }
    }

    FILELOOP:
    for my $f (@list) {

        # load up
        my %params = decode( $f->lines_raw({ chomp => 1 }) );
        unless (keys %params) {
            $log->info(sprintf 'File %s is emtpy? skipping it, but not deleting', $f->basename );
            next FILELOOP
        }
        $log->debug(sprintf 'File %s contained: %s', $f->basename, Dumper( \%params ))
            if $log->is_debug();

        # our unique id is based upon nagios unique id
        my $alias = bugalias( $params{SERVICEPROBLEMID} );
        $log->debug("The alias for $params{SERVICEPROBLEMID} is $alias");

        # FIXME, we should update bugs!
        # short circuit if we have seen this bug before
        if ( $problems{ $alias } ) {
            $log->info( "Skipping over already handled $params{SERVICEPROBLEMID}" );
            try { if ($delete) { $log->debug('Removing file: ' .$f->basename); $f->remove() }}
            catch { $log->warn(sprintf 'Failed to delete %s because: %s', $f->basename, $_) };
            next FILELOOP
        }

        $log->info("Searching for $alias on server");

        # does the bug already exist?
        my $search = try {
            return BZ::Client::Bug->search( $client, { alias => $alias } );
        }
        catch {
             $log->logdie(sprintf 'Something bad happened searching for %s via alias %s, error: %s',
                $alias , $params{SERVICEPROBLEMID} , Dumper( $_ ) );
        };

        ## not new, so skipping it
        if ( ref $search eq 'ARRAY' and @$search ) {
            $log->info( "Found and skipping $params{SERVICEPROBLEMID}" );
            $problems{ $alias } = $search->[0]; # hold on to this for later
            try { if ($delete) { $log->debug('Removing file: ' .$f->basename); $f->remove() }}
            catch { $log->warn(sprintf 'Failed to delete %s because: %s', $f->basename, $_) };
            next FILELOOP
        }

        # if 0, we came from OK state so no bug exists. otherwise we found the existing bug
        if ($params{LASTSERVICEPROBLEMID}) {

            my $lastalias = bugalias( $params{LASTSERVICEPROBLEMID} );
            $log->debug("The last alias for $params{LASTSERVICEPROBLEMID} is $lastalias");

            # short circuit if we have seen this bug before
            if ($problems{ $lastalias }) {
                update_bug($f, $problems{ $lastalias }, \%params);
                push @pleaseclose, $lastalias;
                next FILELOOP
            }

            $log->info("Searching for $lastalias on server");

            # does the bug already exist?
            my $search = try {
                return BZ::Client::Bug->search( $client, { alias => $lastalias } );
            }
            catch {
                 $log->logdie(sprintf 'Something bad happened searching for %s via alias %s, error: %s',
                    $lastalias , $params{SERVICEPROBLEMID} , Dumper( $_ ) );
            };

            if ( ref $search eq 'ARRAY' and @$search ) {
                $log->info( "Found and updating $params{LASTSERVICEPROBLEMID}" );
                $problems{ $lastalias } = $search->[0]; # hold on to this for later
                update_bug($f, $problems{ $lastalias }, \%params);
                push @pleaseclose, $lastalias;
                next FILELOOP
            }

            $log->info("Unable to locate last event $lastalias, processing current event id")

        }

        # skip time'd out plugins if we are going from OK to UNKNOWN
        if ($params{SERVICEOUTPUT} =~ m/^UNKNOWN: Plugin failed: Timeout executing plugin/) {

            $log->info( 'Skipping time\'d out plugin notice' );
            try { if ($delete) { $log->debug('Removing file: ' .$f->basename); $f->remove() }}
            catch { $log->warn(sprintf 'Failed to delete %s because: %s', $f->basename, $_) };
            next FILELOOP

        }

        # create the bug
        create_bug( $f, $alias, \%params );
        push @pleaseclose, $alias;

    } # end for

    $log->info( 'Finished handling problems' );

} # end handle_problems

}

{

# recovery we have already observed
my %recovery;

sub close_bug {

    my $f = shift;
    my $bug = shift;
    my $params = shift;

    $log->info('Going to close ' . $bug->alias());

    # We only care if its still open
    unless ( $bug->is_open() ) {
        $log->info( 'Bug is already closed. Next' );
        try { if ($delete) { $log->debug('Removing file: ' .$f->basename); $f->remove() }}
        catch { $log->warn(sprintf 'Failed to delete %s because: %s', $f->basename, $_) };
        return 1;
    }

    $log->debug('Close params: ' . Dumper( $params )) if $log->is_debug;

        my $comment = sprintf(
            <<'EOF', $0, hostname(), @{$params}{qw( SERVICESTATE SERVICEOUTPUT )}, join( "\n", map { "$_=$params->{$_}" } sort keys %$params ) );

This fault has cleared in Nagios.

New Details:

Status: %3$s
Information: %4$s

Changing Status to: RESOLVED
...with Resolution: FIXED

Your next steps:

 * Check to ensure you agree
 * Then, set this bug's Status to VERIFIED
 * Or, set to Status to REOPENED
 * Then, comment on your findings
 * Then, take further actions to resolve

No further changes to this bug will be made by this automation.

Raw details provided by Nagios:

----BEGIN RAW----
%5$s
----END RAW----

This action taken automatically by %1$s running on %2$s

EOF

        my %update = (
            ids        => [ $bug->id() ],
            comment    => { comment => $comment, },
            status     => 'RESOLVED',
            resolution => 'FIXED',
        );

        $log->debug('Updating bug with: ' . Dumper( \%update )) if $log->is_debug;

        try {
            my $done =
                BZ::Client::Bug->update( $client, \%update );
        }
        catch {
            $log->logdie(sprintf 'Failed to update %s via alias %s, error: %s',
                    $bug->id(), $bug->alias(), Dumper( $_ ));
        };

        try { if ($delete) { $log->debug('Removing file: ' .$f->basename); $f->remove() }}
        catch { $log->warn(sprintf 'Failed to delete %s because: %s', $f->basename, $_) };

        return 1

}

### Handle recovery notices ###
sub handle_recovery {

    $log->info( 'Handling recoveries' );

    # handle recovery, sort by mtime so we do the oldest first
    my @list = try { # Catch exceptions from path()
        return
            sort { $a->stat->mtime <=> $b->stat->mtime }
            grep { $_->stat->size }
            grep { $_->is_file }
            grep { $_ =~ m/_RECOVERY_/ }
            path($spool)->children();
    }
    catch {
        $log->logdie( "Something bad happened listing $spool:" . $_ );
    };

    if ($log->is_debug()) {
        if (@list) {
            $log->debug("Found @list")
        }
        else {
            $log->debug('Found (none)')
        }
    }

    for my $f (@list) {

        # load up
        my %params = decode( $f->lines_raw({ chomp => 1 }) );
        $log->debug(sprintf 'File %s contained: %s', $f->basename, Dumper( \%params ))
            if $log->is_debug();

        # short circuit if we have seen this bug before
        #    if ( $recovery{ $params{SERVICEPROBLEMID} } ) {
        #        say "Skipping $params{SERVICEPROBLEMID}";
        #        next
        #    }

        # for recovery notices, the SERVICEPROBLEMID will always be 0, look for the last ID so we can close it
        # our unique id based on nagios unique id
        my $alias = bugalias( $params{LASTSERVICEPROBLEMID} );
        $log->debug("The alias for $params{SERVICEPROBLEMID} is $alias");

        $log->info("Searching for $alias on server");

        # does the bug already exist
        my $search = try {
            return BZ::Client::Bug->search( $client, { alias => $alias } );
        }
        catch {
             $log->logdie(sprintf 'Something bad happened searching for %s via alias %s, error: %s',
                $alias , $params{LASTSERVICEPROBLEMID} , Dumper( $_ ) );
        };

        unless ( ref $search eq 'ARRAY' and @$search ) {
            $log->info( "Unable to locate $params{LASTSERVICEPROBLEMID}, NO-OP");
            try { if ($delete) { $log->debug('Removing file: ' .$f->basename); $f->remove() }}
            catch { $log->warn(sprintf 'Failed to delete %s because: %s', $f->basename, $_) };
            next;
        }

        my $bug = $search->[0];

        $log->info( 'Found ', $bug->alias(), ' with ', $bug->id() );

        ## got this far? lets close the bug then
        close_bug( $f, $bug, \%params );

    }

    $log->info( 'Finished handling recoveries' );

}

}

{

sub stir_stalled {

    $log->info('Going to stir stalled bugs');
    my %search = (
        status   => [ 'NEW', 'ASSIGNED', 'REOPENED' ],
        keywords => $team{keywords}
    );

    my @bugs = try {
        return BZ::Client::Bug->search( $client, \%search )
    }
    catch {
         $log->logdie(sprintf 'Something bad happened searching for NEW, ASSIGNED AND REOPENED bugs: %s',
            Dumper( $_ ) );
    };

    if (@bugs) {
        my $now = DateTime->now();

        for my $bug (@bugs) {

            # create time = last change, nothing has happened
            if (0 == DateTime->compare($bug->last_change_time,$bug->creation_time)) {

                if ($now->delta_ms($bug->last_change_time)->in_units('hours') < $acktime ) {
                    # give people time to look at it
                    $log->debug(sprintf 'Bug %d is NEW but not yet passed ACK time. Leaving it alone', $bug->id);
                    next
                }

                $log->debug(sprintf 'Bug %d has not been ACK\'d - adding a comment', $bug->id);

                # add a comment, this will taint the bug's last_change_time
                my %comment = (
                    id => $bug->id,
                    comment => sprintf(<<'EOF', $0, hostname(), $acktime)
No activity on new bug within %3$d hours of creation.

***Please tend to this issue urgently***

PLEASEACK: By %1$s running on %2$s
EOF

                );

                my $commentid = try {
                    return BZ::Client::Bug::Comment->add($client,\%comment)
                }
                catch {
                    $log->logdie(sprintf 'Something bad happened adding an ACK comment: %s',
                        Dumper( $_ ) );
                };

                $log->info(sprintf 'Added please ACK to Bug %d, comment id %d ', $bug->id, $commentid);

                next

            }

            # if last_change_time >= stir time, then absolutely we need to do something
            if ($now->delta_ms($bug->last_change_time)->in_units('hours') >= $stirtime ) {

                $log->debug(sprintf 'Bug %d needs a stir - adding a comment', $bug->id);

                # add a comment, this will taint the bug's last_change_time
                my %comment = (
                    id => $bug->id,
                    comment => sprintf(<<'EOF', $0, hostname(), $stirtime)
Bug appears to have stalled, %3$d hours of inactivity.

***Please tend to this issue urgently***

STIRSTALLED: By %1$s running on %2$s
EOF

                );

                my $commentid = try {
                    return BZ::Client::Bug::Comment->add($client,\%comment)
                }
                catch {
                    $log->logdie(sprintf 'Something bad happened adding an stir comment: %s',
                        Dumper( $_ ) );
                };

                $log->info(sprintf 'Added a stir to Bug %d, comment id %d ', $bug->id, $commentid);

                next
            }

            # FIXME, do something with bugs that are just being stired over and over

            $log->debug(sprintf 'Bug %d is NEW/ASSIGNED but not yet ready for a stir. Leaving it alone', $bug->id);

        }
    }

    $log->info('Finished stirring stalled bugs');

}

}

{

sub close_resolved {

    $log->info('Going to close resolved bugs');
    my %search = (
        status   => 'RESOLVED',
        keywords => $team{keywords}
    );

    my @bugs = try {
        return BZ::Client::Bug->search( $client, \%search )
    }
    catch {
         $log->logdie(sprintf 'Something bad happened searching for RESOLVED bugs: %s',
            Dumper( $_ ) );
    };

    if (@bugs) {
         my $now = DateTime->now();

         for my $bug (@bugs) {

              if ($now->delta_ms($bug->last_change_time)->in_units('hours') < $closetime ) {
                  $log->debug(sprintf 'Bug %d is RESOLVED but not yet for 7 days. Leaving it alone', $bug->id);
                  next;
              }

              $log->info(sprintf 'Bug %d will be closed as its now over %d hours since touched', $bug->id, $closetime);

              my %update = (
                  ids     => [ $bug->id ],
                  status  => 'CLOSED',
                  comment => {
                      body => sprintf(
                  <<'EOF', $0, hostname(), $closetime/24)
Closed automatically due to RESOLVED and %3$d days of inactivity.
AUTOCLOSE: By %1$s running on %2$s
EOF
                  }
              );

              my @changed = try { return BZ::Client::Bug->update( $client, \%update ) }
              catch {
                  $log->warn('Something bad happended trying to close %d: %s', $bug->id, Dumper($_))
              };
              if (@changed) {
                      $log->info(sprintf 'Closed bug %d', $bug->id)
              }

         }
    }

    $log->info('Finished closing resolved bugs');
}

}

# from the nagios queue
handle_problems();
handle_recovery();

# do house keeping
close_resolved();
# people are ignoring this # stir_stalled();

# this is just so we can clean up quickly
if ($closeplease and @pleaseclose) {
    $log->info( "closing these: @pleaseclose" );

    my %update = (
        ids        => \@pleaseclose,
        comment    => { comment => 'autoclose test stuff', },
        status     => 'RESOLVED',
        resolution => 'INVALID',
    );
    my $done =
      BZ::Client::Bug->update( $client, \%update );    # FIXME catch exception
    $update{status} = 'VERIFIED';
    $done =
      BZ::Client::Bug->update( $client, \%update );    # FIXME catch exception

}

$log->info('END');

1

__END__

