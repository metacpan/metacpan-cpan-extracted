package Bio::FastParsers::Roles::Targetable;
# ABSTRACT: Target attrs common to HMMER Standard::Target and Table::Hit
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
$Bio::FastParsers::Roles::Targetable::VERSION = '0.221230';
use Moose::Role;

use autodie;
use feature qw(say);

use Bio::FastParsers::Types;
use Bio::FastParsers::Constants qw(:files);


has $_ => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
) for qw(target_name query_name);

has $_ => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    required => 1,
) for qw(target_description);

has $_ => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
) for qw(
             evalue           score           bias
    best_dom_evalue  best_dom_score  best_dom_bias
        exp     dom
);



sub expect {
    return shift->evalue;
}

sub name {
    return shift->target_name;
}

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Bio::FastParsers::Roles::Targetable - Target attrs common to HMMER Standard::Target and Table::Hit

=head1 VERSION

version 0.221230

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
