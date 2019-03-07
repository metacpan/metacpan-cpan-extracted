#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019 by Gérald Sédrati-Dinet.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
package App::SpreadRevolutionaryDate::Freenode;
$App::SpreadRevolutionaryDate::Freenode::VERSION = '0.06';
# ABSTRACT: Subclass of L<App::SpreadRevolutionaryDate> to handle spreading on Freenode.

use App::SpreadRevolutionaryDate::Freenode::Bot;


sub new {
  my $class = shift;
  my $config = shift;
  bless {config => $config}, $class;
}


sub spread {
  my $self = shift;
  my $msg = shift;
  my $no_run = shift || 0;

  my $port = 6667;
  my $ssl = 0;

  # Switch to SSL if module POE::Component::SSLify is available
  if (eval { require POE::Component::SSLify; 1 }) {
    $port = 6697;
    $ssl = 1;
  }

  my $channels = $self->{config}->test ? $self->{config}->freenode_test_channels : $self->{config}->freenode_channels;

  my $freenode = App::SpreadRevolutionaryDate::Freenode::Bot->new(
    server            => 'irc.freenode.net',
    port              => $port,
    nick              => 'RevolutionaryDate',
    alt_nicks         => ['RevolutionaryCalendar', 'RevolutionarybBot'],
    name              => 'Revolutionary Calendar bot',
    flood             => 1,
    useipv6           => 1,
    ssl               => $ssl,
    charset           => 'utf-8',
    channels          => $channels,
    freenode_nickname => $self->{config}->freenode_nickname,
    freenode_password => $self->{config}->freenode_password,
    msg               => $msg,
    no_run            => $no_run,
  )->run();
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SpreadRevolutionaryDate::Freenode - Subclass of L<App::SpreadRevolutionaryDate> to handle spreading on Freenode.

=head1 VERSION

version 0.06

=head1 METHODS

=head2 new

Constructor class method, subclassing C<Bot::BasicBot>. Takes one mandatory argument: C<$config> which should be an C<App::SpreadRevolutionaryDate::Config> object. Returns an C<App::SpreadRevolutionaryDate::Freenode> object.

=head2 spread

Spreads a message to Freenode channels configured with the multivalued option C<channels>. Takes one mandatory argument: C<$msg> which should be the message to spread as a characters string. If C<test> option is set the message is spreaded on channels configured with the multivalued option C<test_channels>. Takes also one optional boolean argument, if true (default) authentication and spreading to Freenode is performed, otherwise, you've got to run C<use POE; POE::Kernel->run();> to do so. This is only used for testing, when multiple bots are needed. You can safely leave this optional argument unset.

=head1 SEE ALSO

=over

=item L<spread-revolutionary-date|https://metacpan.org/pod/distribution/App-SpreadRevolutionaryDate/bin/spread-revolutionary-date>

=item L<App::SpreadRevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::Config>

=item L<App::SpreadRevolutionaryDate::Twitter>

=item L<App::SpreadRevolutionaryDate::Mastodon>

=item L<App::SpreadRevolutionaryDate::Freenode::Bot>

=back

=head1 AUTHOR

Gérald Sédrati-Dinet <gibus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Gérald Sédrati-Dinet.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
