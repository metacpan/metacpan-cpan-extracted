package DashProfiler::Sample;

=head1 NAME

DashProfiler::Sample - encapsulates the acquisition of a single sample

=head1 DESCRIPTION

Firstly, read L<DashProfiler::UserGuide> for a general introduction.

A DashProfiler::Sample object is returned from the prepare() method of DashProfiler::Core,
or from the functions imported by DashProfiler::Import.

The object, and this class, are rarely used directly.

=head1 METHODS

=cut

use strict;

our $VERSION = sprintf("1.%06d", q$Revision: 48 $ =~ /(\d+)/o);

use DBI;
use DBI::Profile qw(dbi_profile dbi_time);
use constant DBI_GE_1603 => ($DBI::VERSION >= 2.603);
use Carp;

BEGIN {
    # use env var to control debugging at compile-time
    # see pod for DEBUG at end
    my $debug = $ENV{DASHPROFILER_SAMPLE_DEBUG} || $ENV{DASHPROFILER_DEBUG} || 0;
    eval "sub DEBUG () { $debug }; 1;" or die; ## no critic
}


=head2 new

This method is normally only called by the code reference returned from the
DashProfiler::Core prepare() method, and not directly.

    $sample = DashProfiler::Sample->new($meta, $context2);
    $sample = DashProfiler::Sample->new($meta, $context2, $start_time, $allow_overlap);

The returned object encapsulates the time of its creation and the supplied arguments.

The $meta parameter must be a hash reference containing at least a
'C<_dash_profile>' element which must be a reference to a DashProfiler::Core
object. The new() method marks the profile as 'in use'.

If the $context2 is false then $meta->{_context2} is used instead.

If $start_time false, which it normally is, then the value returned by dbi_time() is used instead.

If $allow_overlap is false, which it normally is, then if the DashProfiler
refered to by the 'C<_dash_profile>' element of %$meta is marked as 'in use'
then a warning is given (just once) and C<new> returns undef, so no sample is
taken.

If $allow_overlap is true, then overlaping samples can be taken. However, if
samples do overlap then C<period_exclusive> is disabled for that DashProfiler.

=cut

sub new {
    # ($class, $meta, $context2, $start_time, $allow_overlap)
    my $profile_ref = $_[1]->{_dash_profile}; # $meta->_dash_profile
    if ($profile_ref->{in_use}++) {
        if ($profile_ref->{disabled}) {
            $profile_ref->{in_use}--; # undo the increment we did above
            return;
        }
        if ($_[4]) { # allow_overlaping_use
            # can't use exclusive timer with nested samples
            undef $profile_ref->{exclusive_sampler};
        }
        else {
            Carp::cluck("$_[0] $profile_ref->{profile_name} already active")
                unless $profile_ref->{in_use_warning_given}++; # warn once
            return; # don't double count
        }
    }
    # to help debug nested profile samples you can uncomment this
    # and remove the ++ from the if() above and tweak the cluck message
    #$profile_ref->{in_use} = Carp::longmess("");
    return bless [
        $_[1],
        $_[2] || $_[1]->{_context2},
        $_[3] || dbi_time(), # do this as late as practical
    ] => $_[0];
}


=head2 current_sample_duration

  $ps = foo_profiler(...);
  my $duration = $ps->current_sample_duration();

Returns the amount of time since the sample was created.

=cut

sub current_sample_duration {
    return dbi_time() - shift->[2];
}


=head2 DESTROY

When the DashProiler::Sample object is destroyed it:

 - calls dbi_time() to get the time of the end of the sample

 - marks the profile as no longer 'in use'

 - adds the timespan of the sample to the 'period_accumulated' of the DashProiler

 - extracts context2 from the DashProiler::Sample object. If it's a code reference
   then it's executed and the return value is used as context2.
   This is very useful where the value of context2 can't be determined
   at the time the sample is started.

 - if the $meta hash reference (passed to new()) contained a 'C<context2edit>'
   code reference then it's called and passed context2 and $meta.
   The return value is used as context2.

 - calls DBI::Profile::dbi_profile(handle, context1, context2, start time, end time)
   for each DBI profile currently attached to the DashProiler.

=cut

sub DESTROY {
    my $end_time = dbi_time(); # get timestamp as early as practical

    # Any fatal errors won't be reported because we're in a DESTROY.
    # This can make debugging hard. If you suspect a problem then uncomment this:
    #local $SIG{__DIE__} = sub { warn @_ } if DEBUG(); ## no critic
    # Note that throwing an exception can be used by the context2edit hook
    # to 'veto' the sample.

    my ($meta, $context2, $start_time) = @{+shift};

    my $profile_ref = $meta->{_dash_profile};
    undef $profile_ref->{in_use};
    $profile_ref->{period_accumulated} += $end_time - $start_time;

    $context2 = $context2->($meta)
        if ref $context2 eq 'CODE';
    $context2 = $meta->{context2edit}->($context2, $meta)
        if ref $meta->{context2edit} eq 'CODE';

    carp(sprintf "%s: %s %s: %f - %f = %f",
        $profile_ref->{profile_name}, $meta->{_context1}, $context2, $start_time, $end_time, $end_time-$start_time
    ) if DEBUG() and DEBUG() >= 4;

    if (DBI_GE_1603()) {    # use more functional dbi_profile() if available
        dbi_profile($profile_ref->{dbi_handles_active}, $meta->{_context1}, $context2, $start_time, $end_time);
    }
    else {
        # if you get an sv_dump ("SV = RV(0x181aa80) at 0x1889a80 ...") to stderr
        # it probably means %$dbi_handles_active contains a plain hash ref not a dbh
        for (values %{$profile_ref->{dbi_handles_active}}) {
            next unless defined; # skip any dead weakrefs
            dbi_profile($_, $meta->{_context1}, $context2, $start_time, $end_time);
        }
    }

    return;
}


1;

=head2 DEBUG

The DEBUG subroutine is a constant that returns whatever the value of

    $ENV{DASHPROFILER_SAMPLE_DEBUG} || $ENV{DASHPROFILER_DEBUG} || 0;

was when the modle was loaded.

=head1 AUTHOR

DashProfiler by Tim Bunce, L<http://www.tim.bunce.name> and
L<http://blog.timbunce.org>

=head1 COPYRIGHT

The DashProfiler distribution is Copyright (c) 2007-2008 Tim Bunce. Ireland.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut

