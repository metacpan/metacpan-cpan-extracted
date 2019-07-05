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
package App::SpreadRevolutionaryDate::Target;
$App::SpreadRevolutionaryDate::Target::VERSION = '0.27';
# ABSTRACT: Role providing interface for targets of L<App::SpreadRevolutionaryDate>.

use MooseX::Role::Parameterized;
use LWP::Protocol::https;

use Locale::TextDomain 'App-SpreadRevolutionaryDate';
use namespace::autoclean;

parameter worker => (
  isa     => 'Str',
  default => 'Any',
);

role {
  my $p = shift;

  has obj => (
    is => 'ro',
    isa => $p->worker,
    required => 1,
  );

  requires 'spread';
};


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

App::SpreadRevolutionaryDate::Target - Role providing interface for targets of L<App::SpreadRevolutionaryDate>.

=head1 VERSION

version 0.27

=head1 DESCRIPTION

This role defines the interface for any target which L<App::SpreadRevolutionaryDate> should spread the revolutionary date to.

Any consuming class can parameterize this role (through L<MooseX::Role::Parameterized>) with a C<worker> type set to the effective Perl module implementing any protocol needed by this target (eg. L<Net::Twitter::Lite::WithAPIv1_1>, L<Mastodon::Client>). Then, this role provides an C<obj> required attribute with type constraint defined by the C<worker> parameter. If no C<worker> parameter is given, the C<obj> type defaults to C<Any>. Constructors of consuming classes should instanciate C<obj> (with L<Moose> C<BUILDARGS> or C<BUILD>, see L<Moose::Manual::Construction>).

Any class consuming this role is required to implement a C<spread> method, which is called with two parameters: C<msg>, the message as a string to be spread, and C<test>, an optional boolean which informs this method to actually spread the message if this parameter is C<false> (that should be the default), or to just test without spreading.

If the target needs authentication, it can be carried out in the constructor (with L<Moose> C<BUILDARGS> or C<BUILD>) or in the implementation of the C<spread> method, obviously before actually spreading the message.

=head1 SEE ALSO

=over

=item L<spread-revolutionary-date>

=item L<App::SpreadRevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::Config>

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
