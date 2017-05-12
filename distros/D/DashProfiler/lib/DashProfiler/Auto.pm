package DashProfiler::Auto;

use strict;
use warnings;
use Carp;

use base qw(DashProfiler::Import);

our $VERSION = sprintf("1.%06d", q$Revision: 45 $ =~ /(\d+)/o);


=head1 NAME

DashProfiler::Auto - Creates and imports a predeclared DashProfiler sampler

=head1 SYNOPSIS

Measure the time spent between creating a sample object and destroying it:

  $ perl -MDashProfiler::Auto -w -e '$a=auto_profiler("foobar"); sleep 1; undef $a'
  auto > -e > foobar: dur=1.000231 count=1 (max=1.000231 avg=1.000231)
  auto > other > other: dur=0.000451 count=1 (max=0.000451 avg=0.000451)

The leading "auto > -e > foobar" portion shows the name of the profiler (auto),
the name of the file that called it (in this case "-e" because the code was
given on the command line), and finally the argument given to auto_profiler().

The time shown as "auto > other > other" is all the 'other' time spent by the
program that isn't included in the samples taken.

This next example shows use of the 'C<context2>' parameter to auto_profiler()
and also how to samples can overlap:

  $ perl -MDashProfiler::Auto -w -e '
      sub fib {
          my $n = shift;
          return $n if $n < 2;
          my $s = auto_profiler($n, undef, 1);
          fib($n-1) + fib($n-2);
      }
      fib(7)
  '
  auto > -e > 2: dur=0.000054 count=8 (max=0.000013 avg=0.000002)
  auto > -e > 3: dur=0.000137 count=5 (max=0.000046 avg=0.000009)
  auto > -e > 4: dur=0.000197 count=3 (max=0.000085 avg=0.000028)
  auto > -e > 5: dur=0.000245 count=2 (max=0.000139 avg=0.000069)
  auto > -e > 6: dur=0.000226 count=1 (max=0.000226 avg=0.000226)
  auto > -e > 7: dur=0.000370 count=1 (max=0.000370 avg=0.000370)

The timing for "other" isn't shown because if any samples do overlap then
the C<period_exclusive> summary is disabled.

=head1 DESCRIPTION

The DashProfiler::Auto is designed for quick temporary use of DashProfiler.
It avoids the need to create a profile by creating one for you with a typical
configuration, and defining a I<sample period> from the time the module was
loaded to the time the program exits.

=head2 Profiler Configuration

The default configuration is:

    my $auto = DashProfiler->add_profile( auto => {
        period_exclusive => 'other',
        flush_hook => sub {
            my ($self, $dbi_profile_name) = @_;
            warn $_ for $self->profile_as_text($dbi_profile_name);
            return $self->reset_profile_data($dbi_profile_name);
        },
    });

B<*> C<period_exclusive> enables the automatic addition of a sample which measures the time I<not> accounted for by the samples. See L</Sample Periods> below.

B<*> C<flush_hook> uses warn() to write out the profile data, then resets (discards) the data.

=cut

my $auto = DashProfiler->add_profile( auto => {
    period_exclusive => 'other',
    profile_as_text_args => {
        separator => " > ",
    },
    flush_hook => sub {
        my ($self, $dbi_profile_name) = @_;
        warn $_ for $self->profile_as_text($dbi_profile_name);
        return $self->reset_profile_data($dbi_profile_name);
    },
});

=head2 Sample Periods

When the modle is loaded it creates the C<auto> profile and calls

    $auto->start_sample_period();

It also defines an C<END> block which does

    $auto->end_sample_period();
    $auto->flush;

so the sample period runs from the time the module was loaded (typically when
the program started running) through to the time the program exits.

=cut

$auto->start_sample_period();

END {
    $auto->end_sample_period();
    $auto->flush;
}


=head2 Imported Samplers

Using DashProfile::Auto in a file like this:

    use DashProfiler::Auto;

is almost identical to this:

    use DashProfiler::Import auto_profiler => [ basename(__FILE__) ];

=cut

sub import {
    my $class = shift;

    croak "DashProfile::Auto doesn't support explicit imports"
        if @_;

    local $DashProfiler::Import::ExportLevel = $DashProfiler::Import::ExportLevel + 1;

    my $caller_file = (caller)[1];
    $caller_file =~ s:.*[/\\]::; # delete everything upto and including the last slash or backslash
    $class->SUPER::import( auto_profiler => [ $caller_file ] );
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

