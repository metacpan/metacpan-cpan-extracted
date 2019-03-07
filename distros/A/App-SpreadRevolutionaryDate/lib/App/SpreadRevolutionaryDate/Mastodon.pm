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
package App::SpreadRevolutionaryDate::Mastodon;
$App::SpreadRevolutionaryDate::Mastodon::VERSION = '0.06';
# ABSTRACT: Subclass of L<App::SpreadRevolutionaryDate> to handle spreading on Mastodon.

use Mastodon::Client;


sub new {
  my $class = shift;
  my $config = shift;
  my $mastodon = Mastodon::Client->new(
                  instance        => $config->mastodon_instance,
                  client_id       => $config->mastodon_client_id,
                  client_secret   => $config->mastodon_client_secret,
                  access_token    => $config->mastodon_access_token,
                  #coerce_entities => 1,
                  name            => 'RevolutionaryDate');
  bless {config => $config, obj => $mastodon}, $class;
}


sub spread {
  my $self = shift;
  my $msg = shift;
  if ($self->{config}->test) {
    print "Spread to Mastodon $msg\n";
  } else {
    $self->{obj}->post_status($msg);
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SpreadRevolutionaryDate::Mastodon - Subclass of L<App::SpreadRevolutionaryDate> to handle spreading on Mastodon.

=head1 VERSION

version 0.06

=head1 METHODS

=head2 new

Constructor class method. Takes one mandatory argument: C<$config> which should be an C<App::SpreadRevolutionaryDate::Config> object. Authentifies to Mastodon and returns an C<App::SpreadRevolutionaryDate::Mastodon> object.

=head2 spread

Spreads a message to Mastodon. Takes one mandatory argument: C<$msg> which should be the message to spread as a characters string. If C<test> option is set the message is printed on standard output and not spread on Mastodon.

=head1 SEE ALSO

=over

=item L<spread-revolutionary-date|https://metacpan.org/pod/distribution/App-SpreadRevolutionaryDate/bin/spread-revolutionary-date>

=item L<App::SpreadRevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::Config>

=item L<App::SpreadRevolutionaryDate::Twitter>

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
