package Bio::Palantir::Explorer::GeneFasta;
# ABSTRACT: Explorer internal class for handling GeneFasta objects
$Bio::Palantir::Explorer::GeneFasta::VERSION = '0.191800';
use Moose;
use namespace::autoclean;

use Data::UUID;
use List::AllUtils qw(each_array);

use aliased 'Bio::Palantir::Refiner::DomainPlus';
with 'Bio::Palantir::Roles::Fillable';


# public attributes

has 'from_seq' => (
    is       => 'ro',
    isa      => 'Bool',
    init_arg => undef,
    default  => 1,
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

has $_ => (
    is => 'ro',
    isa => 'Str',
) for qw(protein_sequence name);

has $_ => (
    is => 'ro',
    isa => 'Num',
) for qw(gene_begin gene_end rank size);

has 'coordinates' => (
    is      => 'ro',
    isa     => 'ArrayRef',
);


# private attributes


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

## no critic (ProhibitUnusedPrivateSubroutines)


## use critic


sub BUILD {
    my $self = shift;

    my ($seq) = $self->protein_sequence; 
    my $gene_pos = 0;

    my @domains = $self->detect_domains($seq, $gene_pos);
      
    unless (@domains) {
        return;
    }

    $self->_set_domains(\@domains);

    return;
}

# public methods


# private methods


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::Palantir::Explorer::GeneFasta - Explorer internal class for handling GeneFasta objects

=head1 VERSION

version 0.191800

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 ATTRIBUTES

=head2 domains

ArrayRef of L<Bio::Palantir::Refiner::DomainPlus>

=head1 METHODS

=head2 count_domains

Returns the number of Domains of the Gene.

    # $gene is a Bio::Palantir::Explorer::GeneFasta
    my $count = $gene->count_domains;

This method does not accept any arguments.

=head2 all_domains

Returns all the Domains of the Gene (not an array reference).

    # $gene is a Bio::Palantir::Explorer::GeneFasta
    my @domains = $gene->all_domains;

This method does not accept any arguments.

=head2 get_domain

    # $gene is a Bio::Palantir::Explorer::GeneFasta
    my $domain = $gene->get_domain($index);
    croak "Domain $index not found!" unless defined $domain;

This method accepts just one argument (and not an array slice).

=head2 next_domain

Shifts the first Domain of the array off and returns it, shortening the
array by 1 and moving everything down. If there are no more Domains in
the array, returns C<undef>.

    # $gene is a Bio::Palantir::Explorer::GeneFasta
    while (my $domain = $gene->next_domain) {
        # process $domain
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
