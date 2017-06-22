# -*-cperl-*-
#
# Business::HashCash - Accept HashCash payments online
# Copyright (c) 2017 Ashish Gulhati <biz-hashcash at hash.neo.tc>
#
# $Id: lib/Business/HashCash.pm v1.003 Fri Jun 16 02:43:24 PDT 2017 $

package Business::HashCash;

use warnings;
use strict;

use Crypt::HashCash qw(_dec);
use Crypt::HashCash::Client;
use Crypt::HashCash::Stash;
use Crypt::HashCash::Coin;
use vars qw( $VERSION $AUTOLOAD );

our ( $VERSION ) = '$Revision: 1.003 $' =~ /\s+([\d\.]+)/;

sub new {
  my ($class, %arg) = @_;
  return undef unless my $client = new Crypt::HashCash::Client;
  bless { stash     => $arg{Stash},
	  vaults    => $arg{Vaults},
	  client    => $client
	}, $class;
}

sub verify {
  my ($self, $coinsin) = @_;
  my $client = $self->client; my $stash = $self->stash; my %fee = %{$client->keydb->{fees}};
  $coinsin =~ /^5b235d(52|45)([0-9a-f]{32})(.*)$/;
  my ($sigscheme, $vaultid, $coins, $amt, @coinstrs, @coins) = ($1, _dec($2), $3);
  my $coinsize = ($sigscheme == 52) ? 296 : 170;
  while (my $coinstr = substr($coins, 0, $coinsize, '')) { push @coinstrs, $coinstr }
  for (@coinstrs) {
    my $coin = Crypt::HashCash::Coin->from_hex($_);
    push @coins, $coin if $coin;
  }
  for my $coin (@coins) {
    return undef unless $client->verify_coin($coin);
  }
  my $numcoins = scalar @coins; my ($denoms, $d); # TODO: populate $denoms
  my $fee = $numcoins * ($fee{vf} + $fee{mf}) + int($amt * ($fee{mp} + $fee{vp}));
  $fee = $fee + ($client->denoms->[0] - ($fee % $client->denoms->[0]));
  return '-EFEE' if $fee > $self->stash->balance;
  return '-ELOSSYTX' if $fee >= $amt;
  my ($feecoins, $change) = $stash->getcoins($fee);
  my ($numchgcoins, $chgdenoms) = (0); ($chgdenoms, $numchgcoins) = breakamt(-$change) if $change;
  my %coins; for (@coins) { $coins{$_->d}++ }
  return '-EVAULT' unless my $res =
    $client->initexchange( Coins => \%coins,              # Denominations of coins being exchanged
			   ReqDenoms => $denoms,          # Denominations of coins being requested
			   ChangeDenoms => $chgdenoms,    # Denominations of change coins from fee payment
			   ReplaceDenoms => $d,           # Denominations of exchange coins replaced by change coins
			   FeeCoins => $feecoins );       # The fee coins
  return $res if $res =~ /^-E/;
  my @inits = split / /, $res; my $i = 0;
  my @requests;
  for my $denom (keys %{$denoms}) {
    for (1..$denoms->{$denom}) {
      push @requests, $client->request_coin( Denomination => $denom, Init => $inits[$i++] );
    }
  }
  my @changereqs;
  for my $denom (keys %{$chgdenoms}) {
    for (1..$chgdenoms->{$denom}) {
      push @changereqs, $client->request_coin( Denomination => $denom, Init => $inits[$i++] );
    }
  }
  my %feecoins; for (@$feecoins) { $feecoins{$_->d}++ }
  $res = $client->exchange( FeeCoins => \%feecoins, Coins => \@coins, Requests => \@requests, ChangeRequests => \@changereqs );
  return '-EVAULT' unless $res;
  return $res if $res =~ /^-E/;
  $res =~ s/\s*$//;
  my $vcoins = [ map { Crypt::HashCash::Coin::Blinded->from_string($_) } split / /, $res ];
  for (@$vcoins) {
    my $c = $client->unblind_coin($_);
    if ($client->verify_coin($c)) {
      $stash->addcoins('V',$c);
    }
  }
}

sub AUTOLOAD {
  my $self = shift; (my $auto = $AUTOLOAD) =~ s/.*:://;
  return if $auto eq 'DESTROY';
  if ($auto =~ /^(debug|client|stash)$/x) {
    $self->{$auto} = shift if (defined $_[0]);
    return $self->{$auto};
  }
  else {
    die "Could not AUTOLOAD method $auto.";
  }
}

=head1 NAME

Business::HashCash - Accept HashCash payments online

=head1 VERSION

 $Revision: 1.003 $
 $Date: Fri Jun 16 02:43:24 PDT 2017 $

=head1 SYNOPSIS

    use Business::HashCash;

    my $bizhc = new Business::HashCash (Stash => '/tmp/bizhc.db',
                                        Vaults => '/tmp/vaults');

    print 'Please input HashCash coins for $amount, and press <enter>';
    my $coins = readline(*STDIN);

    my $verified = $bizhc->verify($coins);

    print $verified ? "Thanks for your order.\n" : "Error: coins failed verification\n";

=head1 CONSTRUCTOR

=head2 new

=head1 METHODS

=head2 verify

=head1 AUTHOR

Ashish Gulhati, C<< <biz-hashcash at hash.neo.tc> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-business-hashcash at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-HashCash>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::HashCash

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-HashCash>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Business-HashCash>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Business-HashCash>

=item * Search CPAN

L<http://search.cpan.org/dist/Business-HashCash/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016-2017 Ashish Gulhati.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

See L<http://www.perlfoundation.org/artistic_license_2_0> for the full
license terms.
