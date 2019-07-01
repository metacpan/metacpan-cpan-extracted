package Bio::Palantir::Roles::Domainable;
# ABSTRACT: Domainable Moose role for Domain and DomainPlus objects
$Bio::Palantir::Roles::Domainable::VERSION = '0.191800';
use Moose::Role;

use autodie;


requires qw(                   
    rank function chemistry
    protein_sequence begin 
    end size coordinates
    monomer
);      # dna_* from gene_locations method (Domain.pm) create bugs because, as 
        # there is no DNA sequence when doing protein analyses, no strand can
        # be determined in antismash 4 and 5 versions



has 'symbol' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        
        my $name = $self->function;

        return 'na' unless $name;

        my $symbol = 
            $name =~ m/^A$ | AMP-binding | A-OX/xms 
            ? 'A' 
            : $name =~ m/^PCP | PP-binding/xms
            ? 'PCP' 
            : $name =~ m/^C$ | Condensation | ^X$ | Cglyc | Cter$/xms 
            ? 'C' 
            : $name =~ m/^E$ | Epimerization/xms 
            ? 'E' 
            : $name =~ m/^H$ | Heterocyclization/xms
            ? 'H' 
            : $name =~ m/^TE$ | Thioesterase/xmsi
            ? 'Te' 
            : $name =~ m/^Red$ | ^TD$ /xmsi
            ? 'Red' 
            : $name =~ m/Aminotran/xms
            ? 'Amt' 
            : $name =~ m/^PKS_/xms 
            ? $name =~ s/PKS_//r 
            : $name
        ;  # no need to reappoint domains like cMT, oMT, B, Hal,... 
        
        return $symbol;
    },
);

has 'class' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        
        my $name = $self->function;

        return 'NA'
            if $name eq 'NA';

        my $class = 
            $name =~ m/^A$ | AMP-binding | A-OX | Minowa | Khayatt | CAL | AT/xms
            ? 'substrate-selection'
            : $name =~ m/PCP | ACP$ | ACP_beta | PP-binding/xms
            ? 'carrier-protein'
            : $name =~ m/^C$ | Condensation | ^X$ | Cglyc | ^KS$ | _KS
                | Heterocyclization | ^H$/xms
            ? 'condensation'
            : $name =~ m/Thioesterase | TE | Red | TD | Cter | NAD/xms
            ? 'termination'
            : 'tailoring/other'
        ;

        return $class;
    },
);
    

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Bio::Palantir::Roles::Domainable - Domainable Moose role for Domain and DomainPlus objects

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
