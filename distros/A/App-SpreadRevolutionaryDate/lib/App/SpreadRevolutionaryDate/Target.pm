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
package App::SpreadRevolutionaryDate::Target;
$App::SpreadRevolutionaryDate::Target::VERSION = '0.51';
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

sub _split_msg {
  my ($self, $text, $max_len) = @_;
  my @msgs;
  while ($text) {
    if (length $text <= $max_len) {
      push @msgs, $text;
      last;
    }
    my $prefix = substr $text, 0, $max_len;
    my $loc = rindex $prefix, ' ';

    if ($loc == -1) {
      die "We found a word which is longer than $max_len\n";
    }
    my $str = substr $text, 0, $loc, '';
    push @msgs, $str;
    substr $text, 0, 1, '';
  }
  return @msgs;
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

App::SpreadRevolutionaryDate::Target - Role providing interface for targets of L<App::SpreadRevolutionaryDate>.

=head1 VERSION

version 0.51

=head1 DESCRIPTION

This role defines the interface for any target which L<App::SpreadRevolutionaryDate> should spread the revolutionary date to.

Any consuming class can parameterize this role (through L<MooseX::Role::Parameterized>) with a C<worker> type set to the effective Perl module implementing any protocol needed by this target (eg. L<App::SpreadRevolutionaryDate::BlueskyLite>, L<Twitter::API>, L<Mastodon::Client>). Then, this role provides an C<obj> required attribute with type constraint defined by the C<worker> parameter. If no C<worker> parameter is given, the C<obj> type defaults to C<Any>. Constructors of consuming classes should instanciate C<obj> (with L<Moose> C<BUILDARGS> or C<BUILD>, see L<Moose::Manual::Construction>).

Any class consuming this role is required to implement a C<spread> method, which is called with three parameters: C<msg>, the message as a string to be spread; C<test>, an optional boolean which informs this method to actually spread the message if this parameter is C<false> (that should be the default), or to just test without spreading; and C<img>, an optional hash reference with the following keys: C<path> valued by a path to an image file, and C<alt> an alternate text for this image.

If the target needs authentication, it can be carried out in the constructor (with L<Moose> C<BUILDARGS> or C<BUILD>) or in the implementation of the C<spread> method, obviously before actually spreading the message.

There is a L<Bluesky|https://metacpan.org/pod/Bluesky> Perl module on CPAN that would have been the best choice of C<worker> for L<Bluesky|https://bsky.app/>. But it needs at least Perl v5.40.0, which is a requirement that most Perl installations does not meet yet. So we've included a very simple C<worker> L<App::SpreadRevolutionaryDate::BlueskyLite> in this distribution, based on L<post|https://betterprogramming.pub/building-a-perl-module-for-posting-to-bluesky-social-92fc732fc297> by William Shunn. It does not intend to extensively cover Blusky nor At (the protocol Bluesky is based on), just a way to connect and post a message to Bluesky.

=head1 SEE ALSO

=over

=item L<spread-revolutionary-date>

=item L<App::SpreadRevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::Config>

=item L<App::SpreadRevolutionaryDate::BlueskyLite>

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

=item L<App::SpreadRevolutionaryDate::MsgMaker::Gemini>

=back

=head1 AUTHOR

Gérald Sédrati <gibus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2025 by Gérald Sédrati.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
