package DashProfiler::Core;

=head1 NAME

DashProfiler::Core - DashProfiler core object and sampler factory

=head1 SYNOPSIS

See L<DashProfiler::UserGuide> for a general introduction.

DashProfiler::Core is currently viewed as an internal class. The interface may change.
The DashProfiler and DashProfiler::Import modules are the usual interfaces.

=head1 DESCRIPTION

A DashProfiler::Core objects are the core of the DashProfiler, naturally.
They sit between the 'samplers' that feed data into a core, and the DBI::Profile
objects that aggregate those samples. A core may have multiple samplers and
multiple profiles.

=cut

use strict;

our $VERSION = sprintf("1.%06d", q$Revision: 48 $ =~ /(\d+)/o);

use DBI 1.57 qw(dbi_time dbi_profile_merge);
use DBI::Profile;
use DBI::ProfileDumper;
use Carp;

our $ENDING = 0;

BEGIN {
    # use env var to control debugging at compile-time
    my $debug = $ENV{DASHPROFILER_CORE_DEBUG} || $ENV{DASHPROFILER_DEBUG} || 0;
    eval "sub DEBUG () { $debug }; 1;" or die; ## no critic
}
END {
    $ENDING = 1;
}


BEGIN {
    # load Hash::Util for lock_keys()
    # if Hash::Util isn't available then install a stub for lock_keys()
    eval {
        require Hash::Util;
        Hash::Util->import('lock_keys');
    };
    die @$ if $@ && $@ !~ /^Can't locate Hash\/Util/;
    *lock_keys = sub { } if not defined &lock_keys;
}


# check for weaken support, used by ChildHandles
my $HAS_WEAKEN = eval {
    require Scalar::Util;
    # this will croak() if this Scalar::Util doesn't have a working weaken().
    Scalar::Util::weaken( my $test = [] );
    1;
};
*weaken = sub { croak "Can't weaken without Scalar::Util::weaken" }
    unless $HAS_WEAKEN;


# On 2GHz OS X 10.5.2 laptop:
#   sample_overhead_time = 0.000014s
#   sample_inner_time    = 0.000003s
my ($sample_overhead_time, $sample_inner_time) = estimate_sample_overheads();


=head1 CLASS METHODS

=head2 new

  $obj = DashProfiler::Core->new( 'foo' );

  $obj = DashProfiler::Core->new( 'bar', { ...options... } );

  $obj = DashProfiler::Core->new( extsys => {
      granularity => 10,
      flush_interval => 300,
  } );

Creates and returns a DashProfiler::Core object.

=head2 Options for new()

=head3 disabled

Set to a true value to prevent samples being added to this core. If true, the
prepare() method and the L<DashProfiler::Sample> new() method will return undef.

Default false.

Currently, any existing samples that were active will still be added when they
terminate. This behaviour may change.

See also L<DashProfiler::Import>.

=head3 dbi_profile_class

Specifies the class to use for creating DBI::Profile objects.
The default is C<DBI::Profile>. Alternatives include C<DBI::ProfileDumper>
and C<DBI::ProfileDumper::Apache>.

=head3 dbi_profile_args

Specifies extra arguments to pass the new() method of the C<dbi_profile_class>
(e.g., C<DBI::Profile>). The default is C<{ }>.

=head3 flush_interval

How frequently the DBI:Profiles associated with this core should be written out
and the data reset. Default is 0 - no regular flushing.

=head3 flush_hook

If set, this code reference is called when flush() is called and can influence
its behaviour. For example, this is the flush_hook used by L<DashProfiler::Auto>:

    flush_hook => sub {
        my ($self, $dbi_profile_name) = @_;
        warn $_ for $self->profile_as_text($dbi_profile_name);
        return $self->reset_profile_data($dbi_profile_name);
    },

See L</flush> for more details.

=head3 granularity

The default C<Path> for the DBI::Profile objects doesn't include time.
The granularity option adds 'C<!Time~$granularity>' to the front of the Path.
So as time passes the samples are aggregated into new sub-trees.

=head3 sample_class

The sample_class option specifies which class should be used to take profile samples.
The default is C<DashProfiler::Sample>.
See the L</prepare> method for more information.

=head3 period_summary

Specifies the name of an extra DBI Profile object to attach to the core.
This extra 'period summary' profile is enabled and reset by the start_sample_period()
method and disabled by the end_sample_period() method.

The mechanism enables a single profile to be used to capture both long-running
sampling (often with C<granularity> set) and single-period (e.g., for a 'debug'
footer on a generated web page)

=head3 period_exclusive

When using periods, via the start_sample_period() and end_sample_period() methods,
DashProfiler can add an additional sample representing the time between the
start_sample_period() and end_sample_period() method calls that I<wasn't>
accounted for by the samples.

The period_exclusive option enables this extra sample. The value of the option
is used as the value for key1 and key2 in the Path.

=head3 period_strict_start

See L</start_sample_period>.

=head3 period_strict_end

See L</end_sample_period>.

=head3 profile_as_text_args

A reference to a hash containing default formatting arguments for the profile_as_text() method.

=head3 extra_info

Can be used to attach any extra information to the profiler core object. That can be useful sometimes in callbacks.

=cut

sub new {
    my ($class, $profile_name, $opt_params) = @_;
    $opt_params ||= {};
    croak "No profile_name given" unless $profile_name && not ref $profile_name;
    croak "$class->new($profile_name, $opt_params) options must be a hash reference"
        if ref $opt_params ne 'HASH';

    our $opt_defaults ||= {
        disabled => 0,
        sample_class => 'DashProfiler::Sample',
        dbi_profile_class => 'DBI::Profile',
        dbi_profile_args => {},
        flush_interval => 0,
        flush_hook => undef,
        granularity => 0,
        period_exclusive => undef,
        period_summary => undef,
        period_strict_start  => 0x01,
        period_strict_end    => 0x00,
        profile_as_text_args => undef,
        extra_info => undef, # for caller to hook in their own data
    };
    croak "Invalid options: ".join(', ', grep { !$opt_defaults->{$_} } keys %$opt_params)
        if keys %{ { %$opt_defaults, %$opt_params } } > keys %$opt_defaults;

    my $time = dbi_time();
    my $self = bless {
        profile_name         => $profile_name,
        in_use               => 0,
        in_use_warning_given => 0,
        dbi_handles_all      => {},
        dbi_handles_active   => {},
        flush_due_at_time    => undef,
        # for start_period
        period_count         => 0,
        period_start_time    => 0,
        period_accumulated   => 0,
        exclusive_sampler    => undef,
        %$opt_defaults,
        %$opt_params,
    } => $class;
    $self->{flush_due_at_time} = $time + $self->{flush_interval};

    lock_keys(%$self);

    _load_class($self->{sample_class});

    if (my $exclusive_name = $self->{period_exclusive}) {
        # create the sampler through which period_exclusive samples are added
        # by end_sample_period()
        $self->{exclusive_sampler} = $self->prepare($exclusive_name, $exclusive_name);
    }
    my $dbi_profile = $self->_mk_dbi_profile($self->{dbi_profile_class}, $self->{granularity});
    $self->attach_dbi_profile( $dbi_profile, "main", 0 );

    if (my $period_summary = $self->{period_summary}) {
        my $dbi_profile = $self->_mk_dbi_profile("DashProfiler::DumpNowhere", 0);
        my $dbh = $self->attach_dbi_profile( $dbi_profile, "period_summary", 0 );
        $self->{dbi_handles_all}{period_summary} = $dbh;
        # start_sample_period() will add handle to {dbi_handles_active}
    }

    # mark as in_use if disabled as this allows the sampler to be more efficient
    $self->{in_use} = -42 if $self->{disabled};

    return $self;
}


=head2 estimate_sample_overheads

  $sample_overhead_time = DashProfiler::Core->estimate_sample_overheads();

  ($sample_overhead_time, $sample_inner_time)
      = DashProfiler::Core->estimate_sample_overheads();

Estimates and returns the approximate minimum time overhead for taking a sample.
Two times are returned. The following timeline diagram explains the difference:

    previous statement      -------------                              
                                      |                                
    sampler called                    |                                
      sampler does work               |                                
      sampler reads time    -----     |                           
      sampler does work       |       |                           
      return sample object    |       |                           
                              |       |                           
    (measured statements)     |       |                           
                              |       |                           
    sample DESTROY'd          |       |                           
      sample does work        v       |                           
      sample reads time     -----     |     = sample_inner_time  
      sample does work                |                                
                                      v                                
    next statement          -------------   = sample_overhead_time       

For estimate_sample_overheads() there are no I<measured statements> so the
times reflect the pure overheads.

Note that because estimate_sample_overheads() uses a tight loop, the timings
returned are likely to be I<slightly> smaller then the timings you'd get in
practice due to CPU L2 caches and other factors. This is okay.
On my 2GHz laptop running OS X 10.5.2 $sample_overhead_time is 0.000014 and
$sample_inner_time is 0.000003. (When doing occasional sampling the
sample_overhead_time is 0.000002 to 0.000003 higher, in case you care.)

DashProfiler automatically calls estimate_sample_overheads() when loading and
records the returned values.  It then uses the C<sample_overhead_time> to
adjust the L</period_exclusive> time to more accrately reflect the time not
covered by the accumulated samples.  Currently the C<sample_inner_time> is
I<not> subtracted from the individual samples. That may change in future.

=cut

sub estimate_sample_overheads {
    my ($self, $count) = @_;
    $count ||= 1000;

    my $profile = __PACKAGE__->new('overhead',{ dbi_profile_class => 'DashProfiler::DumpNowhere' });
    my $sampler = $profile->prepare('c1');
    # It's okay that this is a tight loop so will tend to give lower times
    # than would be experienced in practice because, while we want to get as
    # close as possible to the true overhead, we don't want to overestimate it.
    my ($i, $sum) = ($count, 0);
    while ($i--) {
        my $t0 = dbi_time();         # to compare with t1 below
        my $t1 = dbi_time();         # time before sampling
        my $ps1 = $sampler->("c2");  # begin sample
        undef $ps1;                  # end sample
        $sum += (dbi_time() - $t1)   # time to perform full sample lifecycle
              - ($t1 - $t0);         # subtract cost of calling dbi_time()
    }
    # overhead is average of time spent calling sampler & DESTROY:
    $sample_overhead_time = $sum / $count; # ~0.000014s on 2GHz OS X 10.5.2 laptop
    $sample_inner_time    = ($profile->get_dbi_profile->{Data}{c1}{c2}[1] / $count);

    # we could also subtract the time accumulated by the samples, like this:
    #   $sample_overhead_time -= $sample_inner_time
    # but we don't because that's also a valid part of the overhead
    # because there are no statements between the sample creation and destruction.

    warn sprintf "sample_overhead_time=%.7fs (sample_inner_time=%.7fs)\n",
        $sample_overhead_time, $sample_inner_time if DEBUG();

    $profile->reset_profile_data;

    return  $sample_overhead_time unless wantarray;
    return ($sample_overhead_time, $sample_inner_time);
}



=head1 OBJECT METHODS

=head2 attach_dbi_profile

  $core->attach_dbi_profile( $dbi_profile, $name );

Attaches a DBI Profile to a DashProfiler::Core object using the $name given.
Any later samples are also aggregated into this DBI Profile.

Not normally called directly. The new() method calls attach_dbi_profile() to
attach the "main" profile and the C<period_summary> profile, if enabled.

The $dbi_profile argument can be either a DBI::Profile object or a string
containing a DBI::Profile specification.

The get_dbi_profile($name) method can be used to retrieve the profile.

=cut

sub attach_dbi_profile {
    my ($self, $dbi_profile, $dbi_profile_name, $weakly) = @_;
    # wrap DBI::Profile object/spec with a DBI handle
    croak "No dbi_profile_name specified" unless defined $dbi_profile_name;
    local $ENV{DBI_AUTOPROXY};
    my $dbh = DBI->connect("dbi:DashProfiler:", "", "", {
        Profile => $dbi_profile,
        RaiseError => 1, PrintError => 1, TraceLevel => 0,
    });
    $dbh = tied %$dbh; # switch to inner handle
    $dbh->{Profile}->empty; # discard FETCH&STOREs etc due to connect()
    for my $handles ($self->{dbi_handles_all}, $self->{dbi_handles_active}) {
        # clean out any dead weakrefs
        defined $handles->{$_} or delete $handles->{$_} for keys %$handles;
        $handles->{$dbi_profile_name} = $dbh;
#       weaken($handles->{$dbi_profile_name}) if $weakly;   # not currently documented or used
    }
    return $dbh;
}


sub _attach_new_temporary_plain_profile {   # not currently documented or used
    my ($self, $dbi_profile_name) = @_;
    # create new DBI profile (with no time key) that doesn't flush anywhere
    my $dbi_profile = $self->_mk_dbi_profile("DashProfiler::DumpNowhere", 0);
    # attach to the profile, but only weakly
    $self->attach_dbi_profile( $dbi_profile, $dbi_profile_name, 1 );
    # return ref so caller can store till ready to discard
    return $dbi_profile;
}


sub _mk_dbi_profile {
    my ($self, $class, $granularity) = @_;

    _load_class($class);
    my $Path = $granularity ? [ "!Time~$granularity", "!Statement", "!MethodName" ]
                            : [                       "!Statement", "!MethodName" ];
    my $dbi_profile = $class->new(
        Path  => $Path,
        Quiet => 1,
        Trace => 0,
        File  => "dashprofile.$self->{profile_name}",
        %{ $self->{dbi_profile_args} },
    );

    return $dbi_profile;
};


=head2 get_dbi_profile

  $dbi_profile  = $core->get_dbi_profile( $dbi_profile_name );
  @dbi_profiles = $core->get_dbi_profile( '*' );

Returns a reference to the DBI Profile object that attached to the $core with the given name.
If $dbi_profile_name is undef then it defaults to "main".
Returns undef if there's no profile with that name atached.
If $dbi_profile_name is 'C<*>' then it returns all attached profiles.
See L</attach_dbi_profile>.

=cut

sub get_dbi_profile {
    my ($self, $name) = @_;
    my $dbi_handles = $self->{dbi_handles_all}
        or return;
    # we take care to avoid auto-viv here
    my $dbh = $dbi_handles->{ $name || 'main' };
    return $dbh->{Profile} if $dbh;
    return unless $name && $name eq '*';
    croak "get_dbi_profile('*') called in scalar context" unless wantarray;
    return map {
        ($_->{Profile}) ? ($_->{Profile}) : ()
    } values %$dbi_handles;
}


=head2 profile_as_text

  $core->profile_as_text();
  $core->profile_as_text( $dbi_profile_name );
  $core->profile_as_text( $dbi_profile_name, {
      path      => [ $self->{profile_name} ],
      format    => '%1$s: dur=%11$f count=%10$d (max=%14$f avg=%2$f)'."\n",
      separator => ">",
  } );

Returns the aggregated data from the specified DBI Profile (default "main") formatted as a string.
Calls L</get_dbi_profile> to get the DBI Profile, then calls the C<as_text> method on the profile.
See L<DBI::Profile> for more details of the parameters.

In list context it returns one item per profile leaf node, in scalar context
they're concatenated into a single string. Returns undef if the named DBI
Profile doesn't exist.

=cut

sub profile_as_text {
    my $self = shift;
    my $name = shift;
    my $default_args = $self->{profile_as_text_args} || {};
    my %args = (%$default_args, %{ shift || {} });

    $args{path}   ||= [ $self->{profile_name} ];
    $args{format} ||= '%1$s: dur=%11$f count=%10$d (max=%14$f avg=%2$f)'."\n";
    $args{separator} ||= ">";

    my $dbi_profile = $self->get_dbi_profile($name) or return;
    return $dbi_profile->as_text(\%args);
}


=head2 reset_profile_data

  $core->reset_profile_data( $dbi_profile_name );

Resets (discards) DBI Profile data and resets the period count to 0.
If $dbi_profile_name is false then it defaults to "main".
If $dbi_profile_name is "*" then all attached profiles are reset.
Returns a list of the affected DBI::Profile objects.

=cut

sub reset_profile_data {
    my ($self, $dbi_profile_name) = @_;
    my @dbi_profiles = $self->get_dbi_profile($dbi_profile_name);
    $_->empty for @dbi_profiles;
    $self->{period_count} = 0;
    return @dbi_profiles;
}


sub _visit_nodes {  # depth first with lexical ordering
    my ($self, $node, $path, $sub) = @_;
    croak "No sub ref given" unless ref $sub eq 'CODE';
    return unless $node;
    $path ||= [];
    if (ref $node eq 'HASH') {    # recurse
        $path = [ @$path, undef ];
        return map {
            $path->[-1] = $_;
            ($node->{$_}) ? $self->_visit_nodes($node->{$_}, $path, $sub) : ()
        } sort keys %$node;
    }
    return $sub->($node, $path);
}   


=head2 visit_profile_nodes

  $core->visit_profile_nodes( $dbi_profile_name, sub { ... } )

Calls the given subroutine for each leaf node in the named DBI Profile.
The name defaults to "main". If $dbi_profile_name is "*" then the leafs nodes
in all the attached profiles are visited.

=cut

sub visit_profile_nodes {
    my ($self, $dbi_profile_name, $sub) = @_;
    my @dbi_profiles = $self->get_dbi_profile($dbi_profile_name);
    for my $dbi_profile (@dbi_profiles) {
        my $data = $dbi_profile->{Data}
            or next;
        $self->_visit_nodes($data, undef, $sub)
    }
    return;
}


=head2 propagate_period_count

  $core->propagate_period_count( $dbi_profile_name )

Sets the count field of all the leaf-nodes in the named DBI Profile to the
number of times start_sample_period() has been called since the last flush() or
reset_profile_data().

If $dbi_profile_name is "*" then counts in all attached profiles are set.

Resets the period count used.

Does nothing but return 0 if the the period count is zero.

This method is especially useful where the number of sample I<periods> are much
more relevant than the number of samples. This is typically the case where
sample periods correspond to major units of work, such as web requests.
Using propagate_period_count() lets you calculate averages based on the count
of I<periods> instead of samples.

Imagine, for example, that you're instrumenting a web application and you have
a function that sends a request to some network service and another reads each
line of the response.  You'd add DashProfiler sampler calls to each function.
The number of samples recorded in the leaf node will depends on the number of
lines in the response from the network service. You're much more likely to want
to know "average total time spent handling the network service per http request"
than "average time spent in a network service related function".

This method is typically called just before a flush(), often via C<flush_hook>.

=cut

sub propagate_period_count {
    my ($self, $dbi_profile_name) = @_;
    # force count of all nodes to be count of periods instead of samples
    my $count = $self->{period_count}
        or return 0;
    warn "propagate_period_count $self->{profile_name} count $count\n" if DEBUG();
    # force count of all nodes to be count of periods
    $self->visit_profile_nodes($dbi_profile_name, sub { return unless ref $_[0] eq 'ARRAY'; $_[0]->[0] = $count });
    return $count;
}


=head2 flush

  $core->flush()
  $core->flush( $dbi_profile_name )

Calls the C<flush_hook> code reference, if set, passing it $core and the
$dbi_profile_name augument (which is typically undef).  If the C<flush_hook>
code returns a non-empty list then flush() does nothing more except return that
list.

If C<flush_hook> wasn't set, or it returned an empty list, then the flush_to_disk()
method is called for the named DBI Profile (defaults to "main", use "*" for all).
In this case flush() returns a list of the DBI::Profile objects flushed.

=cut


sub flush {
    my ($self, $dbi_profile_name) = @_;
    if (my $flush_hook = $self->{flush_hook}) {
        # if flush_hook returns true then don't call flush_to_disk
        my @ret = $flush_hook->($self, $dbi_profile_name);
        return @ret if @ret;
        # else fall through
    }
    my @dbi_profiles = $self->get_dbi_profile($dbi_profile_name);
    $_->flush_to_disk for (@dbi_profiles);
    return @dbi_profiles;
}


=head2 flush_if_due

  $core->flush_if_due()

Returns nothing if C<flush_interval> was not set.
Returns nothing if C<flush_interval> was set but insufficient time has passed since
the last call to flush_if_due().
Otherwise notes the time the next flush will be due, and calls C<return flush();>.

=cut

sub flush_if_due {
    my ($self) = @_;
    return unless $self->{flush_interval};
    return if time() < $self->{flush_due_at_time};
    $self->{flush_due_at_time} = time() + $self->{flush_interval};
    return $self->flush();
}


=head2 has_profile_data

    $bool = $core->has_profile_data
    $bool = $core->has_profile_data( $dbi_profile_name )

Returns true if the named DBI Profile (default "main") contains any profile data.

=cut

sub has_profile_data {
    my ($self, $dbi_profile_name) = @_;
    my @dbi_profiles = $self->get_dbi_profile($dbi_profile_name)
        or return undef; ## no critic
    keys %{$_->{Data}||{}} && return 1 for (@dbi_profiles);
    return 0;
}


=head2 start_sample_period

  $core->start_sample_period

Marks the start of a series of related samples, e.g, within one http request.

If end_sample_period() has not been called for this core since the last
start_sample_period() then the value of the C<period_strict_start> attribute
determines the actions taken:

  0 = restart the period, silently
  1 = restart the period and issue a warning (this is the default)
  2 = continue the current period, silently
  3 = continue the current period and issue a warning
  4 = call end_sample_period(), silently
  5 = call end_sample_period() and issue a warning

If the value is a CODE ref then it's called (and passed $core) and the return value used.

Resets the C<period_accumulated> attribute to zero.
Sets C<period_start_time> to the current dbi_time().
If C<period_summary> is enabled then the period_summary DBI Profile is enabled and reset.

See also L</end_sample_period>, the C<period_summary> option, and L</propagate_period_count>.

=cut

sub start_sample_period {
    my $self = shift;
    # marks the start of a series of related samples, e.g, within one http request
    # see end_sample_period()
    if ($self->{period_start_time}) {
        if (my $strictness = $self->{period_strict_start}) {
            $strictness = $strictness->($self) if ref $strictness eq 'CODE';
            carp "start_sample_period() called for $self->{profile_name} without preceeding end_sample_period()"
                if $strictness & 0x01;
            return
                if $strictness & 0x02;
            $self->end_sample_period()
                if $strictness & 0x04;
        }
    }
    if (my $period_summary_h = $self->{dbi_handles_all}{period_summary}) {
        # ensure period_summary_h dbi profile will receive samples
        $self->{dbi_handles_active}{period_summary} = $period_summary_h;
        $period_summary_h->{Profile}->empty; # start period empty
    }
    $self->{period_accumulated} = 0;
    $self->{period_start_time}  = dbi_time();
    return;
}


=head2 end_sample_period

  $core->end_sample_period

Marks the end of a series of related samples, e.g, within one http request.

If start_sample_period() has not been called for this core since the last
end_sample_period() (or the start of the script) then the value of the
C<period_strict_end> attribute determines the actions taken:

  0 = do nothing, silently (this is the default)
  1 = do nothing but warn
  2 = call start_sample_period(), silently
  3 = call start_sample_period() and warn

If the value is a CODE ref then it's called (and passed $core) and the return value used.
If start_sample_period() isn't called then end_sample_period() just returns.

The C<period_count> attribute is incremented.

If C<period_exclusive> is enabled then a sample is added with a duration
caclulated to be the time since start_sample_period() was called to now, minus
the time accumulated by samples since start_sample_period() was called.

Resets the C<period_start_time> attribute to 0.  If C<period_summary> is
enabled then the C<period_summary> DBI Profile is disabled and returned, else
undef is returned.

See also L</start_sample_period>, C<period_summary> and L</propagate_period_count>.

=cut

sub end_sample_period {
    my $self = shift;

    if (not $self->{period_start_time}) {
        if (my $strictness = $self->{period_strict_end}) {
            $strictness = $strictness->($self) if ref $strictness eq 'CODE';
            carp "end_sample_period() called for $self->{profile_name} without preceeding start_sample_period()"
                if $strictness & 0x01;
            $self->start_sample_period()
                if $strictness & 0x02;
        }
        # return if we didn't start a period
        return if not $self->{period_start_time};
    }

    $self->{period_count}++;

    # disconnect period_summary dbi profile from receiving any more samples
    my $period_summary_dbh = delete $self->{dbi_handles_active}{period_summary};
    my $period_summary_profile = $period_summary_dbh->{Profile};

    if (my $exclusive_sampler = $self->{exclusive_sampler}) {
        # Calculate how much time between $self->{period_start_time} and now
        # is not accounted for by $self->{period_accumulated}.
        # Add a sample with the start time forced to be period_start_time
        # shifted forward by the accumulated sample durations + sampling overheads.
        # This accounts for all the time between start_sample_period and
        # end_sample_period that hasn't been accounted for by normal samples.

        # calculate overhead of taking samples
        my $overhead;
        if ($period_summary_profile) {
            # if period_summary is enabled then we can use the count of
            # samples this period to scale the overhead correctly
            dbi_profile_merge(my $total=[], $period_summary_profile->{Data});
            # scale overhead by number of samples in period
            $overhead = $sample_overhead_time * $total->[0];
        }
        else {
            # if period_summary is not enabled then we can't do much
            $overhead = $sample_overhead_time;
        }

        warn sprintf "%s period end: overhead %.6fs (%.0f * %.6fs)\n",
                $self->{profile_name}, $overhead, $overhead/$sample_overhead_time, $sample_overhead_time
            if DEBUG() && DEBUG() >= 3;

        $exclusive_sampler->(undef, $self->{period_start_time} + $self->{period_accumulated} + $overhead);

        # sample gets destroyed, and so counted, immediately.
    }

    $self->{period_start_time} = 0;
    # $self->{period_accumulated} will be reset by start_sample_period()

    return $period_summary_profile;
}


=head2 period_start_time

  $time = $core->period_start_time;

Returns the time the current sample period was started (typically the time
L</start_sample_period> was called) or 0 if there's no period active.

=cut

sub period_start_time {
    return shift->{period_start_time};
}


=head2 prepare

  $sampler_code_ref = $core->prepare( $context1 )
  $sampler_code_ref = $core->prepare( $context1, $context2 )
  $sampler_code_ref = $core->prepare( $context1, $context2, %meta )

  $sampler_code_ref->( $context2 )
  $sampler_code_ref->( $context2, $start_time )

Returns a reference to a subroutine that will create sampler objects.
In effect the prepare() method creates a 'factory'.

The sampler objects created by the returned code reference are pre-set to use
$context1, and optionally $context2, as their context values.

If the appropriate value for C<context2> won't be available until the end of
the sample you can set $context2 to a code reference. The reference will be
executed at the end of the sample. See L<DashProfiler::Sample>.

XXX needs more info about %meta - see the code for now, it's not very complex.

See L<DashProfiler::Sample> for more information.

=cut

sub prepare {
    my ($self, $context1, $context2, %meta) = @_;
    # return undef if profile exists but is disabled
    return undef if $self->{disabled}; ## no critic

    # return a light wrapper around the profile, containing the context1
    my $sample_class = $meta{sample_class} || $self->{sample_class};
    # use %meta to carry context info into sample object factory
    $meta{_dash_profile} = $self;
    $meta{_context1}     = $context1;
    $meta{_context2}     = $context2;
    # skip method lookup
    my $coderef = $sample_class->can("new") || "new";
    return sub { # closure over $sample_class, %meta and $coderef
        $sample_class->$coderef(\%meta, @_)
    };
}


sub DESTROY {
    my $self = shift;
    # global destruction shouldn't be relied upon because often the
    # dbi profile data will have been already destroyed
    $self->end_sample_period() if $self->{period_start_time};
    $self->flush if $self->has_profile_data("*");
}


sub _load_class {
    my ($class) = @_;
    ## no critic
    no strict 'refs';
    return 1 if keys %{"$class\::"}; # already loaded
    (my $file = $class) =~ s/::/\//g;
    require "$file.pm";
}


=head2 DEBUG
    
The DEBUG subroutine is a constant that returns whatever the value of

    $ENV{DASHPROFILER_CORE_DEBUG} || $ENV{DASHPROFILER_DEBUG} || 0;

was when the modle was loaded.

=cut



# --- DBI::ProfileDumper subclass that doesn't flush_to_disk
#     Used by period_summary
{
    package DashProfiler::DumpNowhere;
    use strict;
    use base qw(DBI::ProfileDumper);
    sub flush_to_disk { return }
}


# --- ultra small 'null' driver for DBI ---
#     This is really just for the custom dbh DESTROY method below

{
    package DBD::DashProfiler;
    our $drh;       # holds driver handle once initialised
    sub driver{
        return $drh if $drh;
        my ($class, $attr) = @_;
        $DBD::DashProfiler::db::imp_data_size = 0;
        $DBD::DashProfiler::dr::imp_data_size = 0;
        return DBI::_new_drh($class."::dr", {
            Name => 'DashProfiler', Version => $DashProfiler::Core::VERSION,
        });
    }
    sub CLONE { undef $drh }
}
{   package DBD::DashProfiler::dr;
    our $imp_data_size = 0;
    sub DESTROY { undef }
}
{   package DBD::DashProfiler::db;
    our $imp_data_size = 0;
    use strict;
    sub STORE {
        my ($dbh, $attrib, $value) = @_;
        $value = ($value) ? -901 : -900 if $attrib eq 'AutoCommit';
        return $dbh->SUPER::STORE($attrib, $value);
    }
    sub DESTROY {
        my $dbh = shift;
        $dbh->{Profile} = undef; # don't profile the DESTROY
        return $dbh->SUPER::DESTROY;
    }
}
{   package DBD::DashProfiler::st;
    our $imp_data_size = 0;
}
# fake the %INC entry so DBI install_driver won't try to load it
BEGIN { $INC{"DBD/DashProfiler.pm"} = __FILE__ }



1;

=head1 AUTHOR

DashProfiler by Tim Bunce, L<http://www.tim.bunce.name> and
L<http://blog.timbunce.org>

=head1 COPYRIGHT

The DashProfiler distribution is Copyright (c) 2007-2008 Tim Bunce. Ireland.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut

