#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019 by Gérald Sédrati-Dinet.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
package App::SpreadRevolutionaryDate;
$App::SpreadRevolutionaryDate::VERSION = '0.06';
# ABSTRACT: Spread date and time from Revolutionary (Republican) Calendar on Twitter, Mastodon and Freenode.

use App::SpreadRevolutionaryDate::Config;
use App::SpreadRevolutionaryDate::Twitter;
use App::SpreadRevolutionaryDate::Mastodon;
use App::SpreadRevolutionaryDate::Freenode;
use DateTime::Calendar::FrenchRevolutionary;


sub new {
  my $class = shift;
  my $filename = shift;
  my $config = App::SpreadRevolutionaryDate::Config->new;

  $config->parse_file($filename);
  $config->parse_command_line;

  my $self = {config => $config};

  if (!$self->{config}->twitter && !$self->{config}->mastodon && !$self->{config}->freenode) {
    $self->{config}->twitter(1);
    $self->{config}->mastodon(1);
    $self->{config}->freenode(1);
  }

  if ($self->{config}->twitter) {
    if ($self->{config}->check_twitter) {
      $self->{twitter} = App::SpreadRevolutionaryDate::Twitter->new($self->{config});
    } else {
      die "Cannot spread on Twitter, configuraton parameters missing\n";
    }
  }

  if ($self->{config}->mastodon) {
    if ($self->{config}->check_mastodon) {
      $self->{mastodon} = App::SpreadRevolutionaryDate::Mastodon->new($self->{config});
    } else {
      die "Cannot spread on Mastodon, configuraton parameters missing\n";
    }
  }

  if ($self->{config}->freenode) {
    if ($self->{config}->check_freenode) {
      $self->{freenode} = App::SpreadRevolutionaryDate::Freenode->new($self->{config});
    } else {
      die "Cannot spread on Freenode, configuraton parameters missing\n";
    }
  }

  bless $self, $class;
  return $self;
}


sub spread {
  my $self = shift;
  my $no_run = shift || 1;
  $no_run = !$no_run;

  # As of DateTime::Calendar::FrenchRevolutionary 0.14
  # locale is limited to 'en' or 'fr', defaults to 'fr'
  my $locale = $self->{config}->locale || 'fr';
  $locale = 'fr' unless $locale eq 'en';

  my $now = $self->{config}->acab ?
      DateTime->today->set(hour => 3, minute => 8, second => 56)
    : DateTime->now;
  my $revolutionary = DateTime::Calendar::FrenchRevolutionary->from_object(object => $now, locale => $locale);
  my $msg = $locale eq 'fr' ? $revolutionary->strftime("Nous sommes le %A, %d %B de l'An %EY (%Y) de la Révolution, %Ej, il est %T!") : $revolutionary->strftime("We are %A, %d %B of Revolution Year %EY (%Y), %Ej, it is %T!");

  $self->{twitter}->spread($msg) if $self->{config}->twitter;
  $self->{mastodon}->spread($msg) if $self->{config}->mastodon;
  $self->{freenode}->spread($msg, $no_run) if $self->{config}->freenode;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SpreadRevolutionaryDate - Spread date and time from Revolutionary (Republican) Calendar on Twitter, Mastodon and Freenode.

=head1 VERSION

version 0.06

=head1 METHODS

=head2 new

Constructor class method. Takes one optional argument: C<$filename> which should be the file path of, or an opened file handle on your configuration file, defaults to C<~/.config/spread-revolutionary-date/spread-revolutionary-date.conf> or C<~/.spread-revolutionary-date.conf>. This is only used for testing, when custom configuration file is needed. You can safely leave this optional argument unset. Returns an C<App::SpreadRevolutionaryDate> object.

=head2 spread

Spreads calendar date to configured targets. Takes one optional boolean argument, if true (default) authentication and spreading to Freenode is performed, otherwise, you've got to run C<use POE; POE::Kernel-E<gt>run();> to do so. This is only used for testing, when multiple bots are needed. You can safely leave this optional argument unset.

=head1 SEE ALSO

=over

=item L<spread-revolutionary-date|https://metacpan.org/pod/distribution/App-SpreadRevolutionaryDate/bin/spread-revolutionary-date>

=item L<App::SpreadRevolutionaryDate::Config>

=item L<App::SpreadRevolutionaryDate::Twitter>

=item L<App::SpreadRevolutionaryDate::Mastodon>

=item L<App::SpreadRevolutionaryDate::Freenode>

=item L<App::SpreadRevolutionaryDate::Freenode::Bot>

=back

=head1 AUTHOR

Gérald Sédrati-Dinet <gibus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Gérald Sédrati-Dinet.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
