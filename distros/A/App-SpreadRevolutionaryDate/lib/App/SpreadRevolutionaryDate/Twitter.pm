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
package App::SpreadRevolutionaryDate::Twitter;
$App::SpreadRevolutionaryDate::Twitter::VERSION = '0.06';
# ABSTRACT: Subclass of L<App::SpreadRevolutionaryDate> to handle spreading on Twitter.

use Net::Twitter::Lite::WithAPIv1_1;
use Net::OAuth 0.25;


sub new {
  my $class = shift;
  my $config = shift;
  my $twitter = Net::Twitter::Lite::WithAPIv1_1->new(
                  consumer_key        => $config->twitter_consumer_key,
                  consumer_secret     => $config->twitter_consumer_secret,
                  access_token        => $config->twitter_access_token,
                  access_token_secret => $config->twitter_access_token_secret,
                  user_agent          => 'RevolutionaryDate',
                  ssl                 => 1);
  bless {config => $config, obj => $twitter}, $class;
}


sub spread {
  my $self = shift;
  my $msg = shift;
  if ($self->{config}->test) {
    print "Spread to Twitter: $msg\n";
  } else {
    $self->{obj}->update($msg);
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SpreadRevolutionaryDate::Twitter - Subclass of L<App::SpreadRevolutionaryDate> to handle spreading on Twitter.

=head1 VERSION

version 0.06

=head1 METHODS

=head2 new

Constructor class method. Takes one mandatory argument: C<$config> which should be an C<App::SpreadRevolutionaryDate::Config> object. Authentifies to Twitter and returns an C<App::SpreadRevolutionaryDate::Twitter> object.

=head2 spread

Spreads a message to Twitter. Takes one mandatory argument: C<$msg> which should be the message to spread as a characters string. If C<test> option is set the message is printed on standard output and not spread on Twitter.

=head1 SEE ALSO

=over

=item L<spread-revolutionary-date|https://metacpan.org/pod/distribution/App-SpreadRevolutionaryDate/bin/spread-revolutionary-date>

=item L<App::SpreadRevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::Config>

=item L<App::SpreadRevolutionaryDate::Mastodon>

=item L<App::SpreadRevolutionaryDate::Freenode>

=item L<App::SpreadRevolutionaryDate::Freenode::Bot>

=back

=head1 AUTHOR

Gérald Sédrati-Dinet <gibus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Gérald Sédrati-Dinet.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
