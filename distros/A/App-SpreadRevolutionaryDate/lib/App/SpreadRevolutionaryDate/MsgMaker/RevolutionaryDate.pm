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
package App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate;
$App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::VERSION = '0.51';
# ABSTRACT: MsgMaker class for L<App::SpreadRevolutionaryDate> to build message with revolutionary date

use Moose;
with 'App::SpreadRevolutionaryDate::MsgMaker';

use App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Calendar;

use Locale::TextDomain 'App-SpreadRevolutionaryDate';
use namespace::autoclean;

has '+locale' => (
  default => 'fr',
);

has 'acab' => (
  is  => 'ro',
  isa => 'Bool',
  required => 1,
  default => 0,
);

has 'wikipedia_link' => (
  is  => 'ro',
  isa => 'Bool',
  required => 1,
  default => 1,
);

around BUILDARGS => sub {
  my ($orig, $class, %args) = @_;

  $args{locale} = 'fr'
    unless   $args{locale}
          && grep { $args{locale} eq $_ } ('en', 'it', 'es');
  return $class->$orig(%args);
};


sub compute {
  my $self = shift;

  # As of App::SpreadRevolutionaryDate 0.11
  # locale is limited to 'fr', 'en', 'it' or 'es', defaults to 'fr'
  # forced to 'fr' for any other value
  my $revolutionary = $self->acab ?
      App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Calendar->now->set(hour => 1, minute => 31, second => 20, locale => $self->locale)
    : App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Calendar->now->set(locale => $self->locale);

  my $feast_long = $revolutionary->feast_long;
  my $today = DateTime->today;
  if ($self->special_birthday_day && $self->special_birthday_month && $self->special_birthday_name && $today->day == $self->special_birthday_day && $today->month == $self->special_birthday_month) {
      $feast_long = $revolutionary->locale->prefixes->[$self->special_birthday_prefix] . $self->special_birthday_name . $revolutionary->locale->suffix;
  }

  my $msg = __x("We are {day_name}, {day} {month} of Revolution year {roman_year} ({year}), {feast_long}, it is {time}!",
      day_name   => $revolutionary->day_name,
      day        => $revolutionary->day,
      month      => $revolutionary->month_name,
      roman_year => $revolutionary->strftime("%EY"),
      year       => $revolutionary->year,
      feast_long => $feast_long,
      time       => $revolutionary->hms,
  );

  if ($self->special_birthday_day && $self->special_birthday_month && $self->special_birthday_name && $today->day == $self->special_birthday_day && $today->month == $self->special_birthday_month && $self->special_birthday_url) {
      $msg .= ' ' . $self->special_birthday_url;
  } elsif ($self->wikipedia_link) {
    use URI::Escape;
    my $entry = $revolutionary->locale->wikipedia_redirect($revolutionary->month, $revolutionary->feast_short);
    $msg .= ' https://' . $self->locale . '.wikipedia.org/wiki/' . uri_escape_utf8($entry);
  }

  return ($msg, undef);
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

App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate - MsgMaker class for L<App::SpreadRevolutionaryDate> to build message with revolutionary date

=head1 VERSION

version 0.51

=head1 METHODS

=head2 compute

Computes revolutionary date. Takes no argument. Returns message as string, ready to be spread.

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
