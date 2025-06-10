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
package App::SpreadRevolutionaryDate::Target::Twitter;
$App::SpreadRevolutionaryDate::Target::Twitter::VERSION = '0.51';
# ABSTRACT: Target class for L<App::SpreadRevolutionaryDate> to handle spreading on Twitter.

use Moose;
with 'App::SpreadRevolutionaryDate::Target'
  => {worker => 'Twitter::API__WITH__Twitter::API::Trait::ApiMethods'};

use Twitter::API;

use Locale::TextDomain 'App-SpreadRevolutionaryDate';
use namespace::autoclean;

has 'consumer_key' => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has 'consumer_secret' => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has 'access_token' => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has 'access_token_secret' => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);


around BUILDARGS => sub {
  my ($orig, $class) = @_;

  my $args = $class->$orig(@_);
  my $api_1 = $args->{api} && $args->{api} eq 1 || 0;

  $args->{obj} = Twitter::API->new_with_traits(
                  traits              => 'ApiMethods',
                  $api_1 ?
                    () :
                    (api_version => '2', api_ext => ''),
                  consumer_key        => $args->{consumer_key},
                  consumer_secret     => $args->{consumer_secret},
                  access_token        => $args->{access_token},
                  access_token_secret => $args->{access_token_secret},
                  agent               => 'RevolutionaryDate');
  return $args;
};


sub spread {
  my ($self, $msg, $test) = @_;
  $test //= 0;

  # Multiline message
  $msg =~ s/\\n/\n/g;

  if ($test) {
    $msg = __("Spread on Twitter: ") . $msg;

    use open qw(:std :encoding(UTF-8));
    use IO::Handle;
    my $io = IO::Handle->new;
    $io->fdopen(fileno(STDOUT), "w");

    use Encode qw(encode decode is_utf8);
    $msg = encode('UTF-8', $msg) if is_utf8($msg);

    $io->say($msg);
  } else {
    $self->obj->post('tweets', {'-to_json' => {"text" => $msg}});
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

App::SpreadRevolutionaryDate::Target::Twitter - Target class for L<App::SpreadRevolutionaryDate> to handle spreading on Twitter.

=head1 VERSION

version 0.51

=head1 METHODS

=head2 new

Constructor class method. Takes a hash argument with the following mandatory keys: C<consumer_key>, C<consumer_secret>, C<access_token>, and C<access_token_secret>, with all values being strings. Authentifies to Twitter and returns an C<App::SpreadRevolutionaryDate::Target::Twitter> object.

=head2 spread

Spreads a message to Twitter. Takes one mandatory argument: C<$msg> which should be the message to spread as a characters string; and one optional argument: C<test>, which defaults to C<false>, and if C<true> prints the message on standard output instead of spreading on Twitter.

=head1 SEE ALSO

=over

=item L<spread-revolutionary-date>

=item L<App::SpreadRevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::Config>

=item L<App::SpreadRevolutionaryDate::BlueskyLite>

=item L<App::SpreadRevolutionaryDate::Target>

=item L<App::SpreadRevolutionaryDate::Target::Bluesky>

=item L<App::SpreadRevolutionaryDate::Target::Mastodon>

=item L<App::SpreadRevolutionaryDate::Target::Freenode>

=item L<App::SpreadRevolutionaryDate::Target::Freenode::Bot>

=item L<App::SpreadRevolutionaryDate::Target::Liberachat>

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
