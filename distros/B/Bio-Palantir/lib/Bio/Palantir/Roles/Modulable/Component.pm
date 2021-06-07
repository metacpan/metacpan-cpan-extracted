package Bio::Palantir::Roles::Modulable::Component;
$Bio::Palantir::Roles::Modulable::Component::VERSION = '0.211420';
use Moose;
use namespace::autoclean;

use aliased 'Bio::Palantir::Parser::Domain';
use aliased 'Bio::Palantir::Refiner::DomainPlus';


# private attributes

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

has 'rank' => (
    is      => 'ro',
    isa     => 'Num',
	default => -1,
	writer  => '_set_rank',
);

has $_ => (
    is       => 'ro',
    isa      => 'Str',
) for qw(protein_sequence cumulative_protein_sequence);

has $_ => (
    is  => 'ro',
    isa => 'ArrayRef',
) for qw(gene_uuis genomic_prot_coordinates);

has $_ => (
    is       => 'ro',
    isa      => 'Num',
) for qw(genomic_prot_begin genomic_prot_end size);


# public array(s) of composed objects


has 'domains' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef',    # possible to make a link with the role domainable?
    handles  => {
         count_domains => 'count',
           all_domains => 'elements',
           get_domain  => 'get',
          next_domain  => 'shift',        
    },
);


## no critic (ProhibitUnusedPrivateSubroutines)


## use critic



# public composed object(s)


# public deep methods


# public methods

# public aliases

sub sort_domains {
    
    my $self = shift;

    return [ sort { 
        $a->protein_locations->begin <=> $b->protein_locations->begin 
        } $self->all_domains 
    ];
}


sub genomic_dna_begin {
    return (shift->genomic_prot_begin * 3)
}


sub genomic_dna_end {
    return (shift->genomic_prot_end * 3)
}


sub get_domain_functions { 
    my $self = shift;

    my @domain_functions = map { $_->function } $self->all_domains;

    return \@domain_functions;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::Palantir::Roles::Modulable::Component

=head1 VERSION

version 0.211420

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 ATTRIBUTES

=head2 domains

ArrayRef of L<Bio::Palantir::Parser::Domain>

=head1 METHODS

=head2 count_domains

Returns the number of Domains of the Component.

    # $component is a Bio::Palantir::Parser::Component
    my $count = $component->count_domains;

This method does not accept any arguments.

=head2 all_domains

Returns all the Domains of the Component (not an array reference).

    # $component is a Bio::Palantir::Parser::Component
    my @domains = $component->all_domains;

This method does not accept any arguments.

=head2 get_domain

Returns one Domain of the Component by its index. You can also use
negative index numbers, just as with Perl's core array handling. If the
specified Domain does not exist, this method will return C<undef>.

    # $component is a Bio::Palantir::Parser::Component
    my $domain = $component->get_domain($index);
    croak "Domain $index not found!" unless defined $domain;

This method accepts just one argument (and not an array slice).

=head2 next_domain

Shifts the first Domain of the array off and returns it, shortening the
array by 1 and moving everything down. If there are no more Domains in
the array, returns C<undef>.

    # $component is a Bio::Palantir::Parser::Component
    while (my $domain = $component->next_domain) {
        # process $domain
        # ...
    }

This method does not accept any arguments.

=head2 sort_domains

Returns a array of sorted domains by increasing start coordinate (by default, the list of domains should be built in the right order, so it is a security here).

    # $component is a Bio::Palantir::Roles::Modulable::Component
	my @sorted_domains = $component->sort_domains;

This method does not accept any arguments.

=head2 genomic_dna_begin

Returns the begin of the genomic DNA coordinate of the module.

    # $component is a Bio::Palantir::Roles::Modulable::Component
	my $genomic_dna_begin = $component->genomic_dna_begin;

=head2 genomic_dna_end

Returns the end of the genomic DNA coordinate of the module.

    # $component is a Bio::Palantir::Roles::Modulable::Component
	my $genomic_dna_end = $component->genomic_dna_end;

=head2 get_domain_functions

Returns the list of functions from the domains constituting the module.

=head1 AUTHOR

Loic MEUNIER <lmeunier@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by University of Liege / Unit of Eukaryotic Phylogenomics / Loic MEUNIER and Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
