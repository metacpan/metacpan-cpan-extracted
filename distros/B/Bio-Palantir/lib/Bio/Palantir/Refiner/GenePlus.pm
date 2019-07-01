package Bio::Palantir::Refiner::GenePlus;
# ABSTRACT: Refiner internal class for handling GenePlus objects
$Bio::Palantir::Refiner::GenePlus::VERSION = '0.191800';
use Moose;
use namespace::autoclean;

use Data::UUID;
use List::AllUtils qw(each_array);

use aliased 'Bio::Palantir::Refiner::DomainPlus';


# private attributes

has '_gene' => (
    is      => 'ro',
    isa     => 'Bio::Palantir::Parser::Gene',
    handles => [qw(
        name rank protein_sequence genomic_dna_begin 
        genomic_dna_end genomic_dna_coordinates
        genomic_dna_size genomic_prot_begin genomic_prot_end 
        genomic_prot_coordinates genomic_prot_size
    )],
);

has 'from_seq' => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
);

# public attributes

has 'gap_filling' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has 'undef_cleaning' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

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

has 'gene_begin' => (
    is       => 'ro',
    isa      => 'Num',
    init_arg => undef,
    default  => 1,
);

has 'gene_end' => (
    is       => 'ro',
    isa      => 'Num',
    init_arg => undef,
    default  => sub {
        my $self = shift;
        return $self->genomic_prot_size;
    }
);


# public array(s) of composed objects


has 'domains' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Bio::Palantir::Refiner::DomainPlus]',
    init_arg => undef,
    default  => sub { [] },
    writer   => '_set_domains',
    handles  => {
         count_domains => 'count',
           all_domains => 'elements',
           get_domain  => 'get',
          next_domain  => 'shift',        
    },
);

with 'Bio::Palantir::Roles::Fillable', 
     'Bio::Palantir::Roles::Geneable';



has 'exp_domains' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Bio::Palantir::Refiner::DomainPlus]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_exp_domains',
    handles  => {
         count_exp_domains => 'count',
           all_exp_domains => 'elements',
           get_exp_domain  => 'get',
          next_exp_domain  => 'shift',        
    },
);

## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_exp_domains {
    my $self = shift;

    my ($seq) = $self->protein_sequence; 
    my $gene_pos = 0;

    my @domains = $self->detect_domains($seq, $gene_pos);
      
    unless (@domains) {
        return [];
    }

    return [ sort { $a->end <=> $b->end } @domains ];
}

## use critic


sub BUILD {
    #TODO encapsulate the BUILD in Roles/Fillable.pm
    my $self = shift;

    if ($self->from_seq == 1) {
    
        my ($seq) = $self->protein_sequence; 
        my $gene_pos = 0;

        my @domains = $self->detect_domains($seq, $gene_pos);

        unless (@domains) {
            return;
        }

        $self->_set_domains(\@domains);
    }

    else { 

        # based on Bio::Palantir::Parser::Gene
        my @domains_plus;
        for my $domain ($self->_gene->all_domains) {
            push @domains_plus, DomainPlus->new(
                protein_sequence => $domain->protein_sequence,
                function         => $domain->function,
                base_uui         => $domain->uui,
                _domain          => $domain,
                begin            => $domain->begin,
                monomer          => $domain->monomer,
            );
        }
        
        unless (@domains_plus) {
            return;
        }

        # get all domain properties
        $self->_get_domain_features($_, $_->begin) for @domains_plus;
        
        # delete domains from antismash where we can't retrieve traces with all pHMMs (bugs ? -> P pisi Pren)
        if ($self->undef_cleaning == 1 ) {
            @domains_plus = grep { $_->function ne 'to_remove' } @domains_plus;
        }
        
        $self->_set_domains(\@domains_plus);
        
        # self explaining
        $self->_elongate_coordinates([$self->all_domains]);
        $self->_refine_coordinates($self->all_domains);

        # subtype the domains
        $self->_get_domain_subtype($_) for $self->all_domains;
        
        # fill gaps if needed (add domains)
        unless ($self->gap_filling == 0) {
            $self->_fill_gaps();
        }

        #TODO $self->_get_docking_domains
    }
    
    return;
}

# public methods


# private methods

sub _fill_gaps {         # use gene protein sequence
    my $self = shift;
    
    my $gap_cutoff = shift // 250;

    # point out "holes" in domain architecture
    my %gap_for;
    my @domains = $self->all_domains;

    for (my $i = 0; $i <= (scalar @domains - 2); $i++ ) {
            
        if ( ($domains[$i+1]->begin - $domains[$i]->end) > $gap_cutoff ) {

            $gap_for{$domains[$i]->end . '-' . $domains[$i+1]->end} = { 
                start => $domains[$i]->end + 1,
                end   => $domains[$i+1]->begin - 1,
                size  => ($domains[$i+1]->begin - 1)
                            - ($domains[$i]->end + 1) + 1,
            };
        }

        #TODO if last domain before the end of the gene, maybe check it for undetected domains
    }

    for my $gap (keys %gap_for) {

        my ($seq) = $self->protein_sequence;
        $seq = substr($seq, $gap_for{$gap}{start} - 1, $gap_for{$gap}{size});                    

        my @new_domains = $self->detect_domains($seq, $gap_for{$gap}{start}, 
            [ $gap_for{$gap}{start}, $gap_for{$gap}{end} ]) ;

        # remove very truncated domains (to not overlap previous domain in upstream)
        for my $i (0..@new_domains - 1) {

            my $match_length = $new_domains[$i]->size; 
            my $length_cutoff = $new_domains[$i]->tlen * 0.5;

            delete $new_domains[$i] if $match_length <= $length_cutoff;
        }
        
        @new_domains = grep { defined } @new_domains;

        if (@new_domains) {
            $self->_set_domains( [@domains, @new_domains] );
        }
    }

    return;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::Palantir::Refiner::GenePlus - Refiner internal class for handling GenePlus objects

=head1 VERSION

version 0.191800

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 ATTRIBUTES

=head2 domains

ArrayRef of L<Bio::Palantir::Refiner::Domain>

=head2 exp_domains

ArrayRef of L<Bio::Palantir::Refiner::Domain>

=head1 METHODS

=head2 count_domains

Returns the number of Domains of the Gene.

    # $gene is a Bio::Palantir::Refiner::Gene
    my $count = $gene->count_domains;

This method does not accept any arguments.

=head2 all_domains

Returns all the Domains of the Gene (not an array reference).

    # $gene is a Bio::Palantir::Refiner::Gene
    my @domains = $gene->all_domains;

This method does not accept any arguments.

=head2 get_domain

    # $gene is a Bio::Palantir::Refiner::Gene
    my $domain = $gene->get_domain($index);
    croak "Domain $index not found!" unless defined $domain;

This method accepts just one argument (and not an array slice).

=head2 next_domain

Shifts the first Domain of the array off and returns it, shortening the
array by 1 and moving everything down. If there are no more Domains in
the array, returns C<undef>.

    # $gene is a Bio::Palantir::Refiner::Gene
    while (my $domain = $gene->next_domain) {
        # process $domain
        # ...
    }

This method does not accept any arguments.

=head2 count_exp_domains

Returns the number of Domains of the Gene.

    # $gene is a Bio::Palantir::Refiner::Gene
    my $count = $gene->count_exp_domains;

This method does not accept any arguments.

=head2 all_exp_domains

Returns all the Domains of the Gene (not an array reference).

    # $gene is a Bio::Palantir::Refiner::Gene
    my @exp_domains = $gene->all_exp_domains;

This method does not accept any arguments.

=head2 get_exp_domain

    # $gene is a Bio::Palantir::Refiner::Gene
    my $exp_domain = $gene->get_exp_domain($index);
    croak "Domain $index not found!" unless defined $exp_domain;

This method accepts just one argument (and not an array slice).

=head2 next_exp_domain

Shifts the first Domain of the array off and returns it, shortening the
array by 1 and moving everything down. If there are no more Domains in
the array, returns C<undef>.

    # $gene is a Bio::Palantir::Refiner::Gene
    while (my $exp_domain = $gene->next_exp_domain) {
        # process $exp_domain
        # ...
    }

This method does not accept any arguments.

=head1 AUTHOR

Loic MEUNIER <lmeunier@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by University of Liege / Unit of Eukaryotic Phylogenomics / Loic MEUNIER and Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
