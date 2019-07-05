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
package App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale;
$App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::VERSION = '0.27';
# ABSTRACT: Role providing interface for localization of revolutionary date built by L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate>.

use Moose::Role;

use DateTime::Calendar::FrenchRevolutionary;

use Locale::TextDomain 'App-SpreadRevolutionaryDate';
use namespace::autoclean;

has months => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  required => 1,
);

has decade_days => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  required => 1,
);

has feast => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  required => 1,
);

has prefixes => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  required => 1,
  default => sub {['']},
);

has suffix => (
  is => 'ro',
  isa => 'Str',
  required => 1,
  default => '',
);

has wikipedia_entries => (
  is => 'ro',
  isa => 'HashRef[HashRef[Str]]',
  required => 1,
);


sub month_name {
  my ($self, $date) = @_;
  return $self->months->[$date->month_0]
}


sub day_name {
  my ($self, $date) = @_;
  return $self->decade_days->[$date->day_of_decade_0];
}


sub feast_short {
  my ($self, $date) = @_;
  my $lb = $self->feast->[$date->day_of_year_0];
  $lb =~ s/_/ /g;
  return substr($lb, 1);
}


sub feast_long {
  my ($self, $date) = @_;
  my $lb = $self->feast->[$date->day_of_year_0] . $self->suffix;
  $lb =~ s/_/ /g;
  $lb =~ s/^(\d)/$self->prefixes->[$1]/e;
  return $lb;
}


sub wikipedia_redirect {
  my ($self, $month, $entry) = @_;
  $entry = $self->wikipedia_entries->{$month}->{$entry}
      if    exists $self->wikipedia_entries->{$month}
         && exists $self->wikipedia_entries->{$month}->{$entry};
  return $entry;
}


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

App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale - Role providing interface for localization of revolutionary date built by L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate>.

=head1 VERSION

version 0.27

=head1 DESCRIPTION

This role defines the localization interface for L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate>.

It provides some methods copied from L<DateTime::Calendar::FrenchRevolutionary::Locale::fr>.

Any class consuming this role is required to overload every mandatory attribute with a default in the language of that class:

=over

=item months

Default for this attribute should be a sorted array reference of 13 strings, each of them translating the name of each month (C<'Vendémiaire'>, C<'Brumaire'>,  C<'Frimaire'>, C<'Nivôse'>, C<'Pluviôse'>, C<'Ventôse'>, C<'Germinal'>, C<'Floréal'>, C<'Prairial'>, C<'Messidor'>, C<'Thermidor'>, and C<'Fructidor'> in French), along with a last pseudo-month (C<jour complémentaire> in French) holding the five additional days (or six on leap years), also called "sans-culottides", added after Fructidor. E.g.:

  has '+months' => (
    default => sub {[
      'Vendémiaire', 'Brumaire',  'Frimaire',
      'Nivôse',      'Pluviôse',  'Ventôse',
      'Germinal',    'Floréal',   'Prairial',
      'Messidor',    'Thermidor', 'Fructidor',
      'jour complémentaire',
    ]},
  );

=item decade_days

Default for this attribute should be a sorted array reference of 10 strings, each of them translating the name of each day (C<'Primidi'>, C<'Duodi'>,  C<'Tridi'>, C<'Quartidi'>, C<'Quintidi'>, C<'Sextidi'>, C<'Septidi'>, C<'Octidi'>, C<'Nonidi'>, and C<'Décadi'> in French). E.g.:

  has '+decade_days' => (
    default => sub {[
      'Primidi',
      'Duodi',
      'Tridi',
      'Quartidi',
      'Quintidi',
      'Sextidi',
      'Septidi',
      'Octidi',
      'Nonidi',
      'Décadi',
    ]},
  );

=item feast

Default for this attribute should be a sorted array reference of 366 strings, each of them translating the feast of each day. Any space in the name of the feast of the day should be replaced by an underscore (C<_>).

The feast of the day is used in sentences like I<this is C<feast name> day> or I<c'est le jour de la C<feast name>>. Depending on the language, it could then be prefixed or suffixed: in English it is suffixed by C< day>, whereas in French it is prefixed by C<jour de la >. See L</prefixes> and L</suffix> attributes below.

Moreover, in languages where the feast of the day is prefixed, the prefix often depends on the gender or the number of the noun used for the feast, or whereas this noun starts by a vowel. Therefore, L</prefixes> attribute should be an array of each possible prefix, and each translation of the feast of each day should starts with a digit specifying the index (starting from 0) in the C<prefixes> attribute to use for this word. E.g.: with C<prefixes> defaulting to C<['jour du ', 'jour de la ', "jour de l'", 'jour des ']>, some default values for C<feast> attribute include C<'1carotte', '2amaranthe', '0panais'> (because you say: I<jour de la carotte>, with prefix number C<1>, I<jour de l'amaranthe>, with prefix number C<2>, and I<jour du panais>, with prefix number C<0>. If the language does not use any prefix before the feast of the day, each translation for the feast of the day should start with C<0>.

=item prefixes

Default for this attribute should be a sorted array reference of possible prefixes, as strings, to use with the feast of the day, see L</feast> attribute below. E.g.:

  has '+prefixes' => (
    default => sub {[
      'jour du ',
      'jour de la ',
      "jour de l'",
      'jour des ',
    ]},
  );

If the language does not use any prefix before the feast of the day, you should not overload this attribute with a default.

=item suffix

Default for this attribute should be a string specifying the suffix to use with the feast of the day, see L</feast> attribute below. E.g.:

  has '+suffix' => (
    default => ' day',
  );

If the language does not use a suffix after the feast of the day, you should not overload this attribute with a default.

=item wikipedia_entries

Default for this attribute should be a hash reference, keyed by numbers of months (starting from 1), valued by an inner hash reference defining the localized wikipedia entry corresponding to each localized feast of the day. This is useful when the feast of the day corresponds to an ambiguous entry, or a different word, in wikipedia. If the wikipedia entry is the same as the feast of the day, you can omit it in the default hashref for C<wikipedia_entries> attribute. E.g.:

  has '+wikipedia_entries' => (
    default => sub {{
      2 => {
        'water chestnut' => 'Water_caltrop',
      },
      8 => {
        'hoe'            => 'Hoe_(tool)',
      },
    }},
  );

=back

=head1 METHODS

=head2 month_name

Returns the name of the month. Takes a L<DateTime::Calendar::FrenchRevolutionary> object as mandatory parameter.

=head2 day_name

Returns the name of the day. Takes a L<DateTime::Calendar::FrenchRevolutionary> object as mandatory parameter.

=head2 feast_short

Returns the feast of the day. Takes a L<DateTime::Calendar::FrenchRevolutionary> object as mandatory parameter.

=head2 feast_long

Returns the feast of the day in long format (I<day of E<lt>xxxE<gt>>). Takes a L<DateTime::Calendar::FrenchRevolutionary> object as mandatory parameter.

=head2 wikipedia_redirect

Returns the wikipedia entry (the end of the wikipedia url) corresponding to the feast of the day. Takes two mandatory parameters: the month as integer from 1 to 13 (13 is used for complementary days, also called "sans-culottides"), and the search entry (which should be the feast of the day as returned by L</feast_short>) as a string.

=head1 SEE ALSO

=over

=item L<spread-revolutionary-date>

=item L<App::SpreadRevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::Config>

=item L<App::SpreadRevolutionaryDate::Target>

=item L<App::SpreadRevolutionaryDate::Target::Twitter>

=item L<App::SpreadRevolutionaryDate::Target::Mastodon>

=item L<App::SpreadRevolutionaryDate::Target::Freenode>

=item L<App::SpreadRevolutionaryDate::Target::Freenode::Bot>

=item L<App::SpreadRevolutionaryDate::MsgMaker>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Calendar>

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
