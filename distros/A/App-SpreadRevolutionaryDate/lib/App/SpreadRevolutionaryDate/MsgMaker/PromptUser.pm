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
package App::SpreadRevolutionaryDate::MsgMaker::PromptUser;
$App::SpreadRevolutionaryDate::MsgMaker::PromptUser::VERSION = '0.51';
# ABSTRACT: MsgMaker class for L<App::SpreadRevolutionaryDate> to build message by prompting user

use Moose;
with 'App::SpreadRevolutionaryDate::MsgMaker';

use open qw(:std :encoding(UTF-8));
use IO::Prompt::Hooked;
use File::Spec;
use File::Basename;
use File::Temp qw/tempfile/;
use LWP::UserAgent;

use Locale::TextDomain 'App-SpreadRevolutionaryDate';
use namespace::autoclean;

has 'default' => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
  default => 'Goodbye old world, hello revolutionary worlds',
);

has 'img_path' => (
  is => 'rw',
  isa => 'Str',
  default => '',
);

has 'img_alt' => (
  is => 'rw',
  isa => 'Str',
  default => '',
);

has 'img_url' => (
  is => 'rw',
  isa => 'Str',
  default => '',
);

around BUILDARGS => sub {
  my ($orig, $class, %args) = @_;

  if ($args{locale}) {
    # Get sure locale has .mo file
    my ($volume, $directory, $file) = File::Spec->splitpath(__FILE__);
    my $locale_mo = File::Spec->catfile($directory, '..', '..', '..', 'LocaleData', $args{locale}, 'LC_MESSAGES', 'App-SpreadRevolutionaryDate.mo');
    $args{locale} = 'en' unless -f $locale_mo;
  }

  # Do not pass default => undef to force default in attribute definition
  delete $args{default}
    if exists $args{default} && !defined $args{default};
  return $class->$orig(%args);
};


sub compute {
  my $self = shift;

  my $question = __"Please, enter message to spread";
  #TRANSLATORS: initial used in case insensitive context
  my $confirm_ok = lc(substr(__("yes"), 0, 1));
  #TRANSLATORS: initial used  case insensitive context
  my $confirm_nok = lc(substr(__("no"), 0, 1));
  #TRANSLATORS: initial used in case sensitive context
  my $confirm_abort = substr(__("Abort"), 0, 1);
  my $confirm_abort_text = __x("or {abort} to abort", abort => $confirm_abort);
  my $confirm_intro = __"Spread";
  my $confirm_question = __x("confirm ({confirm_ok}/{confirm_nok} {confirm_abort_text})?", confirm_ok => $confirm_ok, confirm_nok => $confirm_nok, confirm_abort_text => $confirm_abort_text);
  my $confirm_error = __x("Input must be \"{confirm_ok}\" or \"{confirm_nok}\"\n", confirm_ok => $confirm_ok, confirm_nok => $confirm_nok);
  my $abort = __"OK not spreading";

  if ($self->img_path) {
    $self->img_alt(ucfirst(fileparse($self->img_path, qr/\.[^.]*/))) unless $self->img_alt;
    $confirm_question =  __x("with image file"). ' ' . $self->{img_path} . ' (alt:' . $self->img_alt . '), ' . $confirm_question;
  } elsif ($self->img_url) {
    $self->img_alt(ucfirst(fileparse($self->img_url, qr/\.[^.]*/))) unless $self->img_alt;
    $confirm_question =  __x("with image from url:"). ' ' . $self->{img_url} . ' (alt:' . $self->img_alt . '), ' . $confirm_question;
  }

  my $confirm = $confirm_nok;
  my $msg;
  while (defined $confirm && $confirm !~ qr($confirm_ok)) {
    $msg = prompt($question, $self->default);
    $confirm = prompt(
      message  => $confirm_intro . ' "' . $msg . '", ' . $confirm_question,
      default  => $confirm_ok,
      validate => qr/^[$confirm_ok$confirm_nok]$/i,
      escape   => qr/^$confirm_abort$/,
      error    => $confirm_error,
      tries    => 2,
    );
  }
  die "$abort\n" unless defined $confirm && $confirm =~ qr($confirm_ok);

  if ($self->img_path) {
    return ($msg, {path => $self->img_path, alt => $self->img_alt});
  } elsif ($self->img_url) {
    my $ua = LWP::UserAgent->new(env_proxy => 1, timeout => 10, agent =>'App::SpreadRevolutionaryDate bot');
    my $response = $ua->get($self->img_url);
    die "Cannot download image from " . $self->img_url . ": " . $response->status_line . "\n" unless $response->is_success;

    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh $response->content;
    close $fh;
    return ($msg, {path => $filename, alt => $self->img_alt});
  } else {
    return ($msg, undef);
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

App::SpreadRevolutionaryDate::MsgMaker::PromptUser - MsgMaker class for L<App::SpreadRevolutionaryDate> to build message by prompting user

=head1 VERSION

version 0.51

=head1 METHODS

=head2 compute

Prompts user for the message to be spread. Takes no argument. Returns message as string, ready to be spread.

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
