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
package App::SpreadRevolutionaryDate::Target::Bluesky;
$App::SpreadRevolutionaryDate::Target::Bluesky::VERSION = '0.51';
# ABSTRACT: Target class for L<App::SpreadRevolutionaryDate> to handle spreading on Bluesky.

use Moose;
with 'App::SpreadRevolutionaryDate::Target'
  => {worker => 'App::SpreadRevolutionaryDate::BlueskyLite'};

use App::SpreadRevolutionaryDate::BlueskyLite;
use Encode qw(encode decode is_utf8);

use Locale::TextDomain 'App-SpreadRevolutionaryDate';
use namespace::autoclean;

has 'identifier' => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has 'password' => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has 'max_lenght' => (
  is  => 'ro',
  isa => 'Int',
  required => 1,
  default => 250,
);


around BUILDARGS => sub {
  my ($orig, $class) = @_;

  my $args = $class->$orig(@_);

  $args->{obj} = App::SpreadRevolutionaryDate::BlueskyLite->new(
                  identifier => $args->{identifier},
                  password   => $args->{password},
  );
  return $args;
};


sub spread {
  my ($self, $msg, $test, $img) = @_;
  $test //= 0;

  # Multiline message
  $msg =~ s/\\n/\n/g;

  if ($test) {
    $msg = __("Spread on Bluesky: ") . $msg;

    if ($img) {
      $msg .= " with image path: " . $img->{path} . " , alt: " . $img->{alt};
    }

    use open qw(:std :encoding(UTF-8));
    use IO::Handle;
    my $io = IO::Handle->new;
    $io->fdopen(fileno(STDOUT), "w");

    my @msgs = $self->_split_msg($msg, $self->max_lenght);

    for (my $i = 0; $i < scalar @msgs; $i++) {
      my $msg = "Message " . ($i+1) . ": " . $msgs[$i];
      $msg = encode('UTF-8', $msg) if is_utf8($msg);
      $io->say($msg);
    }
  } else {
    my @msgs = $self->_split_msg($msg, $self->max_lenght);
    my $last_status;

    foreach my $msg (@msgs) {
      if (!$last_status) {
        # First post
        my $status = $self->obj->create_post($msg, $img);
        if ($status && ref($status) eq 'HASH' && $status->{uri} && $status->{cid}) {
          $last_status = {
            root => {
              uri => $status->{uri},
              cid => $status->{cid},
            },
            parent => {
              uri => $status->{uri},
              cid => $status->{cid},
            }
          };
        }
      } else {
        # Next posts with reply_to
        my $status = $self->obj->create_post($msg, undef, $last_status);
        if ($status && ref($status) eq 'HASH' && $status->{uri} && $status->{cid}) {
          $last_status->{parent} = {
            uri => $status->{uri},
            cid => $status->{cid},
          };
        }
      }
    }
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

App::SpreadRevolutionaryDate::Target::Bluesky - Target class for L<App::SpreadRevolutionaryDate> to handle spreading on Bluesky.

=head1 VERSION

version 0.51

=head1 METHODS

=head2 new

Constructor class method. Takes a hash argument with the following mandatory keys: C<identifier> and C<password>, with all values being strings. Authentifies to Bluesky and returns an C<App::SpreadRevolutionaryDate::Target::Bluesky> object.

=head2 spread

Spreads a message to Bluesky. Takes one mandatory argument: C<$msg> which should be the message to spread as a characters string; and one optional argument: C<test>, which defaults to C<false>, and if C<true> prints the message on standard output instead of spreading on Bluesky.

=head1 SEE ALSO

=over

=item L<spread-revolutionary-date>

=item L<App::SpreadRevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::Config>

=item L<App::SpreadRevolutionaryDate::BlueskyLite>

=item L<App::SpreadRevolutionaryDate::Target>

=item L<App::SpreadRevolutionaryDate::Target::Twitter>

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
