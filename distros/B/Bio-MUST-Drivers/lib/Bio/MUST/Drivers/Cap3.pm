package Bio::MUST::Drivers::Cap3;
# ABSTRACT: Bio::MUST driver for running the CAP3 assembly program
$Bio::MUST::Drivers::Cap3::VERSION = '0.191910';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

# use Smart::Comments;

use Carp;
use IPC::System::Simple qw(system);
use Module::Runtime qw(use_module);
use Path::Class qw(file);
use Tie::IxHash;

use Bio::MUST::Core;
extends 'Bio::MUST::Core::Ali::Temporary';

use Bio::MUST::Core::Constants qw(:files);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::SeqId';

use Bio::MUST::Drivers::Utils qw(stringify_args);


has 'cap3_args' => (
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { {} },
);

has '_contig_seq_ids' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[ArrayRef[Bio::MUST::Core::SeqId]]',
    init_arg => undef,
    writer   => '_set_contig_seq_ids',
    handles  => {
        all_contig_names   => 'keys',
        all_contig_seq_ids => 'values',
        seq_ids_for        => 'get',
    },
);

has '_contigs' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali',
    init_arg => undef,
    writer   => '_set_contigs',
    handles  => {
          all_contigs =>   'all_seqs',
        count_contigs => 'count_seqs',
    },
);

has '_singlets' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali',
    init_arg => undef,
    writer   => '_set_singlets',
    handles  => {
          all_singlets =>   'all_seqs',
        count_singlets => 'count_seqs',
    },
);


sub BUILD {
    my $self = shift;

    # provision executable
    my $app = use_module('Bio::MUST::Provision::Cap3')->new;
       $app->meet();

    # setup output files
    my $infile   = $self->filename;
    my $basename = $infile . '.cap';
    my $outfile  = $basename . '.out';
    my $outfile_contigs  = $basename . '.contigs';
    my $outfile_singlets = $basename . '.singlets';

    # format CAP3 (optional) arguments
    my $args = $self->cap3_args;
    my $args_str = stringify_args($args);

    # create CAP3 command
    my $pgm = 'cap3';
    my $cmd = "$pgm $infile $args_str > $outfile 2> /dev/null";
    #### $cmd

    # try to robustly execute CAP3
    my $ret_code = system( [ 0, 127 ], $cmd);
    if ($ret_code == 127) {
        carp "[BMD] Warning: cannot execute $pgm command;"
            . ' returning without contigs!';
        return;
    }
    # TODO: try to bypass shell (need for absolute path to executable then)

    # parse output file
    open my $out, '<', $outfile;
    tie my %ids_for, 'Tie::IxHash';
    my $contig_id;

    # CAP3 output file extract
    #
    # Number of segment pairs = 342; number of pairwise comparisons = 8
    # '+' means given segment; '-' means reverse complement
    #
    # Overlaps            Containments  No. of Constraints Supporting Overlap
    #
    # ******************* Contig 1 ********************
    # seq8+
    #                     seq9+ is in seq8+
    # ******************* Contig 2 ********************
    # seq10+
    # seq11+
    # ******************* Contig 3 ********************
    # seq12+
    #                     seq13+ is in seq12+
    #                     seq14+ is in seq13+
    # ******************* Contig 4 ********************
    # seq15+
    # seq16+
    # ******************* Contig 5 ********************
    # seq17+
    # seq18+
    #                     seq19+ is in seq18+
    #
    # DETAILED DISPLAY OF CONTIGS
    # ******************* Contig 1 ********************
    #                           .    :    .    :    .    :    .    :    .    :    .    :
    # seq8+                 CTGGACGAGCTGCAGGAGGAGGCGCTGGCGCTGGTGGCGCAGGCCCGACGAGAGGGCGAC
    #                       ____________________________________________________________
    # consensus             CTGGACGAGCTGCAGGAGGAGGCGCTGGCGCTGGTGGCGCAGGCCCGACGAGAGGGCGAC
    #
    # ...

    LINE:
    while (my $line = <$out>) {
        chomp $line;

        next LINE if $line =~ $EMPTY_LINE;
        last LINE if $line =~ m{\A DETAILED \s+ DISPLAY \s+ OF \s+ CONTIGS}xms;

        # capture next contig id
        if ($line =~ m{\A \*+ \s+ (Contig\s+\d+) \s+ \*+}xms) {
            ($contig_id = $1) =~ tr/ //d;
        }

        # capture fragment ids for current contig...
        elsif ($line =~ m{\A ([^\'\+\-\ ]+)[+-]}xms
            || $line =~ m{\A \s+ (\S+?)[+-]}xms) {
            my $fragment_id = $1;
            push @{ $ids_for{$contig_id} },
                SeqId->new( full_id => $self->long_id_for($fragment_id) );
        }   # ... and restore original id on the fly from IdMapper
    }

    # store contig and fragment ids
    $self->_set_contig_seq_ids(\%ids_for);

    # read and store contig seqs
    my $contigs = Ali->load($outfile_contigs);
    $contigs->dont_guess;
    $self->_set_contigs($contigs);

    # read and store singlet seqs...
    my $singlets = Ali->load($outfile_singlets);
    $singlets->dont_guess;
    $singlets->restore_ids($self->mapper);      # ... restoring original ids
    $self->_set_singlets($singlets);

    # unlink temp files
    my @files2rm = (
        $outfile, $outfile_contigs, $outfile_singlets,
        map { $basename . '.' . $_ } qw(info ace contigs.links contigs.qual)
    );
    file($_)->remove for @files2rm;

    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Drivers::Cap3 - Bio::MUST driver for running the CAP3 assembly program

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
