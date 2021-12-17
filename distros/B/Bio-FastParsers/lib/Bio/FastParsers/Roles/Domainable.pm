package Bio::FastParsers::Roles::Domainable;
# ABSTRACT: Domain attrs common to HMMER Standard::Domain and DomTable::Hit
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
$Bio::FastParsers::Roles::Domainable::VERSION = '0.213510';
use Moose::Role;

use autodie;
use feature qw(say);

use Bio::FastParsers::Types;
use Bio::FastParsers::Constants qw(:files);


has $_ => (
    is          => 'ro',
    isa         => 'Num',
    required    => 1,
) for qw(
    rank
    dom_score c_evalue
    dom_bias  i_evalue
    hmm_from hmm_to
    ali_from ali_to
    env_from env_to
    acc
);



sub ali_start {
    return shift->ali_from;
}

sub ali_end {
    return shift->ali_to;
}

sub hmm_start {
    return shift->hmm_from;
}

sub hmm_end {
    return shift->hmm_to;
}

sub env_start {
    return shift->env_from;
}

sub env_end {
    return shift->env_to;
}

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Bio::FastParsers::Roles::Domainable - Domain attrs common to HMMER Standard::Domain and DomTable::Hit

=head1 VERSION

version 0.213510

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 ALIASES

=head2 expect

Alias for C<evalue> method. For API consistency.

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Arnaud DI FRANCO

Arnaud DI FRANCO <arnaud.difranco@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
