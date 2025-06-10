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
package App::SpreadRevolutionaryDate::MsgMaker::Gemini;
$App::SpreadRevolutionaryDate::MsgMaker::Gemini::VERSION = '0.51';
# ABSTRACT: MsgMaker class for L<App::SpreadRevolutionaryDate> to build message with Gemini prompt

use Moose;
with 'App::SpreadRevolutionaryDate::MsgMaker';

use DateTime;
use File::ShareDir ':ALL';
use LWP::UserAgent;
use JSON;

use Locale::TextDomain 'App-SpreadRevolutionaryDate';
use namespace::autoclean;

has 'api_key' => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has 'process' => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has 'prompt' => (
  is  => 'ro',
  isa => 'HashRef[Str]',
  required => 1,
);

has 'search' => (
  is  => 'ro',
  isa => 'HashRef[Bool]',
);

has 'intro' => (
  is  => 'ro',
  isa => 'HashRef[Str]',
);

has 'img_path' => (
  is  => 'ro',
  isa => 'HashRef[Str]',
);

has 'img_url' => (
  is  => 'ro',
  isa => 'HashRef[Str]',
);

has 'img_alt' => (
  is  => 'ro',
  isa => 'HashRef[Str]',
);

has '+locale' => (
  default => 'fr',
);

around BUILDARGS => sub {
  my ($orig, $class, %args) = @_;

  if ($args{process}) {
      die "Process $args{process} has no prompt\n" unless $args{prompt}->{$args{process}};
  }

  return $class->$orig(%args);
};


sub compute {
  my $self = shift;

  my $url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key= ' . $self->api_key;

  my $today = DateTime->now(locale => $self->locale);
  my $prompt = $self->prompt->{$self->process};
  my @vars = $self->prompt->{$self->process} =~ /\$(\w+)/g;
  foreach my $var (@vars) {
    $prompt =~ s/\$$var/$today->$var/e;
  }

  my $payload = {
    contents => [
      {
        parts => [
          {
            text => $prompt,
          }
        ],
      }
    ],
  };

  if ($self->search && $self->search->{$self->process}) {
    $payload->{tools} = [
      {
        google_search => {},
      },
   ];
  }

  my $json = JSON->new->utf8;
  my $args_json = $json->encode($payload);

  my $ua = LWP::UserAgent->new(env_proxy => 1, timeout => 10, agent =>'App::SpreadRevolutionaryDate bot');
  $ua->default_header('Accept' => 'application/json');
  $ua->default_header('Content-Type' => 'application/json');
  my $req = HTTP::Request->new('POST', $url);
  $req->content($args_json);
  my $resp = $ua->request($req);

  my $msg;
  if ($resp && $resp->is_success) {
    my $content;
    eval { $content = $json->decode($resp->content) };
    unless ($@) {
      if ($content->{candidates} && scalar(@{$content->{candidates}}) == 1 && $content->{candidates}->[0]->{content} && $content->{candidates}->[0]->{content}->{parts} && scalar(@{$content->{candidates}->[0]->{content}->{parts}}) >= 1 && $content->{candidates}->[0]->{content}->{parts}->[0]->{text}) {
        $msg = $content->{candidates}->[0]->{content}->{parts}->[0]->{text};
        $msg =~ s/\s+$//;
        $msg .= "\n#IAGenerated #" . $self->process;
      }
    }
  }

  if ($self->intro && $self->intro->{$self->process}) {
    my $intro = $self->intro->{$self->process};
    my @intro_vars = $self->intro->{$self->process} =~ /\$(\w+)/g;
    foreach my $intro_var (@intro_vars) {
      $intro =~ s/\$$intro_var/$today->$intro_var/e;
    }
    $msg = $intro . "\n" . $msg;
  }

  if ($self->special_birthday_gemini && $self->special_birthday_gemini eq $self->process && $self->special_birthday_day && $self->special_birthday_month && $self->special_birthday_name && $today->day == $self->special_birthday_day && $today->month == $self->special_birthday_month) {
      my $name= $self->special_birthday_name;
      $msg =~ s/^((?:\*|\d\.)\s+)(.+)$/$1$name/m;
      if ($self->special_birthday_url) {
          $msg =~ s/https?:\/\/(?:\S+|$)/$self->special_birthday_url/e;
      }
  }

  my $img;
  $img->{path} = $self->img_path->{$self->process} if $self->img_path && $self->img_path->{$self->process};
  $img->{url} = $self->img_url->{$self->process} if $self->img_url && $self->img_url->{$self->process};
  $img->{alt} = $self->img_alt->{$self->process} if $self->img_alt && $self->img_alt->{$self->process};
  return ($msg, $img);
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

App::SpreadRevolutionaryDate::MsgMaker::Gemini - MsgMaker class for L<App::SpreadRevolutionaryDate> to build message with Gemini prompt

=head1 VERSION

version 0.51

=head1 METHODS

=head2 compute

Computes replies by Gemini AI given a prompt.

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

=item L<App::SpreadRevolutionaryDate::MsgMaker::PromptUser>

=item L<App::SpreadRevolutionaryDate::MsgMaker::Telechat>

=back

=head1 AUTHOR

Gérald Sédrati <gibus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2025 by Gérald Sédrati.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
