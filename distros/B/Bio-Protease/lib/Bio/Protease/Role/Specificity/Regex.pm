package Bio::Protease::Role::Specificity::Regex;
{
  $Bio::Protease::Role::Specificity::Regex::VERSION = '1.112980';
}

# ABSTRACT: A role that implements a regex-based specificity

use Moose::Role;
use Bio::Protease::Types 'ProteaseRegex';

has regex => (
    is  => 'ro',
    isa => ProteaseRegex,
    coerce => 1,
);

sub _cuts {
    my ($self, $peptide) = @_;

    if ( grep { $peptide !~ /$_/ } @{$self->regex} ) {
        return;
    }

    return 'yes, it cuts';
}


1;

__END__
=pod

=head1 NAME

Bio::Protease::Role::Specificity::Regex - A role that implements a regex-based specificity

=head1 VERSION

version 1.112980

=head1 SYNOPSIS

    package My::Protease;
    use Moose;

    with qw(Bio::ProteaseI Bio::Protease::Role::Specificity::Regex);

    package main;

    my $p = My::Protease->new( regex => qr/.{3}AC.{3}/ ); # coerces to [ qr/.../ ];

    my @products = $p->digest( 'AAAACCCC' );

    # @products: ('AAAA', 'CCCC')

=head1 DESCRIPTION

This role implements a regexp-based specificity for a class that also
consumes the L<Bio::ProteaseI> role. A peptide will be cleaved if any of
the regexes provided at construction time matches it. The regexes should
be tailored for 8-residue-long peptides, the cleavage site being between
the fourth and fifth residues.

For instance, if the specificity could be described as "cuts after
lysine or arginine", the appropriate regular expression would be
C<qr/.{3}[KR].{4}/>.

=head1 ATTRIBUTES

=head2 regex

A C<ProteaseRegex>, which is basically an array reference of regular
expressions that describe the protease specificity. It can coerce from a
single regular expression into a single-element array of regexps.  Any
of the regexes in the array should match a given substrate for it to be
cleavable.

=head1 AUTHOR

Bruno Vecchi <vecchi.b gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Bruno Vecchi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

