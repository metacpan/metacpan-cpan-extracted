package Bio::ProteaseI;
{
  $Bio::ProteaseI::VERSION = '1.112980';
}

# ABSTRACT: A role to build your customized Protease

use Moose::Role;
use Carp 'croak';
use namespace::autoclean;

requires '_cuts';

sub cut {
    my ( $self, $substrate, $pos ) = @_;

    croak "Incorrect substrate argument"
        unless ( defined $substrate and _looks_like_string($substrate) );

    unless ( defined $pos and $pos > 0 and $pos <= length $substrate ) {

        croak "Incorrect position.";
    }

    $substrate = uc $substrate;
    $substrate = _cap_head($substrate);
    $pos += 3;

    my $pep = substr($substrate, $pos - 4, 8);

    if ( $self->_cuts($pep) ) {
        my $product = substr($substrate, 0, $pos);
        substr($substrate, 0, $pos) = '';

        _uncap($product, $substrate);

        return ($product, $substrate);
    }

    else { return }
}

sub digest {
    my ( $self, $substrate ) = @_;

    croak "Incorrect substrate argument"
        unless ( defined $substrate and _looks_like_string($substrate) );

    # Get the positions where the enzyme cuts
    my @sites = $self->cleavage_sites($substrate) or return $substrate;

    # Get the peptide products;
    my @products;
    my $start = 0;
    while ( my $site = shift @sites ) {
        my $length = $site - $start;
        my $product = substr($substrate, $start, $length);
        push @products, $product;
        $start += $length;
    }

    # Last peptide: cut from last position to the end.
    push @products, substr($substrate, $start);

    return @products;
}

sub is_substrate {
    my ($self, $substrate) = @_;

    croak "Incorrect substrate argument"
        unless ( defined $substrate and _looks_like_string($substrate) );

    for my $pos (1 .. length $substrate) {
        return 1 if $self->cut($substrate, $pos);
    }

    return;
}

around _cuts => sub {

    my ($orig, $self, $substrate) = @_;

    $substrate = _cap_tail($substrate) or return;

    $self->$orig($substrate);
};

sub _cap_tail {
    my $substrate = shift;

    my $length = length $substrate;
    if ( $length < 8 ) {
        if ( $length > 4 ) {
            $substrate .= 'X' x (8 - $length);
        }
        else { return }
    }

    return $substrate;
}

sub _cap_head { return 'XXX' . shift }

sub _uncap { s/X//g for @_ }

sub _looks_like_string { $_[0] ~~ /[a-z]+/i }

sub cleavage_sites {
    my ( $self, $substrate ) = @_;

    croak "Incorrect substrate argument"
        unless ( defined $substrate and _looks_like_string($substrate) );

    $substrate = uc $substrate;
    my @sites;
    my $i = 1;

    $substrate = _cap_head($substrate);
    while ( my $pep = substr($substrate, $i-1, 8 ) ) {
        if ( $self->_cuts( $pep ) ) { push @sites, $i };
        ++$i;
    }
    return @sites;
}

1;








__END__
=pod

=head1 NAME

Bio::ProteaseI - A role to build your customized Protease

=head1 VERSION

version 1.112980

=head1 SYNOPSIS

    package My::Protease;
    use Moose;
    with 'Bio::ProteaseI';

    sub _cuts {
        my ($self, $peptide) = @_;

        # some code that decides
        # if $peptide should be cut or not

        if ( $peptide_should_be_cut ) { return 1 }
        else                          { return   }
    };

=head1 DESCRIPTION

This module describes the interface for L<Bio::Protease>. You only need
to use this if you want to build your custom specificity protease and
regular expressions won't do; otherwise look at L<Bio::Protease>
instead.

All of the methods provided in L<Bio::Protease> are defined here.
The consuming class just has to implement a C<_cuts> method.

=head1 METHODS

=head2 cut

Attempt to cleave C<$peptide> at the C-terminal end of the C<$i>-th
residue (ie, at the right). If the bond is indeed cleavable (determined
by the enzyme's specificity), then a list with the two products of the
hydrolysis will be returned. Otherwise, returns false.

    my @products = $enzyme->cut($peptide, $i);

=head2 digest

Performs a complete digestion of the peptide argument, returning a list
with possible products. It does not do partial digests (see method
C<cut> for that).

    my @products = $enzyme->digest($protein);

=head2 is_substrate

Returns true or false whether the peptide argument is a substrate or
not. Esentially, it's equivalent to calling C<cleavage_sites> in boolean
context, but with the difference that this method short-circuits when it
finds its first cleavable site. Thus, it's useful for CPU-intensive
tasks where the only information required is whether a polypeptide is a
substrate of a particular enzyme or not 

=head2 cleavage_sites

Returns a list with siscile bonds (bonds susceptible to be cleaved as
determined by the enzyme's specificity). Bonds are numbered starting
from 1, from N to C-terminal. Takes a string with the protein sequence
as an argument:

    my @sites = $enzyme->cleavage_sites($peptide);

=head1 How to implement your own Protease class.

=head2 Step 1: create a class that does ProteaseI.

    package My::Protease;
    use Moose;
    with 'Bio::ProteaseI';

    1;

Simply create a new Moose class, and consume the L<Bio::ProteaseI>
role.

=head2 Step 2: Implement a _cuts() method.

The C<_cuts> method will be used by the methods C<digest>, C<cut>,
C<cleavage_sites> and C<is_substrate>. It will B<always> be passed a
string of 8 characters; if the method returns true, then the peptide
bond between the 4th and 5th residues will be marked as siscile, and the
appropiate action will be performed depending on which method was
called.

Your specificity logic should only be concerned in deciding whether the
8-residue long peptide passed to it as an argument should be cut between
the 4th and 5th residues. This is done in the private C<_cuts> method,
like so:

    sub _cuts {
        my ( $self, $peptide ) = @_;

        # some code that decides
        # if $peptide should be cut or not

        if ( $peptide_should_be_cut ) { return 1 }
        else                          { return   }
    };

And that's it. Your class will be composed with all the methods
mentioned above, and will work according to the specificity logic that
you define in your C<_cuts()> method.

=head2 Example: a ridiculously specific protease

Suppose you want to model a protease that only cleaves the sequence
C<MAEL^VIKP>. Your Protease class would be like this:

    package My::Ridiculously::Specific::Protease;
    use Moose;
    with 'Bio::ProteaseI';

    sub _cuts {
        my ( $self, $substrate ) = @_;

        if ( $substrate eq 'MAELVIKP' ) { return 1 }
        else                            { return   }
    };

    1;

Then you can use your class easily in your application:

    #!/usr/bin/env perl
    use Modern::Perl;

    use My::Ridiculously::Specific::Protease;

    my $protease = My::Ridiculously::Specific::Protease->new;
    my @products = $protease->digest( 'AAAAMAELVIKPYYYYYYY' );

    say for @products; # ["AAAAMAEL", "VIKPYYYYYYY"]

Of course, this specificity model is too simple to deserve a new class,
as it could be perfectly defined by a regex and passed to the
C<specificity> attribute of L<Bio::Protease>. It's only used here as an
example.

=head1 AUTHOR

Bruno Vecchi <vecchi.b gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Bruno Vecchi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

