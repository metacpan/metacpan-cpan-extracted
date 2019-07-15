package Bio::MUST::Drivers::Exonerate;
# ABSTRACT: Bio::MUST driver for running the Exonerate alignment program
$Bio::MUST::Drivers::Exonerate::VERSION = '0.191910';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Carp;
use Const::Fast;
use IPC::System::Simple qw(system);
use List::AllUtils qw(mesh);
use Module::Runtime qw(use_module);
use Path::Class qw(file);

use Bio::MUST::Core;
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::GeneticCode';
use aliased 'Bio::MUST::Core::Seq';
use aliased 'Bio::MUST::Drivers::Exonerate::Sugar';


has 'dna_seq' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Seq',
    required => 1,
);

has 'pep_seq' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Seq',
    required => 1,
);

has 'genetic_code' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::GeneticCode',
    required => 1,
);

has '_ali' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali',
    init_arg => undef,
    writer   => '_set_ali',
    handles  => {
          all_cds =>   'all_seqs',
        count_cds => 'count_seqs',
    },
);

has '_sugars' => (
    traits   => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[Bio::MUST::Drivers::Exonerate::Sugar]',
    default => sub { [] },
    handles  => {
        add_sugar  => 'push',
        get_sugar  => 'get',
    },
);


const my @attrs => qw(
     query_id  query_start  query_end  query_strand
    target_id target_start target_end target_strand
    score
);

sub BUILD {
    my $self = shift;

    # provision executable
    my $app = use_module('Bio::MUST::Provision::Exonerate')->new;
       $app->meet();

    # build temp Ali file for input DNA seq
    my $dna = Ali->new(
        seqs => [ $self->dna_seq ],
        guessing => 0,
    );
    my $dnafile = $dna->temp_fasta;

    # build temp Ali file for input PEP seq
    my $pep = Ali->new(
        seqs => [ $self->pep_seq ],
        guessing => 0,
    );
    my $pepfile = $pep->temp_fasta;

    # setup output file
    my $outfile = $dnafile . '.exonerate.out';
    # TODO: make outfile name more robust using File::Temp

    # create exonerate command
    my $pgm = 'exonerate';
    my $code = $self->genetic_code->ncbi_id;
    my $cmd = qq{$pgm --ryo ">%S\\n%tcs" --showvulgar no}
        . " --showalignment no --verbose 0 --geneticcode $code"
        . " --model protein2genome --query $pepfile --target $dnafile"
        . " > $outfile 2> /dev/null"
    ;

    # try to robustly execute exonerate
    my $ret_code = system( [ 0, 127 ], $cmd);
    if ($ret_code == 127) {
        carp "[BMD] Warning: Cannot execute $pgm command; returning nothing!";
        return;
    }
    # TODO: try to bypass shell (need for absolute path to executable then)

    # read output file (FASTA format with special defline)
    my $ali = Ali->load($outfile);
    $self->_set_ali($ali);

    # parse deflines and store them as Sugar objects
    # TODO: fix coordinates for consistency with Aligned? (beware of rev_comp)
    for my $id ($ali->all_seq_ids) {
        my @fields = split /\s+/xms, $id->full_id;
        $fields[0] = $self->pep_seq->seq_id->full_id;
        $fields[4] = $self->dna_seq->seq_id->full_id;
        @fields[3,7] = map {
            $_ eq '-' ? -1 :        # reverse
            $_ eq '+' ?  1 :        # forward
            $_ eq '.' ?  1 :        # unknown
                        $_
        } @fields[3,7];
        $self->add_sugar( Sugar->new( { mesh @attrs, @fields } ) );
    }
    # TODO: check value of strands / gene orientation

    # unlink temp files
    file($_)->remove for ($dnafile, $pepfile, $outfile);

    return;
}


sub cds_order {
    my $self = shift;

    # return exon indices according to start pos in protein coordinates
    my @order = sort {
        $self->get_sugar($a)->query_start <=> $self->get_sugar($b)->query_start
    } 0..$self->count_cds-1;

    return @order;
}


sub all_exons_in_order {
    my $self = shift;
    return @{ $self->_ali->seqs }[ $self->cds_order ];
}


sub complete_cds {
    my $self = shift;

    # splice CDS from sorted exons
    my $full_id = $self->dna_seq->full_id;
    my $new_seq = join q{}, map { $_->seq } $self->all_exons_in_order;

    # warn of unexpected CDS length
    carp "[BMD] Warning: spliced CDS length not a multiple of 3 for $full_id!"
        unless length($new_seq) % 3 == 0;

    return Seq->new(seq_id => $full_id, seq => $new_seq);
}


sub translation {
    my $self = shift;

    # return translated protein from spliced CDS
    return $self->genetic_code->translate($self->complete_cds);
}


sub all_sugars_in_order {
    my $self = shift;
    return @{ $self->_sugars }[ $self->cds_order ];
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Drivers::Exonerate - Bio::MUST driver for running the Exonerate alignment program

=head1 VERSION

version 0.191910

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
