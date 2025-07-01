package Bio::MUST::Core::Roles::Taxable;
# ABSTRACT: Taxable Moose role for objects that query a taxonomy
$Bio::MUST::Core::Roles::Taxable::VERSION = '0.251810';
use Moose::Role;

use autodie;
use feature qw(say);

use Carp;

use Bio::MUST::Core::Types;
use aliased 'Bio::MUST::Core::Taxonomy';


has 'tax_dir' => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
);


has 'tax' => (
    is       => 'ro',
    isa      => 'Maybe[Bio::MUST::Core::Taxonomy]',
    lazy     => 1,
    builder  => '_build_tax',           # if not provided in constructor
);

## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_tax {
    my $self = shift;

    my $tax_dir = $self->tax_dir;
    unless ($tax_dir) {
        carp '[BMC] Warning: no valid tax_dir specified; disabling taxonomy!';
        return;
    }

    return Taxonomy->new_from_cache( tax_dir => $tax_dir );
}

## use critic

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Roles::Taxable - Taxable Moose role for objects that query a taxonomy

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
