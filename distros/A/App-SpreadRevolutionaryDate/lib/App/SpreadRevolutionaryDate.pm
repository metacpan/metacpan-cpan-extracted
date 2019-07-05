#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019 by Gérald Sédrati-Dinet.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.014;
use utf8;
package App::SpreadRevolutionaryDate;
$App::SpreadRevolutionaryDate::VERSION = '0.27';
# ABSTRACT: Spread date and time from Revolutionary (Republican) Calendar on Twitter, Mastodon and Freenode.

use Moose;
use App::SpreadRevolutionaryDate::Config;
use Class::Load ':all';

use Locale::TextDomain 'App-SpreadRevolutionaryDate';
use Locale::Messages qw(bind_textdomain_filter);
use Encode;
BEGIN {
  $ENV{OUTPUT_CHARSET} = 'UTF-8';
  bind_textdomain_filter 'App-SpreadRevolutionaryDate' => \&Encode::decode_utf8, Encode::FB_DEFAULT;
}
use namespace::autoclean;

has 'config' => (
  is  => 'ro',
  isa => 'App::SpreadRevolutionaryDate::Config',
  required => 1,
);

has 'targets' => (
  is  => 'rw',
  isa => 'HashRef[Object]',
  required => 1,
);

has 'msgmaker' => (
  is  => 'rw',
  isa => 'Object',
  required => 1,
);


around BUILDARGS => sub {
  my ($orig, $class, $filename) = @_;

  my $config = App::SpreadRevolutionaryDate::Config->new($filename);

  my $msgmaker_class = 'App::SpreadRevolutionaryDate::MsgMaker::' . $config->msgmaker;
  try_load_class($msgmaker_class)
    or die "Cannot import msgmaker class $msgmaker_class\n";
  load_class($msgmaker_class);
  my %msgmaker_args = $config->get_msgmaker_arguments($config->msgmaker);
  my $msgmaker = $msgmaker_class->new(locale => $config->locale, %msgmaker_args);

  return $class->$orig(config => $config, targets => {}, msgmaker => $msgmaker);
};


sub BUILD {
  my $self = shift;

  foreach my $target (@{$self->config->targets}) {
    my $target_class = 'App::SpreadRevolutionaryDate::Target::' . ucfirst(lc($target));
    try_load_class($target_class)
      or die "Cannot import target class $target_class for target $target\n";
    load_class($target_class);
    my %target_args = $self->config->get_target_arguments($target);
    $self->targets->{$target} = $target_class->new(%target_args);
  }
}


sub spread {
  my $self = shift;

  my $msg = $self->msgmaker->compute();
  foreach my $target (@{$self->config->targets}) {
    $self->targets->{$target}->spread($msg, $self->config->test);
  }
}


no Moose;
__PACKAGE__->meta->make_immutable;

# A module must return a true value. Traditionally, a module returns 1.
# But this module is a revolutionary one, so it discards all old traditions.
# Idea borrowed from Jean Forget's DateTime::Calendar::FrenchRevolutionary.
"Quand le gouvernement viole les droits du peuple,
l'insurrection est pour le peuple le plus sacré
et le plus indispensable des devoirs";

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SpreadRevolutionaryDate - Spread date and time from Revolutionary (Republican) Calendar on Twitter, Mastodon and Freenode.

=head1 VERSION

version 0.27

=head1 METHODS

=head2 new

Constructor class method. Takes one optional argument: C<$filename> which should be the file path of, or an opened file handle on your configuration file, defaults to C<~/.config/spread-revolutionary-date/spread-revolutionary-date.conf> or C<~/.spread-revolutionary-date.conf>. This is only used for testing, when custom configuration file is needed. You can safely leave this optional argument unset. Returns an C<App::SpreadRevolutionaryDate> object.

=head2 BUILD

Initialises the internal C<App::SpreadRevolutionaryDate> object. This is where all targets objets are built, and authentication is attempted on each of them.

=head2 spread

Spreads calendar date to configured targets. Takes no argument.

=head1 SEE ALSO

=over

=item L<spread-revolutionary-date>

=item L<App::SpreadRevolutionaryDate::Config>

=item L<App::SpreadRevolutionaryDate::Target>

=item L<App::SpreadRevolutionaryDate::Target::Twitter>

=item L<App::SpreadRevolutionaryDate::Target::Mastodon>

=item L<App::SpreadRevolutionaryDate::Target::Freenode>

=item L<App::SpreadRevolutionaryDate::Target::Freenode::Bot>

=item L<App::SpreadRevolutionaryDate::MsgMaker>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Calendar>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::fr>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::en>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::it>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::es>

=item L<App::SpreadRevolutionaryDate::MsgMaker::PromptUser>

=back

=head1 AUTHOR

Gérald Sédrati-Dinet <gibus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Gérald Sédrati-Dinet.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
