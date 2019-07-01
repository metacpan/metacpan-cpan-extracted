package Bio::Palantir::Refiner::DomainPlus;
# ABSTRACT: Refiner internal class for handling DomainPlus objects
$Bio::Palantir::Refiner::DomainPlus::VERSION = '0.191800';
use Moose;
use namespace::autoclean;

use Data::UUID;


# public attributes

has 'uui' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    default  => sub {
        my $self = shift;
        my $ug = Data::UUID->new;
        my $uui = $ug->create_str();    
        return $uui;
    }
);

has '_domain' => (
    is      => 'ro',
    isa     => 'Bio::Palantir::Parser::Domain',
);

has 'coordinates' => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef]',
	default => undef,
	writer  => '_set_coordinates',
);

has $_ => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
	default => undef,
	writer  => '_set_'. $_,
) for qw(function chemistry phmm_name subtype protein_sequence 
    target_name query_name subtype_evalue subtype_score base_uui monomer);

has $_ => (
    is       => 'ro',
    isa      => 'Maybe[Num]',
	default => undef,
	writer  => '_set_'. $_,
) for qw(rank begin end size tlen qlen evalue score ali_from ali_to hmm_from
    hmm_to);

with 'Bio::Palantir::Roles::Domainable';

# public methods


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::Palantir::Refiner::DomainPlus - Refiner internal class for handling DomainPlus objects

=head1 VERSION

version 0.191800

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Loic MEUNIER <lmeunier@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by University of Liege / Unit of Eukaryotic Phylogenomics / Loic MEUNIER and Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
