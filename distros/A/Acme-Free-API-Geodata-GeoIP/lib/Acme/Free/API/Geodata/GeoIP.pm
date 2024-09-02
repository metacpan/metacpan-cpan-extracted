package Acme::Free::API::Geodata::GeoIP;

use v5.38;
use strict;
use warnings;
use utf8;

our $VERSION = '1.0';

use Data::Dumper;
use WWW::Mechanize;
use JSON::XS qw(decode_json);

sub new($proto, %config) {
    my $class = ref($proto) || $proto;

    my $self = bless \%config, $class;

    my $agent = WWW::Mechanize->new(cookie_jar => {});
    $agent->agent('PerlMonks contest/1 (https://perlmonks.org/?node_id=11161472)');
    $agent->stack_depth(1);
    $self->{agent} = $agent;

    if(!defined($self->{debug})) {
        $self->{debug} = 0;
    }

    return $self;
}

sub lookup($self, $ip) {
    my $url = "http://ip-api.com/json/" . $ip;

    my $content = $self->_fetchURL($url);

    my $ok = 0;
    my $decoded;
    eval {
        $decoded = decode_json($content);
        $ok = 1;
    };

    if(!$ok || !defined($decoded)) {
        $self->_debuglog("Failed to decode response. Not a JSON document?");
        $self->_debuglog(Dumper($decoded));
        return;
    }

    #$self->_debuglog(Dumper($decoded));

    return $decoded;
}



# internal helpers
# these are copied from CAVACs vast framework. But we don't want hundreds of dependencies in this example code, only a couple of functions
sub _fetchURL($self, $url) {
    $self->{agent}->get($url);

    if(!$self->{agent}->success()) {
        $self->_debuglog("Network error while fetching URL $url");
        return;
    }

    my $response = $self->{agent}->response();
    if(!defined($response)) {
        $self->_debuglog("Could not get agent response");
        return;
    }

    my $content = $response->decoded_content;
    if(!defined($content) || !length($content)) {
        $self->_debuglog("Could not get response content");
        return;
    }

    #$self->_debuglog(Dumper($content));

    return $content;

}

sub _debuglog($self, $message) {
    if(!$self->{debug}) {
        return;
    }
    print STDERR $message, "\n";
}


1;
__END__

=head1 NAME

Acme::Free::API::Geodata::GeoIP - Lookup GeoIP data for an IP address

=head1 SYNOPSIS

  use Acme::Free::API::Geodata::GeoIP;
  
  my $agent = Acme::Free::API::Geodata::GeoIP->new(debug => 1);

  my $geodata = $agent->lookup('24.48.0.1');

  if(!defined($geodata)) {
      die("Lookup failed");
  }

  print "$ip is hosted by ", $geodata->{org}, " in ", $geodata->{city}, " (", $geodata->{country}, ")\n";

=head1 DESCRIPTION

This module looks up GeoIP data through a public API, see L<https://www.freepublicapis.com/ip-geolocation-api>.

It returns a hashref on success, undefined on failure. To see what went wrong, set debug to a true value in new().

=head1 SEE ALSO

Call for API implementations on PerlMonks: L<https://perlmonks.org/?node_id=11161472>

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=head1 SOURCECODE

Source code is available on my mercurial repo: L<https://cavac.at/public/mercurial/Acme-Free-API-Geodata-GeoIP/>

And no, i do NOT use GitHub for my projects, so don't ask.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.38.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
