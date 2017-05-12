package DashProfiler;

use strict;
use warnings;

our $VERSION = "1.13"; # $Revision: 48 $

=head1 NAME

DashProfiler - efficiently collect call count and timing data aggregated by context

=head1 SYNOPSIS

The DashProfiler modules enable you to efficiently collect performance data
by adding just a line of code to the functions or objects you want to monitor.

Data is aggregated by context and optionally also by a granular time axis.

See L<DashProfiler::UserGuide> for a general introduction.

=head1 DESCRIPTION

=head2 Performance

DashProfiler is fast, very fast. Especially given the functionality and flexibility it offers.

When you build DashProfiler, the test suite shows the performance on your
system when you run "make test". On my system, for example it reports:

    t/02.sample.......ok 1/0 you're using perl 5.010000 on darwin-2level -O3     
      Average 'cold' sample overhead is 0.000021s (max 0.000104s, min 0.000019s)
      Average 'hot'  sample overhead is 0.000017s (max 0.000102s, min 0.000016s)

=head2 Apache mod_perl

DashProfiler was designed to work well with Apache mod_perl in high volume production environments.

Refer to L<DashProfiler::Apache> for details.

=cut

use Carp;
use Data::Dumper;

use DashProfiler::Core;

my %profiles;
my %precondition;

=head1 PRIMARY METHODS

=head2 add_profile

  DashProfiler->add_profile( 'my_profile_name' );
  DashProfiler->add_profile( my_profile_name => { ... } );
  $core = DashProfiler->add_core( my_profile_name => { ... } );

Calls DashProfiler::Core->new to create a new DashProfiler::Core object and
then caches it, using the name as the key, so it can be refered to by name.

See L<DashProfiler::Core> for details of the arguments.

=cut

sub add_profile {
    my $class = shift;
    croak "A profile called '$_[0]' already exists" if $profiles{$_[0]};
    my $self = DashProfiler::Core->new(@_);
    $profiles{ $self->{profile_name} } = $self;
    return $self;
}


=head2 prepare

    $sampler = DashProfiler->prepare($profile_name, ...);

Calls prepare(...) on the DashProfiler named by $profile_name.
Returns a sampler code reference prepared to take samples.

If no profile with that name exists then it will warn, but only once per name.

=cut

sub prepare {
    my $class = shift;
    my $profile_name = shift;
    my $profile_ref = $profiles{$profile_name};
    unless ($profile_ref) { # to catch spelling mistakes
        carp "No $class profiler called '$profile_name' exists"
            unless defined $profile_ref;
        $profiles{$profile_name} = 0; # only warn once
        return;
    };
    return $profile_ref->prepare(@_);
}


=head2 profile_names

  @profile_names = DashProfiler->profile_names;

Returns a list of all the profile names added via L</add_profile>.

=cut

sub profile_names {
    my $class = shift;
    # return keys but skip 0 entries that might be added by prepare()
    return grep { $profiles{$_} } keys %profiles;
}


=head2 get_profile

    $core = DashProfiler->get_profile( $profile_name );

Returns the DashProfiler::Core object associated with that name.

=cut

sub get_profile {
    my ($self, $profile_name) = @_;
    return $profiles{$profile_name};
}


=head2 profile_as_text

  $text = DashProfiler->profile_as_text( $profile_name )

Calls profile_as_text(...) on the DashProfiler named by $profile_name.
Returns undef if no profile with that name exists.

=cut

sub profile_as_text {
    my $self = shift;
    my $profile_name = shift;
    my $profile_ref = $self->get_profile($profile_name) or return;
    return $profile_ref->profile_as_text(@_);
}


=head1 METHODS AFFECTING ALL PROFILES

=head2 all_profiles_as_text

  @text = DashProfiler->all_profiles_as_text

Calls profile_as_text() on all profiles, ordered by name.

=cut

sub all_profiles_as_text {
    my $class = shift;
    return map { $profiles{$_}->profile_as_text() } sort keys %profiles;
}


=head2 dump_all_profiles

    dump_all_profiles()

Equivalent to

    warn $_ for DashProfiler->all_profiles_as_text();

=cut

sub dump_all_profiles {
    my $class = shift;
    warn $_ for $class->all_profiles_as_text();
    return 1;
}


=head2 reset_all_profiles

Calls C<reset_profile_data> for all profiles.

Typically called from mod_perl PerlChildInitHandler.

=cut

sub reset_all_profiles {    # eg PerlChildInitHandler
    my $class = shift;
    if (my $pre = $precondition{reset_all_profiles}) {
	return 1 unless $pre->();
    }
    $_->reset_profile_data for values %profiles;
    return -1; # DECLINED
}
$precondition{reset_all_profiles} = undef;


=head2 flush_all_profiles

  flush_all_profiles()

Calls flush() for all profiles.
Typically called from mod_perl PerlChildExitHandler

=cut

sub flush_all_profiles {    # eg PerlChildExitHandler
    my $class = shift;
    if (my $pre = $precondition{flush_all_profiles}) {
	return -1   # DECLINED
            unless $pre->();
    }
    $_->flush for values %profiles;
    return -1;  # DECLINED
}
$precondition{flush_all_profiles} = undef;


=head2 start_sample_period_all_profiles

  start_sample_period_all_profiles()

Calls start_sample_period() for all profiles.
Typically called from mod_perl PerlPostReadRequestHandler

=cut

sub start_sample_period_all_profiles { # eg PerlPostReadRequestHandler
    my $class = shift;
    if (my $pre = $precondition{start_sample_period_all_profiles}) {
	return -1   # DECLINED
            unless $pre->();
    }
    $_->start_sample_period for values %profiles;
    return -1;   # DECLINED
}
$precondition{start_sample_period_all_profiles} = undef;


=head2 end_sample_period_all_profiles

  end_sample_period_all_profiles()

Calls end_sample_period() for all profiles.
Then calls flush_if_due() for all profiles.
Typically called from mod_perl PerlCleanupHandler

=cut

sub end_sample_period_all_profiles { # eg PerlCleanupHandler
    my $class = shift;
    if (my $pre = $precondition{end_sample_period_all_profiles}) {
	return -1   # DECLINED
            unless $pre->();
    }
    $_->end_sample_period for values %profiles;
    $_->flush_if_due      for values %profiles;
    return -1;  # DECLINED
}
$precondition{end_sample_period_all_profiles} = undef;

=head1 OTHER METHODS

=head2 set_precondition

  DashProfiler->set_precondition( function => sub { ... } );

Available functions are:

    reset_all_profiles
    flush_all_profiles
    start_sample_period_all_profiles
    end_sample_period_all_profiles

The set_precondition method associates a code reference with a function.
When the function is called the corresponding precondition code is executed
first.  If the precondition code does not return true then the function returns
immediately.

This mechanism is most useful for fine-tuning when periods start and end.
For example, there may be times when start_sample_period_all_profiles() is
being called when you might not want to actually start a new period.

Alternatively the precondition code could itself call start_sample_period()
for one or more specific profiles and then return false.

See L<DashProfiler::Apache> for an example use.

=cut

sub set_precondition {
    my ($class, $name, $code) = @_;
    croak "Not a CODE reference" if $code and ref $code ne 'CODE';
    croak "Invalid function name '$name'" unless exists $precondition{$name};
    $precondition{$name} = $code;
    return;
}


=head1 AUTHOR

DashProfiler by Tim Bunce, L<http://www.tim.bunce.name> and
L<http://blog.timbunce.org>

=head1 COPYRIGHT

The DashProfiler distribution is Copyright (c) 2007-2008 Tim Bunce. Ireland.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut

1;
