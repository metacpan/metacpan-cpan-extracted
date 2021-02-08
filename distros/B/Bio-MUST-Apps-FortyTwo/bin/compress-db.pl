#!/usr/bin/env perl
# PODNAME: compress-db.pl
# ABSTRACT: Post-process assembler for transcript enrichment using 42

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Path::Class qw(file dir);

## no critic (RequireLocalizedPunctuationVars)
BEGIN{
    $ENV{Smart_Comments} = $ARGV_verbosity
        ? join q{ }, map { '#' x (2 + $_) } 1..$ARGV_verbosity
        : q{}
    ;
}
## use critic

use Smart::Comments -ENV;
use Config::Any;

use Bio::MUST::Core;
use Bio::MUST::Drivers;
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::Seq';
use aliased 'Bio::MUST::Core::SeqId';
use aliased 'Bio::MUST::Drivers::Cap3';
use aliased 'Bio::MUST::Apps::Debrief42';


# read configuration file
my $config = Config::Any->load_files( {
    files           => [ file($ARGV_config) ],
    flatten_to_hash => 1,
    use_ext         => 1,
    }
);

# build Debrief42 object
my $debrief42 = Debrief42->new(
    config     => $config->{$ARGV_config},
    report_dir => $ARGV_indir,
);

### Reading Tax-Reports...
my $run_report = $debrief42->run_report;
my @orgs = $run_report->all_orgs;

# create output dir named after input dir and settings
my $dirname = dir($ARGV_indir)->stringify;      # ignore trailing '/' if any
my $outdir = dir($dirname . '-compress' . "-o$ARGV_cap3_o" . "-p$ARGV_cap3_p");

### Creating outdir: $outdir->stringify
$outdir->mkpath();

for my $org (@orgs) {

    ### Processing: $org
    my $org_report = $run_report->org_report_for($org);

    my $ali = Ali->new;

    OUTFILE:
    for my $new_seqs (sort $org_report->all_new_seqs_by_outfile) {
        # TODO: try to avoid sort by making method deterministic (not easy)

        # collect new_seqs for current org and outfile
        my $outfile;
        my @seqs2cap;
        for my $new_seq ( @{$new_seqs} ) {
            $outfile //= $new_seq->outfile;
            my $seq_id = SeqId->new( full_id => $new_seq->seq_id )->accession;
            my $seq    = $new_seq->seq;
            push @seqs2cap, Seq->new( seq_id => $seq_id, seq => $seq );
        }

        # proceed only for combos with at least two new_seqs
        # otherwise add lone seq to database
        if (@seqs2cap < 2) {
            $ali->add_seq( shift @seqs2cap );
            next OUTFILE;
        }

        # try to cap new_seqs for current org and outfile
        my $cap = Cap3->new(
            seqs     => \@seqs2cap,
            cap3_args => { -o => $ARGV_cap3_o, -p => $ARGV_cap3_p },
        );

        # add singlet seqs to database
        my @singlets = $cap->all_singlets;
        $ali->add_seq($_) for @singlets;

        # proceed only for combos with contigs of new_seqs
        my @contigs  = $cap->all_contigs;
        next OUTFILE unless @contigs;

        ### $outfile
        for my $contig (@contigs) {
            my @ids = map { $_->full_id }
                @{ $cap->seq_ids_for( $contig->full_id ) };
            ### $contig
            ### @ids
            my $contig_id = shift(@ids) . '+' . @ids;
            ### $contig_id
            my $contig_seq = $contig->seq;
            ### $contig_seq

            # add contig seq to database
            $ali->add_seq(
                Seq->new( seq_id => $contig_id, seq => $contig_seq )
            );
        }
    }

    # store contig database for org
    (my $outfile = $org) =~ tr/ /_/;
        $outfile .= '_new_cap3.fasta';
    $ali->store( file($outdir, $outfile) );
}

__END__

=pod

=head1 NAME

compress-db.pl - Post-process assembler for transcript enrichment using 42

=head1 VERSION

version 0.210370

=head1 USAGE

    compress.pl --config=<file> --indir=<dir> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item --config=<file>

Path to YAML C<config> file for 42.

=for Euclid: file.type: string

=item --indir=<dir>

Path to input tax-report files.

=for Euclid: dir.type: str

=back

=head1 OPTIONAL ARGUMENTS

=item --cap3-o=<n>

Overlap length cutoff for CAP3 (should be > 15) [default: 40].

=for Euclid: n.type:    n > 15
    n.default: 40

=item --cap3-p=<n>

Overlap percent identity cutoff for CAP3 (should be > 65) [default: 90].

=for Euclid: n.type:    n > 65
    n.default: 90

=item --verbosity=<level>

Verbosity level for logging to STDERR [default: 0]. Available levels range from
0 to 6. Level 6 corresponds to debugging mode.

=for Euclid: level.type: int, level >= 0 && level <= 6
    level.default: 1

=item --version

=item --usage

=item --help

=item --man

=over

Print the usual program information

=back

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
