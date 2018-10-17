# -*-cperl-*-
#
# Crypt::HashCash::Stash - Coin Stash for HashCash Digital Cash
# Copyright (c) 2001-2017 Ashish Gulhati <crypt-hashcash at hash.neo.tc>
#
# $Id: lib/Crypt/HashCash/Stash.pm v1.129 Tue Oct 16 16:56:38 PDT 2018 $

package Crypt::HashCash::Stash;

use warnings;
use strict;

use Crypt::HashCash::Coin;
use Crypt::HashCash::Client;
use vars qw( $VERSION $AUTOLOAD );

our ( $VERSION ) = '$Revision: 1.129 $' =~ /\s+([\d\.]+)/;

sub new {
  my ($class, %arg) = @_;
  my $dbfile = $arg{_DB} || '/tmp/stash.db';
  unlink $dbfile if $arg{Clobber} and $dbfile ne ':memory:';
  my $db = DBI->connect("dbi:SQLite:dbname=$dbfile", undef, undef, {AutoCommit => 1});
  my @tables = $db->tables('%','%','coins','TABLE');
  unless ($tables[0]) {
    if ($arg{Create}) {
      return undef unless $db->do('CREATE TABLE coins (
                                                       status text NOT NULL,
                                                       coinstr text UNIQUE NOT NULL
		                                      );');
      return undef unless $db->do('CREATE INDEX idx_coins_coinstr ON coins(coinstr);');
    }
    else {
      return undef;
    }
  }
  @tables = $db->tables('%','%','exported','TABLE');
  unless ($tables[0]) {
    if ($arg{Create}) {
      return undef unless $db->do('CREATE TABLE exported (
                                                       coinstr text UNIQUE NOT NULL,
                                                       timestamp int NOT NULL
		                                      );');
      return undef unless $db->do('CREATE INDEX idx_exported_coinstr ON exported(coinstr);');
    }
    else {
      return undef;
    }
  }
  @tables = $db->tables('%','%','savedbuys','TABLE');
  unless ($tables[0]) {
    if ($arg{Create}) {
      return undef unless $db->do('CREATE TABLE savedbuys (
                                                       address text UNIQUE NOT NULL,
                                                       amount int NOT NULL,
                                                       denoms text NOT NULL
		                                      );');
      return undef unless $db->do('CREATE INDEX idx_savedbuys_address ON savedbuys(address);');
    }
    else {
      return undef;
    }
  }
  bless { _DB => $db }, $class;
}

sub load {              # Load stash from DB
  my $self = shift;
  my $query = 'SELECT status,coinstr from coins;';
  my $coins = $self->db->selectall_arrayref($query);
  my ($balance, $balance_u) = (0, 0);
  for (grep { !/^_/ } keys %$self) { delete $self->{$_} }
  for (@$coins) {
    if (my $coin = Crypt::HashCash::Coin->from_string($_->[1])) {
      if ($coin->is_valid) {
	($_->[0] eq 'V' ? $balance : $balance_u) += $coin->d;
	push @{$self->{$coin->d}->{$_->[0]}}, $coin;
      }
    }
  }
  $self->balance($balance); $self->balance_u($balance_u);
}

sub getcoins {          # Return coins for a specific amount, and change amount if change needed
  my ($self, $amt) = @_;
  my @coins; my $bal = $self->balance;
  return if $amt > $self->balance;
  for (reverse @{$self->denoms}) {                                # Run through all denominations in descending order
    next unless exists $self->{$_}->{V};                          # Skip this denomination if no coins in stash
    $bal -= $_ * @{$self->{$_}->{V}}, next                        # Skip this denomination if > $amt and we don't need them
      if $_ > $amt and $bal - ($_ * @{$self->{$_}->{V}}) > $amt;
    while ($amt >= $_ and $self->{$_}->{V}) {                     # Get coins of this denom (=< $amt) till $amt < this denom
      unshift @coins, pop @{$self->{$_}->{V}};
      my $coinstr = $coins[0]->as_string;
      $self->db->do("DELETE from coins where status='V' and coinstr='$coinstr';");
      $self->db->do("DELETE from exported where coinstr='$coinstr';");
      $self->db->do("INSERT INTO exported values ('$coinstr','" . time . "');");
      delete $self->{$_}->{V} unless scalar @{$self->{$_}->{V}};
      $amt -= $_; $self->balance($self->balance - $_); $bal -= $_;
      last unless $amt > 0;
    }
    last unless $amt > 0;
    next unless $self->{$_}->{V};
    while ($bal - ($_ * (defined $self->{$_}->{V} ? scalar @{$self->{$_}->{V}} : 0)) < $amt) { # If lower denoms total is < $amt
      unshift @coins, pop @{$self->{$_}->{V}};                                                    # get more coins of this denom
      my $coinstr = $coins[0]->as_string;
      $self->db->do("DELETE from coins where status='V' and coinstr='$coinstr';");
      $self->db->do("DELETE from exported where coinstr='$coinstr';");
      $self->db->do("INSERT INTO exported values ('$coinstr','" . time . "');");
      delete $self->{$_}->{V} unless scalar @{$self->{$_}->{V}};
      $amt -= $_; $self->balance($self->balance - $_); $bal -= $_;
      last unless $amt > 0;
    }
    last unless $amt > 0;
    $bal -= $_ * @{$self->{$_}->{V}};                             # Done with coins of this denomination
  }
  for (@{$self->denoms}) {                                        # Delete any denom keys that we have no coins for
    next unless exists $self->{$_};
    delete $self->{$_} unless (defined $self->{$_}->{V} && scalar @{$self->{$_}->{V}}) or
      (defined $self->{$_}->{U} && scalar @{$self->{$_}->{U}})
    }
  return (\@coins, $amt);
}

sub addcoins {          # Add verified coins to stash
  my $self = shift;
  my $type = shift; return unless $type =~ /^[UV]$/;
  my $added;
  for my $coin (@_) {
    next unless ref $coin eq 'Crypt::HashCash::Coin';
    my $coinstr = $coin->as_string;
    my $exists = $self->db->selectall_arrayref("SELECT coinstr from coins where coinstr='$coinstr';")->[0];
    if ($exists || defined $self->{$coin->d} &&
	(defined $self->{$coin->d}->{V} && grep { $_->x == $coin->x } @{$self->{$coin->d}->{V}}) ||
	(defined $self->{$coin->d}->{U} && grep { $_->x == $coin->x } @{$self->{$coin->d}->{U}})) {
      $self->_diag("WARNING: Coin already in stash, not adding\n");
    }
    else {
      push @{$self->{$coin->d}->{$type}}, $coin;
      $self->db->do("INSERT INTO coins values ('$type', '$coinstr');");
      if ($type eq 'V') {
	$self->balance($self->balance + $coin->d);
      }
      else {
	$self->balance_u($self->balance_u + $coin->d);
      }
      $added++;
    }
  }
  $added;
}

sub havedenom {
  my ($self, $denom) = @_;
  defined $self->{$denom} and defined $self->{$denom}->{V}
}

sub getdenom {
  my ($self, $denom) = @_;
  return unless defined $self->{$denom} and defined $self->{$denom}->{V};
  my $coin = shift @{$self->{$denom}->{V}}; my $coinstr = $coin->as_string;
  $self->db->do("DELETE from coins where status='V' and coinstr='$coinstr';");
  $self->db->do("DELETE from exported where coinstr='$coinstr';");
  $self->db->do("INSERT INTO exported values ('$coinstr','" . time . "');");
  delete $self->{$denom}->{V} unless scalar @{$self->{$denom}->{V}};
  delete $self->{$denom} unless (defined $self->{$denom}->{V} && scalar @{$self->{$denom}->{V}}) or
    (defined $self->{$denom}->{U} && scalar @{$self->{$denom}->{U}});
  $coin;
}

sub unverified {
  my $self = shift;
  my @coins; my $denoms; my $amt;
  for (grep { !/^_/ } keys %$self) {
    next unless defined $self->{$_}->{U};
    push @coins, @{$self->{$_}->{U}};
    $amt += $_ * scalar @{$self->{$_}->{U}};
    $denoms->{$_} = @{$self->{$_}->{U}};
    delete $self->{$_}->{U};
    delete $self->{$_} unless defined $self->{$_}->{V} && scalar @{$self->{$_}->{V}};
  }
  for (@coins) {
    my $coinstr = $_->as_string;
    $self->db->do("DELETE from coins where status='U' and coinstr='$coinstr';");
    $self->db->do("DELETE from exported where coinstr='$coinstr';");
    $self->db->do("INSERT INTO exported values ('$coinstr','" . time . "');");
  }
  return ($amt, $denoms, @coins);
}

sub savebuy {
  my ($self, %arg) = @_;
  my $denoms = join ':', map { "$_:" . $arg{Denoms}->{$_} } keys %{$arg{Denoms}};
  $self->db->do("INSERT INTO savedbuys values ('$arg{Address}','$arg{Amt}','$denoms');");
}

sub savedbuys {
  my $self = shift;
  my $savedbuys = $self->db->selectall_arrayref("SELECT * from savedbuys;");
  return $savedbuys->[0] ? $savedbuys : undef;
}

sub finishbuy {
  my $self = shift;
  $self->db->do("DELETE from savedbuys where address='$_[0]';");
}

sub _diag {
  my $self = shift;
  print STDERR @_ if $self->debug;
}

sub AUTOLOAD {
  my $self = shift; (my $auto = $AUTOLOAD) =~ s/.*:://;
  return if $auto eq 'DESTROY';
  if ($auto =~ /^(debug|denoms|balance|balance_u)$/x and defined $_[0]) {
    $self->{"_\U$auto"} = shift;
  }
  elsif ($auto =~ /^(db|denoms|debug|balance|balance_u)$/x) {
    return $self->{"_\U$auto"};
  }
  else {
    die "Could not AUTOLOAD method $auto.";
  }
}

1;

__END__

=head1 NAME

Crypt::HashCash::Stash - Coin Stash for HashCash Digital Cash

=head1 VERSION

 $Revision: 1.129 $
 $Date: Tue Oct 16 16:56:38 PDT 2018 $

=head1 SYNOPSIS

  use Crypt::HashCash::Stash;

  my $stash = new Crypt::HashCash::Stash;

=head1 DESCRIPTION

This module implements a coin stash for the HashCash digital cash
system. It provides methods to get coins from and add coins to the
stash.

=head1 METHODS

=head2 new

Creates and returns a new Crypt::HashCash::Stash object.

=head2 load

=head2 getcoins

=head2 addcoins

=head2 havedenom

=head2 getdenom

=head2 unverified

=head2 savebuy

=head2 savedbuys

=head2 finishbuy

=head1 SEE ALSO

=head2 L<http://www.hashcash.com>

=head2 L<Crypt::HashCash>

=head2 L<Crypt::HashCash::Mint>

=head2 L<Crypt::HashCash::Client>

=head2 L<Crypt::HashCash::Coin>

=head2 L<Crypt::HashCash::Vault::Bitcoin>

=head2 L<Business::HashCash>

=head1 AUTHOR

Ashish Gulhati, C<< <crypt-hashcash at hash.neo.tc> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-crypt-hashcash at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-HashCash>. I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::HashCash::Stash

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-HashCash>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-HashCash>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-HashCash>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-HashCash/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) Ashish Gulhati.

This software package is Open Software; you can use, redistribute,
and/or modify it under the terms of the Open Artistic License 2.0.

Please see L<http://www.opensoftwr.org/oal20.txt> for the full license
terms, and ensure that the license grant applies to you before using
or modifying this software. By using or modifying this software, you
indicate your agreement with the license terms.
