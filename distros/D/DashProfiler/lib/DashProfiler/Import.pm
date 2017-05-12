package DashProfiler::Import;

use strict;

our $VERSION = sprintf("1.%06d", q$Revision: 45 $ =~ /(\d+)/o);

use base qw(Exporter);

use Carp;

use DashProfiler;

our $ExportLevel = 0;

=head1 NAME

DashProfiler::Import - Import curried DashProfiler sampler function at compile-time

=head1 SYNOPSIS

  use DashProfiler::Import foo_profiler => [ "my context 1" ];

  use DashProfiler::Import foo_profiler => [ "my context 1" ],
                           bar_profiler => [ "my context 1", context2edit => sub { ... } ];

  use DashProfiler::Import -optional, baz_profiler => [ "my context 1" ];

  ...
  my $sample = foo_profiler("baz");

=head1 DESCRIPTION

Firstly, read L<DashProfiler::UserGuide> for a general introduction.

The example above imports a function called foo_profiler() that is a sample
factory for the DashProfiler called "foo", pre-configured ("curried") to
use the value "bar" for context1.

=head2 Using *_profiler_enabled()

It also imports a function called foo_profiler_enabled() that's a constant,
returning false if the named DashProfiler was disabled at the time.

This is useful when profiling very time-senstive code and you want the
profiling to have I<zero> overhead when not in use. For example:

    my $sample = foo_profiler("baz") if foo_profiler_enabled();

Because the C<*_profiler_enabled> function is a constant, the perl compiler
will completely remove the code if the corresponding DashProfiler is disabled.

If there is no DashProfiler called "foo" then you'll get a compile-time error
unless the C<-optional> directive has been given first.

Generally this style of code in perl is considered bad practice and error prone:

    my $var = ... if ...;

because the behaviour when the condition is false on one execution having been
true on previous execution is not well defined (on purpose, because it's
surprisingly hard to explain what it does, and anyway, it may change).

For the DashProfiler::Import module, however, that style of code is just fine.
That's because the condition is a compile-time constant.

=cut

sub import {
    my $class = shift;
    my $pkg = caller($ExportLevel);

    my $optional = 0;

    while (@_) {
        local $_ = shift;

        if (m/^[-:](\w+)/) { # the ':optional' form is deprecated
            if ($1 eq 'optional') {
                $optional = 1;
            }
            else {
                croak "Unknown DashProfiler::Import directive '$_'";
            }
            next;
        }

        m/^((\w+)_profiler)$/
            or croak "$class name '$_' must end with _profiler";
        my ($var_name, $profile_name) = ($1, $2);
        my $args = shift;

        my $profile = DashProfiler->get_profile($profile_name);
        if (!$profile) {
            croak "No profile called '$profile_name' has been defined"
                unless $optional;
            # fall-thru to check args and create stubs
        }

        croak "$var_name => ... requires an array ref containing at least one element"
            unless ref $args eq 'ARRAY' and @$args >= 1;
        my $profiler = ($profile) ? $profile->prepare(@$args) : undef;

        #warn "$pkg $var_name ($profile_name) => $context1 $profiler";
        {
            no strict 'refs'; ## no critic
            # if profile has been disabled then export a dummy sub instead
            *{"${pkg}::$var_name"} = $profiler || sub { undef };
            # also export a constant sub that can be used to optimize away the
            # call to the profiler - see docs
            *{"${pkg}::${var_name}_enabled"} = ($profiler) ? sub () { 1 } : sub () { 0 };
        }
    }
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

