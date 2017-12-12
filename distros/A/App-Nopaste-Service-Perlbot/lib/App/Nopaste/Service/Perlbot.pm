use strict;
use warnings;
package App::Nopaste::Service::Perlbot;
# ABSTRACT: Service provider for perlbot.pl - https://perlbot.pl/

our $VERSION = '0.004';

use parent 'App::Nopaste::Service';
use JSON::PP qw/decode_json/;

sub run {
    my ($self, %arg) = @_;
    my $ua = LWP::UserAgent->new;

    if ($arg{chan} eq 'list') {
      my $res = $ua->get( 'https://perl.bot/api/v1/channels');
     
      unless ($res->is_success) {
        return (0, "Failed to get channels, try again later.\n");
      }

      my $response = decode_json $res->decoded_content;

      my $output="Channels supported by perl.bot, all values subject to change.\n-----------------------------------\n";
      for my $channel (@{$response->{channels}}) {
          $output .= sprintf "%15s  %20s\n", $channel->{name}, $channel->{description};
      }

       return (1, $output);

    } else {

      my $res = $ua->post("https://perl.bot/api/v1/paste", {
          paste => $arg{text},
          description => $arg{desc} || 'I broke this',
          username => $arg{nick} || 'Anonymous',
          $arg{chan} ? (chan => $arg{chan}) : (),
          language => $arg{lang} || 'text'
      });

      if ($res->is_success()) {
          my $content = $res->decoded_content;
          my $data = decode_json $content;

          return (1, $data->{url});
      } else {
          return (0, "Paste failed");
      }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Nopaste::Service::Perlbot - Service provider for perl.bot - https://perl.bot/

=head1 COMMANDS

-c list - will list all available channels

=head1 AUTHOR

Ryan Voots L<simcop@cpan.org|mailto:simcop@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

