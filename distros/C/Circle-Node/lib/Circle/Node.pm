package Circle::Node;

use 5.006;
use strict;
use warnings;
use Exporter 'import';
use Carp;
use Try::Tiny;
use URL::Encode;
use Circle::Common qw(load_config build_url_template http_json_post http_json_get);

our $VERSION = '0.02';

our @EXPORT = qw(
  subscribe
  serverFeatures
  broadcastTransaction
);

sub subscribe {
    my $url = build_url_template( "node", "subscribe" );
    return http_json_get($url);
}

sub serverFeatures {
    my $url = build_url_template( 'node', 'serverFeatures' );
    return http_json_get($url);
}

sub broadcastTransaction {
    my ($req) = @_;
    my $url = build_url_template( 'node', 'broadcastTransaction' );
    return http_json_post( $url, $req );
}

1;    # End of Circle::Node

__END__


=head1 NAME

Circle::Node - The Circle Chain's Node module.

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

    use Circle::Node;

    my $response = subscribe();
    ...

=head1 EXPORT

=over

=item subscribe

=item serverFeatures

=item broadcastTransaction

=back


=head1 SUBROUTINES/METHODS

=head2 subscribe

  my $response = subscribe();
  if ($response->{status} == 200) {
     my $data = $response->{data};
     # process data here.
  }

subscribe the circle chain server node and get the basic data of the node:

  {
    "baseHeight": 1000,
    "ipPortList": ["123.34.33.16:80"]
  }

=cut

=head2 serverFeatures

  my $response = serverFeatures();
  if ($response->{status} == 200) {
    my $data = $response->{data};
    # process the data here.
  }

serverFeatures api provides the server features:

  {
    "version": "1.0.0",
    "role": "CLOUDER",
    "protolVersion": "0.0.1",
    "publicIP": "123.32.22.12",
    "localIP": "192.168.1.10",
    "port": 80,
    "baseHeight": 1000,
    "publicKey": null
  }


=cut

=head2 broadcastTransaction

  my $response = broadcastTransaction({
    txid => '',
    type => 0,
    hash => '',
    version => 1,
    size => 100,
    vsize => 100,
    weight => 0,
    locktime => 0,
    vin => [
      {
        txid => '',
        vout => 0,
        scriptSig => {
          asm => '',
          hex => '',
        },
        txinwitness => [],
        sequence => 0,
        addresses => [''],
        value => '',
      }
    ],
    vout => [
      {
        value => '',
        n => 0,
        scriptPubKey => '',
      }
    ],
    blockhash => '',
    confirmations => 1,
    time => 1725885098000,
    blocktime => 1725887098000
  });
  if ($response->{status} == 200) {
    my $txid = $response->{data};
    # the transaction is broadcast.
  }


=cut

=head1 AUTHOR

charles li, C<< <lidh04 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-circle-node at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Circle-Node>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

See L<Circle::Common> for circle common module.

See L<Circle::User> for circle user module .

See L<Circle::Wallet> for circle wallet module.

See L<Circle::Block> for circle block module.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Circle::Node


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Circle-Node>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Circle-Node>

=item * Search CPAN

L<https://metacpan.org/release/Circle-Node>

=back


=head1 ACKNOWLEDGEMENTS

This module belongs to author C<lidh04@gmail>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by charles li.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut


