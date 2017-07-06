# -*-cperl-*-
#
# Crypt::HashCash::Mint - Mint for HashCash Digital Cash
# Copyright (c) 2001-2017 Ashish Gulhati <crypt-hashcash at hash.neo.tc>
#
# $Id: lib/Crypt/HashCash/Mint.pm v1.126 Sat Jun 24 02:15:18 PDT 2017 $

package Crypt::HashCash::Mint;

use 5.008001;
use warnings;
use strict;

use Crypt::RSA::Blind;
use Crypt::ECDSA::Blind;
use Compress::Zlib;
use Persistence::Object::Simple;
use vars qw( $VERSION $AUTOLOAD );
use DBI;

our ( $VERSION ) = '$Revision: 1.126 $' =~ /\s+([\d\.]+)/;

sub new {
  my $class = shift;
  my %arg = @_;
  my $self = bless { VERSION        =>   "Crypt::HashCash::Mint v$VERSION",
		     RSAB           =>   new Crypt::RSA::Blind,
		     ECDSAB         =>   new Crypt::ECDSA::Blind (Create => 1),
		     SIGSCHEME      =>   'ECDSA',
		     COMMENT        =>   '',
		     DEBUG          =>   $arg{Debug} || 0,
		     KEYSIZE        =>   1024,
		     KEYDB          =>   $arg{KeyDB} || '/tmp/vault.key',
		     DENOMS         =>   [qw(100 200 500 1000 2000 5000 10000 20000 50000 100000 200000
					     500000 1000000 2000000 5000000 10000000 20000000 50000000
					     100000000 200000000 500000000 1000000000)],
		     DB             =>   $arg{DB}
		   }, $class;
  return unless my $keydb = new Persistence::Object::Simple ('__Fn' => $self->keydb); $self->keydb($keydb);
  my $db = $self->db;
  unless ($db) {
    unlink $arg{SpentDB} if defined $arg{SpentDB} and $arg{SpentDB} ne ':memory:' and $arg{Clobber};
    return unless $db = DBI->connect("dbi:SQLite:dbname=$arg{SpentDB}", undef, undef, {AutoCommit => 1});
    $self->{DB} = $db;
  }
  my @tables = $db->tables('%','%','spent','TABLE');
  unless ($tables[0]) {
    if ($arg{Create}) {
      return undef unless $db->do('CREATE TABLE spent (id text NOT NULL,
                                                       denom int NOT NULL,
		                                       spent int NOT NULL
		                                      );');
      return undef unless $db->do('CREATE INDEX idx_spent_id ON spent(id);');
    }
    else {
      return undef;
    }
  }
  return $self;
}

sub keygen {
  my $self = shift;
  $self->_diag("MINT: keygen\n");
  my (%skey, %pkey);
  for (@{$self->denoms}) {
    $self->_diag("MINT: keygen for denom $_\n");
    my ($pk, $sk) = $self->signer->keygen (
					   Identity  => "HashCash $_",
					   Size      => $self->keysize,
					   Verbosity => $self->debug,
					  ) or die "Error creating key for denomination $_";
      $skey{$_} = $sk; $pkey{$_} = $pk;
      $self->keydb->{sec}->{$_} = $sk->as_hex; $self->keydb->{pub}->{$_} = $pk->as_hex;
  }
  $self->keydb->commit;
  $self->skeys(\%skey); $self->pkeys(\%pkey);
}

sub loadkeys {
  my $self = shift;
  $self->_diag("MINT: loadkeys\n");
  my (%skey, %pkey);
  my $sigmod = 'Crypt::' . $self->sigscheme . '::Blind';
  no strict 'refs';
  for (@{$self->denoms}) {
    $skey{$_} = &{$sigmod.'::SecKey::from_hex'}($self->keydb->{sec}->{$_});
    $pkey{$_} = &{$sigmod.'::PubKey::from_hex'}($self->keydb->{pub}->{$_});
  }
  $self->skeys(\%skey); $self->pkeys(\%pkey);
}

sub init {
  my $self = shift;
  $self->_diag("MINT: init\n");
  $self->signer->init;
}

sub mint_coin {
  my ($self,$req) = @_;
  return unless $req; return unless defined $self->skeys->{$req->{D}};
  $self->_diag ("MINT: mint_coin\nD: $req->{D}\n");
  return unless my $coin = $self->signer->sign(Key => $self->skeys->{$req->{D}}, Message => $req->{R}, Init => $req->{Init});
  $self->_diag ("req: $req->{R}\ncoin: $coin\n");
  return ( bless { C => "$coin", D => $req->{D}, Init => $req->{Init} }, 'Crypt::HashCash::Coin::Blinded' );
}

sub verify_coin {
  my ($self, $coin) = @_;
  return unless ref $coin eq 'Crypt::HashCash::Coin' and defined $self->pkeys->{$coin->{D}};
  $self->_diag ("MINT: verify_coin\ncoin: $coin->{Z}\nX: $coin->{X}\nD: $coin->{D}\n");
  # Check if coin already spent, and if signature is valid
  return 0 if $self->db->selectcol_arrayref("SELECT spent from spent WHERE id='$coin->{X}' and denom='$coin->{D}';")->[0];
  return 0 unless $self->signer->verify(Key => $self->pkeys->{$coin->{D}}, Signature => $coin->{Z}, Message => $coin->{X});
  # Valid, unspent coin
  return 1;
}

sub spend_coin {
  my ($self, $coin) = @_;
  return unless ref $coin eq 'Crypt::HashCash::Coin' and $coin->is_valid and defined $self->pkeys->{$coin->{D}};
  $self->_diag ("MINT: spend_coin\ncoin: $coin->{Z}\nX: $coin->{X}\nD: $coin->{D}\n");
  my $timestamp = time;
  $self->db->begin_work;
  # First check if coin already spent, so we don't waste time verifying if double-spend
  $self->db->rollback, return 0 if $self->db->selectcol_arrayref("SELECT spent from spent WHERE id='$coin->{X}' and denom='$coin->{D}';")->[0];
  # Unspent coin, add to DB
  $self->db->do("INSERT INTO spent values ('$coin->{X}', '$coin->{D}', '$timestamp');");
  # Verify coin
  $self->db->rollback, return 0 unless $self->signer->verify(Key => $self->pkeys->{$coin->{D}}, Signature => $coin->{Z}, Message => $coin->{X});
  $self->db->commit;
  return 1;
}

sub unspend_coin {
  my ($self, $coin) = @_;
  return unless ref $coin eq 'Crypt::HashCash::Coin' and $coin->is_valid and defined $self->pkeys->{$coin->{D}};
  $self->_diag ("MINT: unspend_coin\ncoin: $coin->{Z}\nX: $coin->{X}\nD: $coin->{D}\n");
  $self->db->do("DELETE from spent WHERE id='$coin->{X}' and denom='$coin->{D}';");
}

sub _diag {
  my $self = shift;
  print STDERR @_ if $self->debug;
}

sub AUTOLOAD {
  my $self = shift; (my $auto = $AUTOLOAD) =~ s/.*:://;
  return if $auto eq 'DESTROY';
  if ($auto =~ /^((s|p)keys|rsab|ecdsab|keysize|debug|version|comment|spentdb|keydb|units|sigscheme)$/x) {
    $self->{"\U$auto"} = shift if (defined $_[0]);
  }
  if ($auto =~ /^((s|p)keys|rsab|ecdsab|keysize|debug|version|comment|spentdb|keydb|units|denoms|db|sigscheme)$/x) {
    return $self->{"\U$auto"};
  }
  if ($auto eq 'signer') {
    $self->sigscheme eq 'RSA' ? $self->rsab : $self->ecdsab;
  }
  else {
    die "Could not AUTOLOAD method $auto.";
  }
}

sub Crypt::RSA::Key::Private::as_hex {
  unpack('H*', compress(shift->serialize));
}

sub Crypt::RSA::Key::Public::as_hex {
  unpack('H*', compress(shift->serialize));
}

1;

__END__

=head1 NAME

Crypt::HashCash::Mint - Mint for HashCash Digital Cash

=head1 VERSION

 $Revision: 1.126 $
 $Date: Sat Jun 24 02:15:18 PDT 2017 $

=head1 SYNOPSIS

  use Crypt::HashCash::Mint;

  my $mint = new Crypt::HashCash::Mint ( Create => 1 );

  $mint->sigscheme('ECDSA');                   # Use ECDSA blind signatures
  $mint->keygen;                               # Create a new mint keypair
  $mint->loadkeys;                             # Load saved mint keys

  my $init = $mint->init;                      # Initialize coin request
  my $bcoin = $mint->mint_coin($request);      # Mint a blinded coin
  print "OK\n" if $mint->verify_coin($coin);   # Verify a coin
  print "Spent\n" if $mint->spend_coin($coin); # Spend a coin

=head1 DESCRIPTION

This module implements a mint for the HashCash digital cash system. It
provides methods to mint blinded coins, and to verify and spend
HashCash coins.

=head1 METHODS

=head2 new

Creates and returns a new Crypt::HashCash::Mint object.

=head2 keygen

Generates and saves blind signing keys for all coin denominations.

=head2 loadkeys

Loads saved mint keys from disk.

=head2 init

Returns an initialization vector for coin minting.

=head2 mint_coin

Mints and returns a blinded coin. Takes a single argument, the coin
request.

=head2 verify_coin

Verifies the coin provided as the only argument, and returns true if
the coin verified successfully, or false if it didn't. This method
doesn't add the coin to the spent coins database.

=head2 spend_coin

Spends the coin provided as the only argument, and returns true if the
coin was spent successfully, or false if it wasn't. This method adds
the coin to the spent coins database.

=head2 unspend_coin

Unspends the coin provided as the only argument. Returns undef if
there was an error in the argument, 0 if the coin wasn't in the spent
DB, or 1 if it was successfully unspent.

=head1 SEE ALSO

=head2 L<http://www.hashcash.com>

=head2 L<Crypt::HashCash>

=head2 L<Crypt::HashCash::Client>

=head2 L<Crypt::HashCash::Coin>

=head2 L<Crypt::HashCash::Vault::Bitcoin>

=head2 L<Business::HashCash>

=head1 AUTHOR

Ashish Gulhati, C<< <crypt-hashcash at hash.neo.tc> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-crypt-hashcash at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-HashCash>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::HashCash::Mint

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

Copyright (c) 2001-2017 Ashish Gulhati.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

See http://www.perlfoundation.org/artistic_license_2_0 for the full
license terms.
