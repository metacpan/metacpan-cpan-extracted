package Bio::AutomatedAnnotation::Prokka;

# ABSTRACT: Prokka class for bacterial annotation


#    Copyright (C) 2012 Torsten Seemann
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

use Moose;
use File::Copy;
use warnings;
use Time::Piece;
use Time::Seconds;
use XML::Simple;
use List::Util qw(min max sum);
use Scalar::Util qw(openhandle);
use Bio::SeqIO;
use Bio::SearchIO;
use Bio::Seq;
use Bio::SeqFeature::Generic;
use FindBin;
use POSIX;

use Bio::AutomatedAnnotation::External::Cmscan;

has 'assembly_file' => ( is => 'ro', isa => 'Str', required => 1 );

has 'quiet'           => ( is => 'rw', isa => 'Bool', default => 1 );
has 'outdir'          => ( is => 'ro', isa => 'Str',  default => '' );
has 'dbdir'           => ( is => 'ro', isa => 'Str',  default => '/tmp/prokka' );
has 'force'           => ( is => 'ro', isa => 'Bool', default => 0 );
has 'prefix'          => ( is => 'ro', isa => 'Str',  default => '' );
has 'addgenes'        => ( is => 'ro', isa => 'Bool', default => 0 );
has 'locustag'        => ( is => 'ro', isa => 'Str',  lazy    => 1, builder => '_build_locustag' );
has 'increment'       => ( is => 'ro', isa => 'Int',  default => 1 );
has 'gffver'          => ( is => 'ro', isa => 'Int',  default => 3 );
has 'centre'          => ( is => 'ro', isa => 'Str',  default => 'VBC' );
has 'genus'           => ( is => 'rw', isa => 'Str',  default => 'Genus' );
has 'species'         => ( is => 'ro', isa => 'Str',  default => 'species' );
has 'strain'          => ( is => 'ro', isa => 'Str',  default => 'strain' );
has 'contig_uniq_id'  => ( is => 'ro', isa => 'Str',  default => 'gnl' );
has 'kingdom'         => ( is => 'rw', isa => 'Str',  default => 'Bacteria' );
has 'gcode'           => ( is => 'ro', isa => 'Int',  default => 0 );
has 'gram'            => ( is => 'ro', isa => 'Str',  default => '' );
has 'usegenus'        => ( is => 'rw', isa => 'Bool', default => 0 );
has 'proteins'        => ( is => 'ro', isa => 'Str',  default => '' );
has 'fast'            => ( is => 'ro', isa => 'Bool', default => 0 );
has 'cpus'            => ( is => 'ro', isa => 'Int',  default => 0 );
has 'mincontig'       => ( is => 'ro', isa => 'Int',  default => 200 );
has 'evalue'          => ( is => 'ro', isa => 'Num',  default => 1E-6 );
has 'rfam'            => ( is => 'ro', isa => 'Bool', default => 0 );
has 'files_per_chunk' => ( is => 'ro', isa => 'Int',  default => 100 );
has 'tempdir'         => ( is => 'ro', isa => 'Str',  default => '/tmp' );
has 'cleanup_prod'    => ( is => 'ro', isa => 'Bool', default => 1 );

has 'exe'     => ( is => 'ro', isa => 'Str', default => 'PROKKA' );
has 'version' => ( is => 'ro', isa => 'Str', default => '1.5' );
has 'author'  => ( is => 'ro', isa => 'Str', default => 'Torsten Seemann <torsten.seemann@monash.edu>' );
has 'url'     => ( is => 'ro', isa => 'Str', default => 'http://www.vicbioinformatics.com' );
has 'hypo'    => ( is => 'ro', isa => 'Str', default => 'hypothetical protein' );
has 'unann'   => ( is => 'ro', isa => 'Str', default => 'unannotated protein' );
has 'blastcmd' => (
    is  => 'ro',
    isa => 'Str',
    default =>
      "blastp -query %i -db %d -evalue %e -num_threads 1 -out %o -num_descriptions 1 -num_alignments 1 2>/dev/null"
);
has 'hmmer3cmd' =>
  ( is => 'ro', isa => 'Str', default => "hmmscan --noali --notextw --acc -E %e --cpu 1 -o %o %d %i 2>/dev/null" );
has 'infernalcmd' =>
  ( is => 'ro', isa => 'Str', default => "cmscan --noali --notextw --acc -E %e --cpu 1 -o %o %d %i 2>/dev/null" );
has 'starttime' => (
    is      => 'ro',
    isa     => 'Time::Piece',
    lazy    => 1,
    builder => '_build_starttime'
);

sub _build_starttime {
    my ($self) = @_;
    return localtime;
}

sub _build_locustag {
    my ($self) = @_;
    return $self->exe;
}

sub annotate {
    my ($self)          = @_;
    my $AUTHOR          = $self->author;
    my $BLASTPCMD       = $self->blastcmd;
    my $EXE             = $self->exe;
    my $HMMER3CMD       = $self->hmmer3cmd;
    my $HYPO            = $self->hypo;
    my $INFERNALCMD     = $self->infernalcmd;
    my $UNANN           = $self->unann;
    my $URL             = $self->url;
    my $VERSION         = $self->version;
    my $addgenes        = $self->addgenes;
    my $centre          = $self->centre;
    my $contig_uniq_id  = $self->contig_uniq_id;
    my $cpus            = $self->cpus;
    my $dbdir           = $self->dbdir;
    my $evalue          = $self->evalue;
    my $fast            = $self->fast;
    my $files_per_chunk = $self->files_per_chunk;
    my $force           = $self->force;
    my $gcode           = $self->gcode;
    my $genus           = $self->genus;
    my $gffver          = $self->gffver;
    my $gram            = $self->gram;
    my $increment       = $self->increment;
    my $kingdom         = $self->kingdom;
    my $locustag        = $self->locustag;
    my $mincontig       = $self->mincontig;
    my $outdir          = $self->outdir;
    my $prefix          = $self->prefix;
    my $proteins        = $self->proteins;
    my $quiet           = $self->quiet;
    my $rfam            = $self->rfam;
    my $species         = $self->species;
    my $starttime       = $self->starttime;
    my $strain          = $self->strain;
    my $tempdir         = $self->tempdir;
    my $usegenus        = $self->usegenus;

    my %seq;

    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    # welcome message

    $self->msg("This is $EXE $VERSION");
    $self->msg("$AUTHOR");
    $self->msg("Victorian Bioinformatics Consortium - $URL");
    $self->msg("Local time is $starttime");

    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    # set up options based on --mode

    if ( $kingdom =~ m/bac|prok/i ) {
        $kingdom = 'Bacteria';
        $gcode ||= 11;
    }
    elsif ( $kingdom =~ m/arch/i ) {
        $kingdom = 'Archaea';
        $gcode ||= 11;
        $gram = '';
    }
    elsif ( $kingdom =~ m/vir/i ) {
        $kingdom = 'Viruses';
        $gcode ||= 1;    # std
        $gram = '';
    }
    else {
        $self->err("Can't parse --mode '$kingdom'. Choose from: Bacteria Archaea Virus");
    }
    $self->msg("Annotating as >>> $kingdom <<<");

    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    # check options

    ( $gcode < 1 or $gcode > 24 ) and $self->err("Invalid genetic code, must be 1..24");
    $evalue >= 0 or $self->err("Invalid --evalue, must be >= 0");

    #($coverage >= 0 and $coverage <= 100) or $self->err("Invalid --coverage, must be 0..100");
    $increment >= 1 or $self->err("Invalid --increment, must be >= 1");
    $locustag ||= uc($EXE);

    # http://www.ncbi.nlm.nih.gov/genomes/static/Annotation_pipeline_README.txt
    $prefix ||= $locustag . '_' . ( localtime->mdy('') );    # NCBI wants US format, ech.
    $outdir ||= $prefix;
    if ( -d $outdir ) {
        if ($force) {
            $self->msg("Re-using existing --outdir $outdir");
        }
        else {
            $self->err("Folder '$outdir' already exists! Please change --outdir or use --force");
        }
    }
    else {
        $self->msg("Creating new output folder: $outdir");
        $self->runcmd("mkdir -p \Q$outdir\E");
    }
    $self->msg("Using filename prefix: $prefix.XXX");

    # canonical names
    $genus   = ucfirst( lc($genus) ) if $genus;
    $species = lc($species)          if $strain;

    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    # set up log file

    my $logfile = "$outdir/$prefix.log";
    $self->msg("Writing log to: $logfile");
    open LOG, '>', $logfile or $self->err("Can't open logfile");

    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    # check dependencies

    for my $exe (
        qw(less grep egrep sed find tbl2asn makeblastdb blastp
        aragorn prodigal rnammer parallel hmmscan cmscan)
      )
    {
        my $fp = $self->require_exe($exe);
        $fp ? $self->msg("Need '$exe' - using $fp") : $self->err("Can't find $exe in your \$PATH");
    }

    # Heikki discovered moreutils.deb contains a really old 'parallel' tool....
    my ($pout) = qx(parallel -V 2> /dev/null);
    if ( $pout !~ m/GNU/ ) {
        $self->err("You don't have GNU 'parallel' installed, you have a different tool with that name.");
    }

    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    # get versions of tools
    # FIXME - put these in a hash with regexps!

    my %tools = (
        'aragorn' => {
            GETVER  => "aragorn -h 2>&1 | grep -i '^ARAGORN v'",
            REGEXP  => qr/([\d\.]+)/,
            VERSION => "1.2",
        },
        'rnammer' => {
            GETVER  => "rnammer -V 2>&1 | grep -i 'rnammer [0-9]'",
            REGEXP  => qr/([\d\.]+)/,
            VERSION => "1.2",
        },
        'prodigal' => {
            GETVER  => "prodigal -v 2>&1 | grep -i '^Prodigal V'",
            REGEXP  => qr/([\d\.]+)/,
            VERSION => "2.6",
        },
        'signalp' => {

            # this is so long-winded as -v changed meaning (3.0=version, 4.0=verbose !?)
            GETVER  => "signalp -v < /dev/null 2>&1 | egrep ',|# SignalP' | sed 's/^# SignalP-//'",
            REGEXP  => qr/^(.*?)[,\s]/,
            VERSION => "4.0",
        },
        'infernal' => {
            GETVER  => "cmscan -h | grep '^# INFERNAL'",
            REGEXP  => qr/INFERNAL ([\d\.]+)/,
            VERSION => "1.0",
        },
    );

    for my $toolname ( keys %tools ) {
        my $t = $tools{$toolname};
        my ($s) = qx($t->{GETVER});
        if ( defined $s ) {
            $s =~ $t->{REGEXP};
            $t->{VERSION} = $1 if defined $1;
        }
        else {
            $self->msg("Could not determine version of $toolname ...");
        }
        $self->msg("Determined $toolname version is $t->{VERSION}");
    }

    if ( $rfam and $tools{infernal}{VERSION} < 1.1 ) {
        $self->err("This script only supports --rfam with Infernal (ie. cmscan) version 1.1 or higher");
    }

    $gcode ||= 1;
    $self->msg("Using genetic code table $gcode.");

    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    # read in sequences; remove small contigs; replace ambig with N

    my $in = $self->assembly_file;
    $self->msg("Loading and checking input file: $in");
    my $fin = Bio::SeqIO->new( -file => $in, -format => 'fasta' );
    my $fout = Bio::SeqIO->new( -file => ">$outdir/$prefix.fna", -format => 'fasta' );
    my $ncontig = 0;
    while ( my $seq = $fin->next_seq ) {
        if ( $seq->length < $mincontig ) {
            $self->msg( "Skipping short (<$mincontig bp) contig:", $seq->display_id );
            next;
        }
        $ncontig++;

        # http://www.ncbi.nlm.nih.gov/genomes/static/Annotation_pipeline_README.txt
        my $id = sprintf "contig%06d", $ncontig;
        $id = "$contig_uniq_id|$centre|$id" if $centre;
        $seq->display_id($id);
        my $s = $seq->seq;
        $s = uc($s);
        $s =~ s/[^ACTG]/N/g;
        $seq->seq($s);
        $seq->desc(undef);
        $fout->write_seq($seq);
        $seq{$id}{DNA} = $seq;
    }
    $self->msg("Wrote $ncontig contigs");

    #$self->msg(sort keys %seq); exit;

    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    # tRNA + tmRNA

    $self->msg("Predicting tRNAs and tmRNAs");
    my $cmd = "aragorn -gc$gcode -w $outdir/$prefix.fna";    # -t/-m
    $self->msg("Running: $cmd");
    my $num_trna = 0;
    open TRNA, "$cmd |";
    my $sid;
    while (<TRNA>) {
        chomp;
        if (m/^>end/) {
          last;
        }
        
        if (m/^>(\S+)/) {
            $sid = $1;
            next;
        }
        my @x = split m/\s+/;
        next unless @x == 5 and $x[0] =~ m/^\d+$/;

        # and $x[4] =~ m/^\([ATCG]{3}\)$/i;
        #$self->msg($_);
        $self->msg("@x");
        $x[2] =~ m/(c)?\[(\d+),(\d+)\]/;
        my ( $revcom, $start, $end ) = ( $1, $2, $3 );

        # bug fix for aragorn when revcom trna ends at start of contig!
        #  if (defined $revcom and $start > $end) {
        #    $self->msg("Activating kludge for Aragorn bug for tRNA end at contig start");
        #    $start = 1;
        #  }
        if ( $start > $end ) {
            $self->msg("tRNA $x[2] has start($start) > end ($end) - skipping.");
            next;
        }
        if ( abs( $end - $start ) > 500 ) {
            $self->msg("tRNA/tmRNA $x[2] is too big (>500bp) - skipping.");
            next;
        }

        # end kludge
        $num_trna++;

        my $ftype   = 'tRNA';
        my $product = $x[1] . $x[4];
        my @gene    = ();
        if ( $x[1] eq 'tmRNA' ) {
            $ftype   = $x[1];
            $product = "transfer-messenger RNA, SsrA";
            @gene    = ( 'gene' => 'ssrA' );
        }

        my $tool = "Aragorn:" . $tools{aragorn}->{VERSION};
        push @{ $seq{$sid}{FEATURE} }, Bio::SeqFeature::Generic->new(
            -primary => $ftype,                          # tRNA or tmRNA
            -seq_id  => $sid,
            -source  => $tool,
            -start   => $start,
            -end     => $end,
            -strand  => ( defined $revcom ? -1 : +1 ),
            -score   => undef,
            -frame   => 0,
            -tag     => {
                'product'   => $product,
                'inference' => "COORDINATES:profile:$tool",
                @gene,
            }
        );
    }
    $self->msg("Found $num_trna tRNAs");

    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    # rRNA

    if ( $kingdom ne 'Viruses' ) {
        $self->msg("Predicting Ribosomal RNAs");
        my $rnammerfn   = "$outdir/rnammer.xml";
        my $num_rrna    = 0;
        my $rnammer_opt = $cpus != 1 ? "-multi" : "";
        $self->runcmd("rnammer -S bac $rnammer_opt -xml $rnammerfn $outdir/$prefix.fna");
        my $xml = XML::Simple->new( ForceArray => 1 );
        my $data = $xml->XMLin($rnammerfn);
        for my $entry ( @{ $data->{entries}[0]->{entry} } ) {
            my $sid = $entry->{sequenceEntry}[0];
            next unless exists $seq{$sid};
            my $desc = $entry->{mol}[0];
            $desc =~ s/s_r/S ribosomal /i;    # make it English '23S_rRNA => 23S ribosomal RNA'
            $num_rrna++;
            my $tool = "RNAmmer:" . $tools{rnammer}->{VERSION};
            push @{ $seq{$sid}{FEATURE} }, Bio::SeqFeature::Generic->new(
                -primary => 'rRNA',
                -seq_id  => $sid,
                -source  => $tool,                    # $data->{predictor}[0]
                -start   => $entry->{start}[0],
                -end     => $entry->{stop}[0],
                -strand  => $entry->{direction}[0],
                -score   => undef,                    # $entry->{score}[0],
                -frame   => 0,
                -tag     => {
                    'product'   => $desc,
                    'inference' => "COORDINATES:profile:$tool",    # FIXME version
                }
            );
            $self->msg(
                join "\t", $num_rrna, $desc, $sid,
                $entry->{start}[0],
                $entry->{stop}[0],
                $entry->{direction}[0]
            );
        }
        $self->delfile($rnammerfn);
        $self->msg("Found $num_rrna rRNAs");
    }
    else {
        $self->msg("Disabling rRNA search for $kingdom.");
    }

    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    # ncRNA via Rfam + Infernal

    my $cmdb = "$dbdir/cm/$kingdom";
    if ( $rfam and -r "$cmdb.i1m" ) {
        $self->msg("Scanning for ncRNAs... please be patient.");

         my $cmscan_obj = Bio::AutomatedAnnotation::External::Cmscan->new(
           cmdb       => $cmdb,
           input_file => "$outdir/$prefix.fna",
           exec       => 'cmscan',
           version    => $tools{infernal}->{VERSION},
           cpus       => $cpus,
           evalue     => $evalue,
         );
        $cmscan_obj->add_features_to_prokka_structure(\%seq);
        
        $self->msg("Found ".$cmscan_obj->number_of_features." ncRNAs.");
    }
    else {
        $self->msg("Disabling ncRNA search, can't find $cmdb file.");
    }

    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    # Tally all the RNA features so we can exclude overlaps with CDS

    my @allrna;
    for my $sid ( sort keys %seq ) {
        push @allrna, ( grep { $_->primary_tag =~ m/RNA/ } @{ $seq{$sid}{FEATURE} } );
    }
    $self->msg( "Total of", scalar(@allrna), "RNA features" );

    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    # CDS

    $self->msg("Predicting coding sequences");
    my $totalbp = sum( map { $seq{$_}{DNA}->length } keys %seq );
    my $prodigal_mode = $totalbp >= 100000 ? 'single' : 'meta';
    $self->msg("Contigs total $totalbp bp, so using $prodigal_mode mode");
    my $num_cds = 0;
    $cmd = "prodigal -i $outdir/$prefix.fna -c -m -g $gcode -p $prodigal_mode -f sco -q";
    $self->msg("Running: $cmd");
    open CDS, "$cmd |";
    while (<CDS>) {

        if (m/seqhdr="([^\s\"]+)"/) {
            $sid = $1;

            #    $self->msg("CDS $sid");
            next;
        }
        elsif (m/^>\d+_(\d+)_(\d+)_([+-])$/) {
            my $tool = "Prodigal:" . $tools{prodigal}->{VERSION};
            my $cds  = Bio::SeqFeature::Generic->new(
                -primary => 'CDS',
                -seq_id  => $sid,
                -source  => $tool,
                -start   => $1,
                -end     => $2,
                -strand  => ( $3 eq '+' ? +1 : -1 ),
                -score   => undef,
                -frame   => 0,
                -tag     => {
                    'inference' => "ab initio prediction:$tool",
                }
            );
            my $overlap;
            for my $rna (@allrna) {

                # same contig, overlapping (could check same strand too? not sure)
                if ( $rna->seq_id eq $sid and $cds->overlaps($rna) ) {
                    $overlap = $rna;
                    last;
                }
            }
            if ($overlap) {
                $self->msg("Not including CDS which overlaps existing RNA at $sid:$1..$2 on $3 strand");
            }
            else {
                $num_cds++;
                push @{ $seq{$sid}{FEATURE} }, $cds;
            }
        }
    }
    $self->msg("Found $num_cds CDS");

    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    # Connect features to their parent sequences

    $self->msg("Connecting features back to sequences");
    for my $sid ( sort keys %seq ) {
        for my $f ( @{ $seq{$sid}{FEATURE} } ) {
            $f->attach_seq( $seq{$sid}{DNA} );
        }
    }

    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    # Find signal peptide leader sequences

    my $sigpver = substr $tools{signalp}{VERSION}, 0, 1;    # first char, expect 3 or 4

    if ( $kingdom eq 'Bacteria' and $sigpver == 3 || $sigpver == 4 ) {
        if ($gram) {
            $gram = $gram =~ m/\+|[posl]/i ? 'gram+' : 'gram-';
            $self->msg("Looking for signal peptides at start of predicted proteins");
            $self->msg("Treating $kingdom as $gram");
            my $spoutfn = "$outdir/signalp.faa";
            my $spout = Bio::SeqIO->new( -file => ">$spoutfn", -format => 'fasta' );
            my %cds;
            my $count = 0;
            for my $sid ( sort keys %seq ) {

                for my $f ( @{ $seq{$sid}{FEATURE} } ) {
                    next unless $f->primary_tag eq 'CDS';
                    $cds{ ++$count } = $f;
                    my $seq = $f->seq->translate;
                    $seq->display_id($count);
                    $spout->write_seq($seq);
                }
            }
            my $opts = $sigpver == 3 ? '-m hmm' : '';
            my $cmd = "signalp -t $gram -f short $opts $spoutfn 2> /dev/null";

            $self->msg("Running: $cmd");
            my $tool       = "SignalP:" . $tools{signalp}->{VERSION};
            my $num_sigpep = 0;
            open SIGNALP, "$cmd |";
            while (<SIGNALP>) {
                my @x = split m/\s+/;
                if ( $sigpver == 3 ) {
                    next unless @x == 7 and $x[6] eq 'Y';    # has sig_pep
                    my $parent = $cds{ $x[0] };
                    my $prob   = $x[5];
                    my $cleave = $x[3];
                    my $start  = $parent->strand > 0 ? $parent->start : $parent->end;
                    my $end    = $start + $parent->strand * ( $cleave - 1 );
                    my $sigpep = Bio::SeqFeature::Generic->new(
                        -seq_id     => $parent->seq_id,
                        -source_tag => $tool,
                        -primary    => 'sig_peptide',
                        -start      => min( $start, $end ),
                        -end        => max( $start, $end ),
                        -strand     => $parent->strand,
                        -frame      => 0,                     # PHASE: compulsory for peptides, can't be '.'
                        -tag        => {

                            #	  'ID' => $ID,
                            #	  'Parent' => $x[0],  # don't have proper IDs yet....
                            'product'   => "putative signal peptide",
                            'inference' => "ab initio prediction:$tool",
                            'note'      => "predicted cleavage at residue $x[3] with probability $prob",
                        }
                    );
                    push @{ $seq{ $parent->seq_id }{FEATURE} }, $sigpep;
                    $num_sigpep++;
                }
                else {
                    #        $self->msg("sigp$sigpver: @x");
                    next unless @x == 12 and $x[9] eq 'Y';    # has sig_pep
                    my $parent = $cds{ $x[0] };
                    my $cleave = $x[2];
                    my $start  = $parent->strand > 0 ? $parent->start : $parent->end;
                    my $end    = $start + $parent->strand * ( $cleave - 1 );
                    my $sigpep = Bio::SeqFeature::Generic->new(
                        -seq_id     => $parent->seq_id,
                        -source_tag => $tool,
                        -primary    => 'sig_peptide',
                        -start      => min( $start, $end ),
                        -end        => max( $start, $end ),
                        -strand     => $parent->strand,
                        -frame      => 0,                     # PHASE: compulsory for peptides, can't be '.'
                        -tag        => {

                            #	  'ID' => $ID,
                            #	  'Parent' => $x[0],  # don't have proper IDs yet....
                            'product'   => "putative signal peptide",
                            'inference' => "ab initio prediction:$tool",
                            'note'      => "predicted cleavage at residue $x[2]",
                        }
                    );
                    push @{ $seq{ $parent->seq_id }{FEATURE} }, $sigpep;
                    $num_sigpep++;
                }
            }
            $self->msg("Found $num_sigpep signal peptides");
            $self->delfile($spoutfn);
        }
        else {
            $self->msg("Option --gram not specified, will NOT check for signal peptides.");
        }
    }

    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    # Annotate CDS

    #my %dbof = ( 'PF'=>'Pfam', 'TIGR'=>'TIGRFAMs', 'PRK'=>'Cdd', 'COG'=>'COG' );

    # primary data source is a curated subset of uniprot (evidence <= 1 per Phylum)
    my @database = (
        {
            DB  => "$dbdir/kingdom/$kingdom/sprot",
            SRC => 'similar to AA sequence:UniProtKB:',
            FMT => 'blast',
            CMD => $BLASTPCMD,
        },
    );

    # secondary sources are a series of HMMs
    unless ( $kingdom eq 'Viruses' ) {
        for my $name (qw(CLUSTERS Cdd TIGRFAMs Pfam)) {
            push @database,
              {
                DB  => "$dbdir/hmm/$name.hmm",
                SRC => "protein motif:$name:",
                FMT => 'hmmer3',
                CMD => $HMMER3CMD,
              };
        }
    }

    # if --usegenus is enabled
    # AND user supplies a genus, and we have a custom file (from GenBank) do it first!
    if ($usegenus) {
        if ( $genus and -r "$dbdir/genus/$genus.pin" ) {
            my $blastdb = "$dbdir/genus/$genus";
            $self->msg("Using custom $genus database for annotation");
            unshift @database,
              {
                DB  => $blastdb,
                SRC => 'similar to AA sequence:RefSeq:',
                FMT => 'blast',
                CMD => $BLASTPCMD,
              };
        }
        else {
            $self->msg("Skipping genus-specific proteins as can't see $dbdir/$genus");
        }
    }
    else {
        $self->msg("Not using genus-specific database. Try --usegenus to enable it.");
    }

    # if user supplies a trusted set of proteins, we try these first!
    if ( -r $proteins ) {
        $self->msg("Preparing user-supplied primary annotation source: $proteins");
        $self->runcmd("makeblastdb -dbtype prot -in '$proteins' -out $outdir/proteins -logfile /dev/null");
        unshift @database,
          {
            DB  => "$outdir/proteins",
            SRC => 'similar to AA sequence:RefSeq:',
            FMT => 'blast',
            CMD => $BLASTPCMD,
          };
    }

    if ($fast) {
        $self->msg("Option --fast enabled, so skipping CDS similarity searches");
    }
    else {
        $self->msg("Annotating CDS, please be patient.");

        my $paropts = $cpus > 0 ? " -j $cpus" : "";
        $self->msg( "Will use", ( $cpus > 0 ? $cpus : 'all available' ), "CPUs for similarity searching." );

        my $num_cleaned = 0;
        my %cds;
        my $count = 0;

        for my $sid ( sort keys %seq ) {
            for my $f ( @{ $seq{$sid}{FEATURE} } ) {
                next unless $f->primary_tag eq 'CDS';
                next if $f->has_tag('product');
                $cds{ ++$count } = $f;
            }
        }

        if ( $count > 0 ) {

            # Minimise the number of files created at a time. Tradeoff with efficiency of parallelisation.
            # This creates X files per CPU.
            my $slice_size = ( ( $cpus > 0 ) ? $cpus : 1 ) * ( ( $files_per_chunk <= 0 ) ? 10 : $files_per_chunk );
            my @cds_counter = sort( keys %cds );
            for ( my $i = 0 ; $i < ceil( (@cds_counter) / $slice_size ) ; $i++ ) {
                for ( my $j = $slice_size * $i ; $j < @cds_counter && $j < $slice_size * ( $i + 1 ) ; $j++ ) {
                    $self->create_cds_sequences_in_file( $tempdir, $cds_counter[$j], $cds{ $cds_counter[$j] } );
                }

                for my $db (@database) {
                    my $cmd = $db->{CMD};
                    $cmd =~ s/%i/{}/g;
                    $cmd =~ s/%o/{}.out/g;
                    $cmd =~ s/%e/$evalue/g;
                    $cmd =~ s,%d,$db->{DB},g;
                    $self->msg( $db->{FMT}, "$count (of $num_cds) proteins against", $db->{DB} );

                    $self->runcmd("nice parallel$paropts $cmd ::: $tempdir/*.seq");

                    for ( my $j = $slice_size * $i ; $j < @cds_counter && $j < $slice_size * ( $i + 1 ) ; $j++ ) {
                        my $pid = $cds_counter[$j];
                        my $bls = Bio::SearchIO->new( -file => "$tempdir/$pid.seq.out", -format => $db->{FMT} );
                        my $res = $bls->next_result or next;
                        my $hit = $res->next_hit or next;
                        my ( $prod, $gene, $EC ) = ( $hit->description, '', '' );
                        if ( $prod =~ m/~~~/ ) {
                            ( $EC, $gene, $prod ) = split m/~~~/, $prod;
                            $EC =~ s/n\d+/-/g;    # collapse transitionary EC numbers
                        }
                        my $cleanprod = $prod;

                        if ( $self->cleanup_prod ) {
                            $cleanprod = $self->cleanup_product($prod);
                            if ( $cleanprod ne $prod ) {
                                $self->msg("Modify product: $prod => $cleanprod");
                                if ( $cleanprod eq $HYPO ) {
                                    $cds{$pid}->add_tag_value( 'note', $prod );
                                    $cds{$pid}->remove_tag('gene')      if $cds{$pid}->has_tag('gene');
                                    $cds{$pid}->remove_tag('EC_number') if $cds{$pid}->has_tag('EC_number');
                                }
                                $num_cleaned++;
                            }
                        }
                        $cds{$pid}->add_tag_value( 'product', $cleanprod );
                        $cds{$pid}->add_tag_value( 'EC_number', $EC ) if $EC;

                        if ( defined($gene)  && $gene ne "" && !$cds{$pid}->has_tag('gene') ) {
                            $cds{$pid}->add_tag_value( 'gene', $gene );
                        }
                        $cds{$pid}->add_tag_value( 'inference', $db->{SRC} . $hit->name );

                        unlink "$tempdir/$pid.seq.out";
                    }
                }
                unlink map { "$tempdir/$_.seq" } keys %cds;
                unlink map { "$tempdir/$_.seq.out" } keys %cds;
            }

            unlink map { "$tempdir/$_.seq" } keys %cds;
            unlink map { "$tempdir/$_.seq.out" } keys %cds;

            $self->msg("Cleaned $num_cleaned /product names") if $num_cleaned > 0;
        }
    }

    if ($proteins) {
        $self->delfile( map { "$outdir/proteins.$_" } qw(psq phr pin) );
    }

    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    # Label unannotated proteins as 'hypothetical protein'

    my $empty_label = $fast ? 'unannotated protein' : $HYPO;
    my $num_hypo = 0;
    for my $sid ( sort keys %seq ) {
        for my $f ( @{ $seq{$sid}{FEATURE} } ) {
            if ( $f->primary_tag eq 'CDS' and not $f->has_tag('product') ) {
                $f->add_tag_value( 'product', $empty_label );
                $num_hypo++;
            }
        }
    }
    $self->msg("Labelling remaining $num_hypo proteins as '$empty_label'") if $num_hypo > 0;

    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    # Look for possible /pseudo genes - adjacent with same annotation

    for my $sid ( sort keys %seq ) {
        my $prev = '';
        for my $f ( grep { $_->primary_tag eq 'CDS' } @{ $seq{$sid}{FEATURE} } ) {
            my $this = $self->tag( $f, 'product' );
            if ( $this eq $prev and $this ne $HYPO and $this ne $UNANN ) {
                $self->msg( "Possible /pseudo '$prev' at", $f->seq_id, 'position', $f->start );
            }
            $prev = $this;
            $this = '';
        }
    }

    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    # Fix colliding /gene names in CDS (before we add 'gene' features)
    # (this could be written as such a nice map/map/grep one day...)

    my %collide;

    for my $sid ( sort keys %seq ) {
        for my $f ( sort { $a->start <=> $b->start } @{ $seq{$sid}{FEATURE} } ) {
            next unless $f->primary_tag eq 'CDS';
            my $gene = $self->tag( $f, 'gene' ) or next;
            push @{ $collide{$gene} }, $f;
        }
    }
    $self->msg( "Found", scalar( keys(%collide) ), "unique /gene codes." );

    my $num_collide = 0;
    for my $gene ( keys %collide ) {
        my @cds = @{ $collide{$gene} };
        next unless @cds > 1;
        my $n = 0;
        for my $f (@cds) {
            $f->remove_tag('gene');
            $n++;
            $f->add_tag_value( 'gene', "${gene}_${n}" );
        }
        $num_collide++;
    }
    $self->msg("Fixed $num_collide colliding /gene names.");

    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    # Add locus_tags and protein_id[CDS only] (and Parent genes if asked)

    my $num_lt = 0;
    for my $sid ( sort keys %seq ) {
        for my $f ( sort { $a->start <=> $b->start } @{ $seq{$sid}{FEATURE} } ) {
            next unless $f->primary_tag =~ m/CDS|RNA/;
            $num_lt++;
            my $ID = sprintf( "${locustag}_%05d", $num_lt * $increment );
            $f->add_tag_value( 'ID',         $ID );
            $f->add_tag_value( 'locus_tag',  $ID );
            $f->add_tag_value( 'protein_id', "gnl|$centre|$ID" ) if $f->primary_tag eq 'CDS';
            if ($addgenes) {
                my $g = $f->clone;
                $g->primary_tag('gene');
                $g->source_tag($EXE);
                $g->remove_tag($_) for $g->get_all_tags;
                $g->add_tag_value( 'locus_tag', $ID );
                if ( my $gENE = $self->tag( $f, 'gene' ) ) {
                    $g->add_tag_value( 'gene', $gENE );
                }
                push @{ $seq{$sid}{FEATURE} }, $g;
            }
        }
    }
    $self->msg("Assigned $num_lt locus_tags to CDS and RNA features.");

    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    # Write it all out!

    $self->msg("Writing outputs to $outdir/");
    open my $gff_fh, '>', "$outdir/$prefix.gff";
    my $faa_fh = Bio::SeqIO->new( -file => ">$outdir/$prefix.faa", -format => 'fasta' );
    my $ffn_fh = Bio::SeqIO->new( -file => ">$outdir/$prefix.ffn", -format => 'fasta' );
    open my $tbl_fh, '>', "$outdir/$prefix.tbl";
    my $fsa_fh = Bio::SeqIO->new( -file => ">$outdir/$prefix.fsa", -format => 'fasta' );

    my $gff_factory = Bio::Tools::GFF->new( -gff_version => $gffver );
    print $gff_fh "##gff-version $gffver\n";
    for my $id ( sort keys %seq ) {
        print $gff_fh "##sequence-region $id 1 ", $seq{$id}{DNA}->length, "\n";
    }

    my $fsa_desc = "[gcode=$gcode] [organism=$genus $species] [strain=$strain]";

    for my $sid ( sort keys %seq ) {
        my $ctg = $seq{$sid}{DNA};
        $ctg->desc($fsa_desc);
        $fsa_fh->write_seq($ctg);
        $ctg->desc(undef);
        print $tbl_fh ">Feature $sid\n";
        for my $f ( sort { $a->start <=> $b->start } @{ $seq{$sid}{FEATURE} } ) {
            if ( $f->primary_tag eq 'CDS' and not $f->has_tag('product') ) {
                $f->add_tag_value( 'product', $HYPO );
            }

            print $gff_fh $f->gff_string($gff_factory), "\n";

            my ( $L, $R ) = ( $f->strand >= 0 ) ? ( $f->start, $f->end ) : ( $f->end, $f->start );
            print {$tbl_fh} "$L\t$R\t", $f->primary_tag, "\n";
            for my $tag ( $f->get_all_tags ) {
                next if $tag =~ m/^(ID|Alias)$/;    # remove GFF specific tags
                for my $value ( $f->get_tag_values($tag) ) {
                    print {$tbl_fh} "\t\t\t$tag\t$value\n";
                }
            }

            my $p = $seq{$sid}{DNA}->trunc( $f->location );
            $p->display_id( $self->tag( $f, 'locus_tag' ) );
            $p->desc( $self->tag( $f, 'product' ) ) if $f->has_tag('product');
            unless ( $addgenes and $f->primary_tag eq 'gene' ) {
                $ffn_fh->write_seq($p);
            }
            if ( $f->primary_tag eq 'CDS' ) {
                $faa_fh->write_seq( $p->translate( -codontable_id => $gcode ) );
            }
        }
    }

    if ( scalar keys %seq ) {
        print $gff_fh "##FASTA\n";
        my $seqio = Bio::SeqIO->new( -fh => $gff_fh, -format => 'fasta' );
        for my $sid ( sort keys %seq ) {
            $seqio->write_seq( $seq{$sid}{DNA} );
        }
    }

    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    # Use tbl2asn tool to make .gbk and .sqn for us

    $self->msg("Generating Genbank and Sequin files");
    $self->runcmd(
"tbl2asn -N 1 -y 'Annotated using $EXE $VERSION from $URL' -Z $outdir/$prefix.err -M n -V b -i $outdir/$prefix.fsa -f $outdir/$prefix.tbl 2> /dev/null"
    );
    $self->delfile("$outdir/errorsummary.val");
    $self->delfile( map { "$outdir/$prefix.$_" } qw(dr fixedproducts ecn val) );
    move( "$outdir/$prefix.gbf", "$outdir/$prefix.gbk" );    # rename XXX.gbf to XXX.gbk

    # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
    # Some final log output

    $self->msg("Output files:");
    foreach (qx(find $outdir -type f -name "$prefix.*")) {
        chomp;
        $self->msg($_);
    }
    my $endtime  = localtime;
    my $walltime = $endtime - $starttime;

    #$self->msg("Walltime used:", $walltime->pretty);  # Heikki says this method only came with 1.20
    my $pretty = sprintf "%.2f minutes", $walltime->minutes;
    $self->msg("Walltime used: $pretty");
    $self->msg( $walltime % 2 ? "Share and enjoy!" : "Thank you, come again." );

    #EXIT

}

sub cleanup_product {
    my ( $self, $p ) = @_;
    return $self->hypo if $p =~ m/DUF\d|UPF\d|conserved|domain of unknown|[CN].term|homolog|paralog/i;
    return $self->hypo if $p !~ m/[a-z]/;

    $p =~ s/\((EC|COG).*?\)//;
    $p =~ s/\s*\w+\d{4,}//;    # remove possible locus tags
    $p =~ s/ and (inactivated|related) \w+//;

    $p =~ s/^(possible|probable|predicted|uncharacteri.ed)/putative/i;
    if ( $p =~ m/(domain|family|binding|fold|like)\s*$/i and $p !~ m/,/ ) {
        $p .= " protein";
    }
    return $p;
}

sub tag {
    my ( $self, $f, $tag ) = @_;
    return unless $f->has_tag($tag);
    return ( $f->get_tag_values($tag) )[0];
}

sub require_exe {
    my ( $self, $bin ) = @_;
    for my $dir ( File::Spec->path ) {
        my $exe = File::Spec->catfile( $dir, $bin );
        return $exe if -x $exe;
    }
    return;
}

sub msg {
    my ( $self, @message ) = @_;
    my $t    = localtime;
    my $line = "[" . $t->hms . "] @message\n";
    print LOG $line if openhandle( \*LOG );
    print STDERR $line unless $self->quiet;
}

sub err {
    my ( $self, @message ) = @_;
    $self->quiet(0);
    $self->msg(@message);
    exit(2);
}

sub runcmd {
    my ( $self, @command_to_run ) = @_;
    $self->msg( "Running:", @command_to_run );
    system(@command_to_run) == 0 or $self->err( "Could not run command:", @command_to_run );
}

sub delfile {
    my ( $self, @files_to_delete ) = @_;
    for my $file (@files_to_delete) {
        $self->msg( "Deleting temporary file:", $file );
        unlink $file;
    }
}

sub create_cds_sequences_in_file {
    my ( $self, $outdir, $count, $feature ) = @_;
    open my $fout, '>', "$outdir/$count.seq";
    print $fout ">$count\n", $feature->seq->translate->seq, "\n";
    close $fout;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Bio::AutomatedAnnotation::Prokka - Prokka class for bacterial annotation

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

    Modified prokka from a command line script to a Moose class - Bacterial annotation done fast and NCBI compliant (mostly).
    http://www.vicbioinformatics.com/software.prokka.shtml
    
    If you use Prokka in your work, please cite:

        Seemann T (2012)
        Prokka: Prokaryotic Genome Annotation System
        http://vicbioinformatics.com/

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
