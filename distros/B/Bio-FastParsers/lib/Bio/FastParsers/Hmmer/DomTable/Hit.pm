package Bio::FastParsers::Hmmer::DomTable::Hit;
# ABSTRACT: internal class for tabular HMMER domain parser
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
$Bio::FastParsers::Hmmer::DomTable::Hit::VERSION = '0.173640';
use Moose;
use namespace::autoclean;
with 'Bio::FastParsers::Hmmer::Roles::Domainable';

# public attributes

has $_ => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
) for qw(target_name query_name);

has $_ => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    required => 1,
) for qw(target_description target_accession query_accession);

has $_ => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
) for qw(tlen qlen evalue score bias of);



sub expect {
    return shift->evalue
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::FastParsers::Hmmer::DomTable::Hit - internal class for tabular HMMER domain parser

=head1 VERSION

version 0.173640

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
