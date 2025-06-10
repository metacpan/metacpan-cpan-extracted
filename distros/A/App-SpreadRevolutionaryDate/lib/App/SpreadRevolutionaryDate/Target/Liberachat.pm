#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019-2025 by Gérald Sédrati.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.014;
use utf8;
package App::SpreadRevolutionaryDate::Target::Liberachat;
$App::SpreadRevolutionaryDate::Target::Liberachat::VERSION = '0.51';
# ABSTRACT: Target class for L<App::SpreadRevolutionaryDate> to handle spreading on Liberachat.

use Moose;
with 'App::SpreadRevolutionaryDate::Target'
  => {worker => 'App::SpreadRevolutionaryDate::Target::Liberachat::Bot'};

use App::SpreadRevolutionaryDate::Target::Liberachat::Bot;
use POE;

use Locale::TextDomain 'App-SpreadRevolutionaryDate';
use namespace::autoclean;

has 'nickname' => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has 'password' => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has 'channels' => (
  is  => 'ro',
  isa => 'ArrayRef[Str]',
  required => 1,
);


around BUILDARGS => sub {
  my ($orig, $class) = @_;

  my $port = 6667;
  my $ssl = 0;

  # Switch to SSL if module POE::Component::SSLify is available
  if (eval { require POE::Component::SSLify; 1 }) {
    $port = 6697;
    $ssl = 1;
  }

  my $args = $class->$orig(@_);

  $args->{obj} = App::SpreadRevolutionaryDate::Target::Liberachat::Bot->new(
    server            => 'irc.libera.chat',
    port              => $port,
    nick              => 'RevolutionaryBot',
    alt_nicks         => ['RevolutionaryCalendar', 'RevolutionaryDate'],
    name              => 'Revolutionary Date bot',
    flood             => 1,
    useipv6           => 1,
    ssl               => $ssl,
    charset           => 'utf-8',
    channels          => $args->{channels},
    liberachat_nickname => $args->{nickname},
    liberachat_password => $args->{password},
    msg               => '',
    no_run            => 1,
  );

  return $args;
};


sub spread {
  my ($self, $msg) = @_;

  # Multiline message
  $msg =~ s/\\n/\n/g;

  $self->obj->msg($msg);
  $self->obj->run;
  POE::Kernel->run();
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

App::SpreadRevolutionaryDate::Target::Liberachat - Target class for L<App::SpreadRevolutionaryDate> to handle spreading on Liberachat.

=head1 VERSION

version 0.51

=head1 METHODS

=head2 new

Constructor class method, subclassing C<Bot::BasicBot>. Takes a hash argument with the following mandatory keys: C<nickname>, C<password>, and C<channels>, with all values being strings. Returns an C<App::SpreadRevolutionaryDate::Target::Liberachat> object.

=head2 spread

Spreads a message to Liberachat channels configured with the multivalued option C<channels>.

=head1 SEE ALSO

=over

=item L<spread-revolutionary-date>

=item L<App::SpreadRevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::Config>

=item L<App::SpreadRevolutionaryDate::BlueskyLite>

=item L<App::SpreadRevolutionaryDate::Target>

=item L<App::SpreadRevolutionaryDate::Target::Bluesky>

=item L<App::SpreadRevolutionaryDate::Target::Twitter>

=item L<App::SpreadRevolutionaryDate::Target::Mastodon>

=item L<App::SpreadRevolutionaryDate::Target::Freenode>

=item L<App::SpreadRevolutionaryDate::Target::Freenode::Bot>

=item L<App::SpreadRevolutionaryDate::Target::Liberachat::Bot>

=item L<App::SpreadRevolutionaryDate::MsgMaker>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Calendar>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::fr>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::en>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::it>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::es>

=item L<App::SpreadRevolutionaryDate::MsgMaker::PromptUser>

=item L<App::SpreadRevolutionaryDate::MsgMaker::Telechat>

=item L<App::SpreadRevolutionaryDate::MsgMaker::Gemini>

=back

=head1 AUTHOR

Gérald Sédrati <gibus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2025 by Gérald Sédrati.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
