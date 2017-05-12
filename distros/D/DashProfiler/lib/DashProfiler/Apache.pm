package DashProfiler::Apache;

use strict;
use warnings;
use Carp;

use base qw(DashProfiler);

our $VERSION = sprintf("1.%06d", q$Revision: 43 $ =~ /(\d+)/o);
our $trace = 0;

use constant MP2 => (
    ($ENV{MOD_PERL_API_VERSION}||0) >= 2
    or eval "require Apache2::ServerUtil; Apache2::ServerUtil::server_root()" ## no critic
);

BEGIN {
  if (MP2) {
    require Apache2::ServerUtil;
    require Apache2::Const;
    Apache2::Const->import(qw(OK DECLINED));

    warn "set_precondition call needs work for mod_perl2"; # see below
  }
  else {
    require Apache;
    require Apache::Constants;
    Apache::Constants->import(qw(OK DECLINED));
  }
}

my $server = eval {
    (MP2) ? Apache2::ServerUtil->server : Apache->server;
};
# warn if we couldn't get a server object, unless were just testing
warn $@ if not $server
    and not ($ENV{HARNESS_VERSION} and $ENV{PERL_DL_NONLAZY});


=head1 NAME

DashProfiler::Apache - Hook DashProfiler into Apache mod_perl (v1 or v2)

=head1 SYNOPSIS

To hook DashProfiler into Apache you add this to your httpd.conf:

    PerlModule DashProfiler::Apache;
    PerlInitHandler       DashProfiler::Apache::start_sample_period_all_profiles
    PerlCleanupHandler    DashProfiler::Apache::end_sample_period_all_profiles
    PerlChildExitHandler  DashProfiler::Apache::flush_all_profiles

You'll also need to define at least one profile. An easy way of doing that
is to use DashProfiler::Auto to get a predefined profile called 'auto':

    PerlModule DashProfiler::Auto;

Or you can define your own, like this:

    PerlModule DashProfiler::Apache;
    <Perl>
	DashProfile->add_profile( foo => { ... } );
    </Perl>

=head1 DESCRIPTION

The DashProfiler module itself will work just fine with Apache.
The DashProfiler::Apache just fine-tunes the integration in a few ways:

B<*> Sets a precondition on start_sample_period_all_profiles() so that it only
starts a period for 'initial' requests (where $r->is_initial_req is true).
This is typically only relevant if your code uses $r->internal_redirect.

B<*> Adds a simple trace mechanism so you can easily see which
DashProfiler::Apache functions are called for which Apache handlers.

=head2 Example Apache mod_perl Configuration

    PerlModule DashProfiler::Apache;
    PerlInitHandler       DashProfiler::Apache::start_sample_period_all_profiles
    PerlCleanupHandler    DashProfiler::Apache::end_sample_period_all_profiles
    PerlChildExitHandler  DashProfiler::Apache::flush_all_profiles
    <Perl>
        # files will be written to $spool_directory/dashprofiler.subsys.ppid.pid
        DashProfiler->add_profile('subsys', {
            granularity => 30,
            flush_interval => 60,
            add_exclusive_sample => 'other',
            spool_directory => '/tmp', # needs write permission for apache user
        });
    </Perl>

=cut

DashProfiler->set_precondition(
    start_sample_period_all_profiles => sub {
	# we only want to start a period for 'initial' requests
	# because we only end them in PerlCleanupHandler and that's only
	# called for initial requests
	my $r = (MP2) ? undef : Apache->request;
	my $is_initial_req = $r->is_initial_req;
	_trace(sprintf "start precondition = %d (main %d, prev %d)",
		$is_initial_req, $r->is_main, $r->prev?1:0)
	    if $trace;
	return $is_initial_req;
    }
);


sub _trace {
    return unless $trace;
    my $r = (MP2) ? undef : Apache->request;
    my $current_callback = ($r) ? "r$$r ".$r->current_callback." " : "";
    my $uri = $r->the_request;
    print STDERR "${current_callback}@_ $uri\n";
}


sub start_sample_period_all_profiles {
    _trace("start_sample_period_all_profiles") if $trace;
    DashProfiler->start_sample_period_all_profiles();
    return DECLINED;
}


sub end_sample_period_all_profiles {
    _trace("end_sample_period_all_profiles") if $trace;
    DashProfiler->end_sample_period_all_profiles();
    return DECLINED;
}


sub flush_all_profiles {
    _trace("flush_all_profiles") if $trace;
    DashProfiler->flush_all_profiles();
    return DECLINED;
}


sub reset_all_profiles {
    _trace("reset_all_profiles") if $trace;
    DashProfiler->reset_all_profiles();
    return DECLINED;
}


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

