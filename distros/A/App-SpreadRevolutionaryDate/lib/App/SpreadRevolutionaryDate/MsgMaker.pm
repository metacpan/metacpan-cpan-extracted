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
package App::SpreadRevolutionaryDate::MsgMaker;
$App::SpreadRevolutionaryDate::MsgMaker::VERSION = '0.27';
# ABSTRACT: Role providing interface for crafting a message to be spread by L<App::SpreadRevolutionaryDate>.

use Moose::Role;
use Locale::Util qw(set_locale);
use Locale::Messages qw(LC_ALL nl_putenv);

use Locale::TextDomain 'App-SpreadRevolutionaryDate';
use namespace::autoclean;

has locale => (
  is => 'ro',
  isa => 'Str',
  required => 1,
  default => 'en',
  trigger => sub {
    # Set locale to $val, see https://metacpan.org/pod/Locale::TextDomain::FAQ#How-do-I-switch-languages-or-force-a-certain-language-independently-from-user-settings-read-from-the-environment?
    my ( $self, $val, $old_val ) = @_;
    if ($val) {
      Locale::Messages->select_package('gettext_pp');
      set_locale(LC_ALL, $val, undef, 'utf-8');
      nl_putenv("LANGUAGE=$val");
      nl_putenv("LANG=$val");
      nl_putenv("OUTPUT_CHARSET=utf-8");
    }
  },
);

requires 'compute';


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

App::SpreadRevolutionaryDate::MsgMaker - Role providing interface for crafting a message to be spread by L<App::SpreadRevolutionaryDate>.

=head1 VERSION

version 0.27

=head1 DESCRIPTION

This role defines the interface for any class that makes a message to be spread by L<App::SpreadRevolutionaryDate>.

Any class consuming this role is required to implement a C<compute> method, which is called with no parameters, and should return the message to be spread as a string.

This role provides a C<locale> required attribute (defaults to C<'fr'>), which holds the language, defined in language code of L<ISO 639-1 alpha-2|https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes>. Consuming classes are then free to use this C<locale> attribute to localize the message they compute.

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
