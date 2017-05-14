package Crypt::PBC::WIBE;
# ABSTRACT: Crypt::PBC::WIBE - Wildcarded Identity-based Encryption Scheme

use strict;
use warnings;
use Carp;
use Crypt::PBC;

use constant DEFAULT_PAIRING_A => <<EOF;
type a
q 8780710799663312522437781984754049815806883199414208211028653399266475630880222957078625179422662221423155858769582317459277713367317481324925129998224791
h 12016012264891146079388821366740534204802954401251311822919615131047207289359704531102844802183906537786776
r 730750818665451621361119245571504901405976559617
exp2 159
exp1 107
sign1 1
sign0 1
EOF

=pod

=encoding utf8

=head1 NAME

Crypt::PBC::WIBE - Implementation of the Boneh-Gentry-Goh Wildcarded Identity-based Encryption scheme.

=head1 SYNOPSIS

    use Crypt::PBC::WIBE;

    # Create a new instance, generate public, master secret key
    my $wibe = new Crypt::PBC::WIBE( L => 2 );

    # Derive Key for Alice, Bob
    my $alice = $wibe->derive(1);
    my $bob = $wibe->derive(2);

    # Derive Subkey (notice: same ID!) for friend of alice
    my $carol = $alice->derive(1);

    # Recap: Alice now has the ID vector [1]
    # and carol (friend of alice) has [1,1]

    # Pattern: Allow all friends (*)
    my $pattern = ['*'];

    # Create a random element from Crypt::PBC
    my $msg = $wibe->pairing->init_GT->random;

    my $cipher = $wibe->encrypt_element($pattern, $msg);

    die "Alice should be able to decrypt"
    unless $alice->decrypt_element($cipher)->is_eq($msg);

    die "Carol must be unable to decrypt"
    if $carol->decrypt_element($cipher)->is_eq($msg);


=head1 OVERVIEW

This module provides an implementation to the Boneh–Boyen–Goh Wildcarded Identity-Based Encryption scheme
as proposed by Abdalla et al., as appeared in I<Journal of Cryptology: Volume 24, Issue 1 , pp 42-82.>.

This implementation relies on the PBC library and thus, its Perl bindings L<Crypt::PBC>.

=head1 DISCLAIMER

This module is part of a prototype implementation of the Boneh-Gentry-Goh WIBE.
While it works fine in my tests, I advise against using it for anything productive other than experimental work.

I appreciate your input on anything you might encounter while using this module.

=head1 METHODS

The exposed methods described below follow the four algorithms from the paper closely.

=head2 new

Returns a WIBE instance. C<new()> expects a parameter hash with at least the
following pair set:

=over 4

=item L

Pattern length / Maximum hierarchy of the encryption scheme.

=back

and the following optional keys:

=over 4

=item pairing

A Type-A pairing. Passed directly to L<Crypt::PBC::new()|Crypt::PBC/"Crypt::PBC::new">.
May be a pairing string, filehandle or filename.

=item SK, MPK

Secret and Public Key of the system. If not set, they
are generated through C<setup()>.

=back

=cut
sub new {
    my $class = shift;
    my %options = @_;

    croak("Missing parameter 'L' from parameters.")
    unless defined $options{L};

    croak("Invalid parameter 'L', must be an integer > 0.")
    unless ($options{L} > 0);

    my $self = bless {
            L => $options{L},
            pairing => new Crypt::PBC($options{pairing} || DEFAULT_PAIRING_A),
        }, $class;

    # Use existing keys if set.
    $self->{$_} = $options{$_} for (qw(SK MPK DSK));

    # If MPK is missing, we assume a new instance, generate keys.
    unless (defined $self->{MPK}) {
        $self->setup;
    }

    # Generate my own decryption key for patterns l+1
    # By convention, we use ID=0 as the identifier for 'self'.
    #
    # I.e., Alice with ID=1 derives a key for [1,0],
    # so that she may decrypt a pattern of length 2.
    $self->{SK} = $self->key_derive(0)
    unless (defined $self->{SK});

    return $self;
}

=head2 pairing

Returns the Type-A pairing used in this WIBE instance.

See L<Crypt::PBC/"Pairing-Functions">.

=cut
sub pairing {
    return shift->{pairing};
}

=head2 setup

Generates the I<mpk> (public key) and I<msk> (master secret key)
of the WIBE system and stores them in the WIBE instance.

=cut
sub setup {
    my ($self) = @_;

    # mpk = (g_1, g_2, h_1, u_0, .. , u_L)
    my ($mpk, $msk);

    # Choose random g_1, g_2 from G
    $mpk->{g1} = $self->{pairing}->init_G1->random;
    $mpk->{g2} = $self->{pairing}->init_G1->random;
    
    # Choose random alpha from Zp
    my $alpha = $self->{pairing}->init_Zr->random;
    
    # Compute h_1 as g_1^(alpha)
    $mpk->{h1} = $self->{pairing}->init_G1->pow_zn($mpk->{g1}, $alpha);
    
    # Choose random u_i for i = 0, .. , L
    for(my $i = 0; $i <= $self->{L}; $i++) {
        $mpk->{u}->[$i] = $self->{pairing}->init_G1->random;
    }

    # Initialize msk
    # msk = (d_0, d_1, ..., d_L, d_L+1)

    # Set d_0 to g_2 ^ alpha
    $msk->{key}->[0] = $self->{pairing}->init_G1;
    $msk->{key}->[0]->pow_zn($mpk->{g2}, $alpha);

    # Initialize all elements of msk as 1 in G
    for(my $i = 1; $i < $self->{L} + 2; $i++) {
        $msk->{key}->[$i] = $self->{pairing}->init_G1->set1;
    }
    

    # ID ids is empty, as this is the master
    $msk->{ids} = [];

    $self->{DSK} = $msk;
    $self->{MPK} = $mpk;

}

=head2 derive

Returns a WIBE instance for a derived ID element.

Required Parameters:

=over 4

=item next_id

Next Identifier element in the hierarchy.

=back

This serves as a shortcut for the following steps:

=over 4

=item 1.

Create a derived key C<<SK[ID0, ... , IDi, next_id] = $self->key_derive(next_id)>>.

=item 2.

Create a new WIBE instance with the same public key and the derived secret key C<SK[ID0, .., IDi+1]>

=item 3.

Returns that instance.

=back

=cut
sub derive {
    my ($self, $next_id) = @_;

    # Derive the new key
    my $derived_key = $self->key_derive($next_id);

    # Pass that key, along with MPK, to a new instance
    my $options = { map { $_ => $self->{$_} } (qw(L MPK)) };

    # If the instance ID vector is = L, it is a leaf,
    # thus it may no longer derive keys.
    # We denote that key as SK.

    if ($self->{L} == scalar(@{$derived_key->{ids}})) {
        $options->{SK} = $derived_key;
    } else {
        # Otherwise, the key is derivable (denoted as DSK).
        $options->{DSK} = $derived_key;
    }

    return Crypt::PBC::WIBE->new(%$options);
}

=head2 key_derive

Derive a key for the given ID element
using the derivable secret key I<(DSK)> of this instance.

Parameters:

=over 4

=item id

Next Identifier element in the hierarchy.

=back

Returns the derived key of size (sk - 1),
which is a simple hash with the following keys:

=over 4

=item key

The element_t secret key for the derived ID.

=item ids

Hierarchy of the secret key.

=back

B<Example:>

=over 4

=item *

Alice derives an identity 1 (Zp) for Bob
using the Master Key. (size |L| + 2)

=item *

Bob receives a secret key of size |L| + 1
and its identity.

=item *
Bob derives an identity 0 (Zp) for Bob
(i.e., the self key).

Bob can decrypt for Pattern [1,*] or [1,0].

=back

=cut
sub key_derive {
    my ($self, $ID) = @_;

    # Use the DSK unless key is set
    croak("Cannot derive key without DSK.")
    unless defined $self->{DSK};

    croak("ID must be an integer >= 0")
    unless ($ID =~ qr/^\d+$/ && $ID >= 0);

    # Load next ID element in Zp
    my $ID_el = $self->{pairing}->init_Zr->set_to_int($ID);

    # l = Current ID vector length
    my $l = scalar(@{ $self->{DSK}->{ids} });
    # Length of DSK
    my $keylen = scalar(@{ $self->{DSK}->{key} });
    # Length of derived key = l - 1
    my $derived_keylen = $keylen - 1;

    # secret key = (d_0, d_l+1, ..., d_L, d_L+1)
    # new key   = (d_0', d_l+2', ...,  d_L, d_L+1)
    my $derived;
    
    # Initialize all elements of the derived key in G
    for(my $i = 0; $i < $derived_keylen; $i++) {
        $derived->[$i] = $self->{pairing}->init_G1;
    }

    # Compute IDs
    my $derived_ids = [ @{$self->{DSK}->{ids}}, $ID];

    # Initialize r as random from Zp
    my $r = $self->{pairing}->init_Zr->random;
    my $temp = $self->{pairing}->init_G1;

    # Compute d_0'
    $derived->[0]->set($self->{MPK}->{u}->[0]);
    my $id_i = $self->{pairing}->init_Zr;
    
    for(my $i = 0; $i < $l + 1; $i++) {
        $id_i->set_to_int($derived_ids->[$i]);
        # multiply with u_i ^ ID_i-1
        $temp->pow_zn($self->{MPK}->{u}->[$i+1], $id_i);
        $derived->[0]->mul($temp);
    }
    
    # Lastly pow with r
    $derived->[0]->pow_zn($r);

    # compute d_l+1 ^ ID_l+1
    $temp->set($self->{DSK}->{key}->[1]);
    $temp->pow_zn($ID_el);
    
    # Multiply with temp
    $derived->[0]->mul($temp);
    
    # Multiply with d_0
    $derived->[0]->mul($self->{DSK}->{key}->[0]);
    
    # Compute d_i' for i=1,..,len-2 of derived key
    for (my $i = 2; $i < $keylen - 1; $i++) {

        # Set d_i' to d_(i) * u_(l+i) ^ r
        # multiply with u_(l+i)
        $derived->[$i - 1]->pow_zn($self->{MPK}->{u}->[$l + $i], $r);
        $derived->[$i - 1]->mul($self->{DSK}->{key}->[$i]);
    }
    
    # Finally, compute d_L+1' as (g_1 ^ r) * d_L+1
    $derived->[$derived_keylen - 1]->pow_zn($self->{MPK}->{g1}, $r);
    $derived->[$derived_keylen - 1]->mul($self->{DSK}->{key}->[$keylen - 1]);

    return {
        ids => $derived_ids,
        key => $derived
    };
}

=head2 encrypt_element

Perform an encryption for an element in G1 using the WIBE scheme.

This key may later be expanded using HKDF and used in a symmetric AE scheme
as a hybrid encryption scheme.

Parameters:

=over 4

=item Pattern

An arrayref of size L with one of:
    1.) C<'*'>, wildcard. Can be derived by any containing the parent pattern
    2.) An Identifier (int >= 0). Derived only by the owner of that identifier.

B<Example>: For L=2, possible patterns are:

=over 4

=item *

C<['*','*']>: Decrypt possible with patterns matching C<'X.*'> or C<'X.Y'> for any C<X>.

=item *

C<['X','*']>: Decrypt possible for X and any subkeys of id C<X>.

=item *

C<['X', 0 ]>: Decrypt possible for subkey 0 of C<X>, which by convention is C<X.self>.

=back

=item m

An element of G1 to encrypt.

=back

The resulting ciphertext of the encryption is a hashref.

=cut
sub encrypt_element {
    my ($self, $pattern, $m) = @_;

    croak("Pattern must be of length <= " . $self->{L})
    unless (scalar(@$pattern) <= $self->{L});

    for my $id (@$pattern) {
        croak("Pattern must only either an * or an integer >= 0")
        unless ($id eq '*' || $id >= 0);
    }

    croak("Cannot encrypt without a public key.")
    unless defined $self->{MPK};

    # cipher = (P, C1, C2, C3, C4)
    my $cipher;

    $cipher->{P} = $pattern;
    
    my $r = $self->{pairing}->init_Zr->random;
    
    # Initialize C1 as g_1 ^ r
    $cipher->{C1} = $self->{pairing}->init_G1;
    $cipher->{C1}->pow_zn($self->{MPK}->{g1}, $r);

    # Compute C2 and C4
    $cipher->{C2} = $self->{pairing}->init_G1;
    $cipher->{C2}->set($self->{MPK}->{u}->[0]);
    # C4 denotes a vector of length |pattern|
    
    my $temp = $self->{pairing}->init_G1;
    my $p_i = $self->{pairing}->init_Zr;
    for (my $i = 0; $i < scalar(@$pattern); $i++) {
        if ($pattern->[$i] eq '*') {
            # Set C4[i] to u_i ^ r
            $cipher->{C4}->[$i] = $self->{pairing}->init_G1;
            $cipher->{C4}->[$i]->pow_zn($self->{MPK}->{u}->[$i+1], $r);
        } else {
            # that is not a wildcard
            $p_i->set_to_int($pattern->[$i]);
            $temp->pow_zn($self->{MPK}->{u}->[$i+1], $p_i);
            $cipher->{C2}->mul($temp);
        }
    }
    
    # Finalize C2 as C2 ^ r
    $cipher->{C2}->pow_zn($r);
    
    # Compute C3 as m * e(h1, g2)^3
    $cipher->{C3} = $self->{pairing}->init_GT;
    $cipher->{C3}->pairing_apply($self->{MPK}->{h1}, $self->{MPK}->{g2});
    $cipher->{C3}->pow_zn($r);
    $cipher->{C3}->mul($m);

    return $cipher;
}

=head2 decrypt_element

Recover the element of GT from the given ciphertext.

Required parameters:

=over 4

=item Ciphertext

The ciphertext is a hashref with (P,C1,..C4) keys,
as returned from the C<encrypt_element> method.

=back

To decrypt, the secret key (SK) is used. It must be of hierarchy length >= |P| in
order to be able to decrypt the pattern.

Returns an element of GT.
L<Use a comparison function|Crypt::PBC/"Comparison_Functions">
to determine the success or failure of the decryption.

=cut
sub decrypt_element {
    my ($self, $cipher) = @_;

    croak("Cannot decrypt without secret key") unless (defined $self->{SK});

    my $pattern_len = scalar(@{$cipher->{P}});
    my $key_hierarchy_len = scalar(@{$self->{SK}->{ids}});

    croak("Cannot decrypt pattern of length " . $pattern_len
        . ", ID hierarchy too small: " . $key_hierarchy_len)
    unless $key_hierarchy_len >= $pattern_len;

    for my $id ($cipher->{P}) {
        croak("Pattern must only either an * or an integer >= 0")
        unless ($id eq '*' || $id >= 0);
    }

    my $c_2n = $self->{pairing}->init_G1;
    my $temp = $self->{pairing}->init_G1;
    # Initialize C2' as C2
    $c_2n->set($cipher->{C2});

    # Prepare IDs from ids
    my $ID_el = $self->{pairing}->init_Zr;
    
    for (my $i = 0; $i < $pattern_len; $i++) {
        if ($cipher->{P}->[$i] eq '*') {
            # Compute v_i ^ ID_i for each i in p that is a wildcard
            $ID_el->set_to_int($self->{SK}->{ids}->[$i]);
            $temp->pow_zn($cipher->{C4}->[$i], $ID_el);
            $c_2n->mul($temp);
        }
    }

    # Compute m as C3 * e(C2', d_L+1) / e(C1, d_0)
    my $m = $self->{pairing}->init_GT;
    my $tempGT = $self->{pairing}->init_GT;

    my $keylen = scalar(@{$self->{SK}->{key}});
    $m->pairing_apply($c_2n, $self->{SK}->{key}->[$keylen - 1]);
    $tempGT->pairing_apply($cipher->{C1}, $self->{SK}->{key}->[0]);
    $m->div($tempGT);
    $m->mul($cipher->{C3});

    return $m;
}

=head1 AUTHOR

Oliver Günther <mail@oliverguenther.de>

=head1 COPYRIGHT

Copyright (C) 2014 by Oliver Günther

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

=head1 SEE ALSO

L<Crypt::PBC>

L<http://crypto.stanford.edu/pbc/>

L<http://groups.google.com/group/pbc-devel>

=cut

1;