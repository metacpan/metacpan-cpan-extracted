package App::Egaz::Command::template;
use strict;
use warnings;
use autodie;

use App::Egaz -command;
use App::Egaz::Common;

sub abstract {
    return 'create executing bash files';
}

sub opt_spec {
    return (
        [   "mode" => hidden => {
                default => "multi",
                one_of  => [
                    [ "multi" => "multiple genome alignments, orthologs" ],
                    [ "self"  => "self genome alignments, paralogs" ],
                    [ "prep"  => "prepare sequences" ],
                ],
            }
        ],
        [],
        [ "outdir|o=s",   "Output directory",  { default => "." }, ],
        [ "queue=s",      "QUEUE_NAME",        { default => "mpi" }, ],
        [ "separate",     "separate each Target-Query groups", ],
        [ "tmp=s",        "user defined tempdir", ],
        [ "parallel|p=i", "number of threads", { default => 2 }, ],
        [ "verbose|v",    "verbose mode", ],
        [],
        [ "length=i", "minimal length of alignment fragments",  { default => 1000 }, ],
        [ "msa=s",    "aligning program for refine alignments", { default => "mafft" }, ],
        [ "taxon=s",  "taxon.csv for this project", ],
        [ "aligndb",  "create aligndb scripts", ],
        [],
        [ "multiname=s", "naming multiply alignment", ],
        [ "outgroup=s",  "the name of outgroup", ],
        [ "tree=s",      "a predefined guiding tree for multiz", ],
        [ "order",       "multiple alignments with original order (using fake_tree.nwk)", ],
        [ "rawphylo",    "create guiding tree by joining pairwise alignments", ],
        [ "vcf",         "create vcf files", ],
        [],
        [ "noblast", "don't blast paralogs against genomes", ],
        [ "circos",  "create circos script", ],
        [],
        [ "repeatmasker=s", "options passed to RepeatMasker", ],
        [ "perseq=s@",      "split these files by names", ],
        [ "min=i",   "minimal length of sequences",                      { default => 5000 }, ],
        [ "about=i", "split sequences to chunks about approximate size", { default => 5000000 }, ],
        [   "suffix=s@",
            "suffix of wanted files",
            { default => [ "_genomic.fna.gz", ".fsa_nt.gz" ] },
        ],
        [ "exclude=s", "regex to exclude some files", { default => "_from_" }, ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "egaz template [options] <path/seqdir> [more path/seqdir]";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

* <path/seqdir> are directories containing multiple .fa files that represent genomes
* Each .fa files in <path/target> should contain only one sequences, otherwise second or latter sequences will be omitted
* Species/strain names in result files are the basenames of <path/seqdir>
* Default --multiname is the basename of --outdir. This option is for more than one aligning combinations
* without --tree and --rawphylo, the order of multiz stitch is the same as the one from command line
* --outgroup uses basename, not full path. *DON'T* set --outgroup to target
* --taxon may also contain unused taxons, for constructing chr_length.csv
* --preq is designed for NCBI ASSEMBLY and WGS, <path/seqdir> are directories containing multiple
    directories

MARKDOWN

    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} < 1 ) {
        my $message = "This command need one or more directories.\n\tIt found";
        $message .= sprintf " [%s]", $_ for @{$args};
        $message .= ".\n";
        $self->usage_error($message);
    }
    for ( @{$args} ) {
        if ( !Path::Tiny::path($_)->is_dir ) {
            $self->usage_error("The input directory [$_] doesn't exist.");
        }
    }

    if ( $opt->{mode} eq "multi" and @{$args} < 2 ) {
        $self->usage_error("Multiple alignments need at least 2 directories");
    }

    if ( $opt->{tree} ) {
        if ( !Path::Tiny::path( $opt->{tree} )->is_file ) {
            $self->usage_error("The tree file [$opt->{tree}] doesn't exist.");
        }
        else {
            $opt->{tree} = Path::Tiny::path( $opt->{tree} )->absolute()->stringify();
        }
    }

    if ( $opt->{taxon} ) {
        if ( !Path::Tiny::path( $opt->{taxon} )->is_file ) {
            $self->usage_error("The taxon file [$opt->{taxon}] doesn't exist.");
        }
        else {
            $opt->{taxon} = Path::Tiny::path( $opt->{taxon} )->absolute()->stringify();
        }

    }

    $opt->{outdir} = Path::Tiny::path( $opt->{outdir} )->absolute()->stringify();

    if ( !$opt->{multiname} ) {
        $opt->{multiname} = Path::Tiny::path( $opt->{outdir} )->basename();
    }

    $opt->{parallel2} = int( $opt->{parallel} / 2 );
    $opt->{parallel2} = 2 if $opt->{parallel2} < 2;

}

sub execute {
    my ( $self, $opt, $args ) = @_;

    print STDERR "Create templates for [$opt->{mode}] genome alignments\n";

    #----------------------------#
    # prepare working dir
    #----------------------------#
    $opt->{outdir} = Path::Tiny::path( $opt->{outdir} )->absolute();
    $opt->{outdir}->mkpath();
    $opt->{outdir} = $opt->{outdir}->stringify();
    print STDERR "Working directory [$opt->{outdir}]\n";

    if ( $opt->{mode} eq "multi" ) {
        Path::Tiny::path( $opt->{outdir}, 'Pairwise' )->mkpath();
        Path::Tiny::path( $opt->{outdir}, 'Results' )->mkpath();
    }
    elsif ( $opt->{mode} eq "self" ) {
        Path::Tiny::path( $opt->{outdir}, 'Pairwise' )->mkpath();
        Path::Tiny::path( $opt->{outdir}, 'Processing' )->mkpath();
        Path::Tiny::path( $opt->{outdir}, 'Results' )->mkpath();
        Path::Tiny::path( $opt->{outdir}, 'Circos' )->mkpath();
    }

    $args = [ map { Path::Tiny::path($_)->absolute()->stringify() } @{$args} ];

    #----------------------------#
    # names and directories
    #----------------------------#
    print STDERR "Associate names and directories\n";
    my @data;
    {
        my %taxon_of;
        if ( $opt->{taxon} ) {
            for my $line ( Path::Tiny::path( $opt->{taxon} )->lines ) {
                my @fields = split /,/, $line;
                if ( $#fields >= 2 ) {
                    $taxon_of{ $fields[0] } = $fields[1];
                }
            }
        }
        @data = map {
            {   dir   => $_,
                name  => Path::Tiny::path($_)->basename(),
                taxon => exists $taxon_of{ Path::Tiny::path($_)->basename() }
                ? $taxon_of{ Path::Tiny::path($_)->basename() }
                : 0,
            }
        } @{$args};
    }

    # move $opt->{outgroup} to last
    if ( $opt->{mode} eq "multi" and $opt->{outgroup} ) {
        my ($exist) = grep { $_->{name} eq $opt->{outgroup} } @data;
        if ( !defined $exist ) {
            Carp::confess "--outgroup [$opt->{outgroup}] does not exist!\n";
        }

        @data = grep { $_->{name} ne $opt->{outgroup} } @data;
        push @data, $exist;
    }
    $opt->{data} = \@data;    # store in $opt

    print STDERR YAML::Syck::Dump( $opt->{data} ) if $opt->{verbose} and $opt->{mode} ne "prep";

    # If there's no phylo tree, generate a fake one.
    if ( $opt->{mode} eq "multi" and !$opt->{tree} ) {
        print STDERR "Create fake_tree.nwk\n";
        my $fh = Path::Tiny::path( $opt->{outdir}, "fake_tree.nwk" )->openw;
        print {$fh} "(" x ( scalar(@data) - 1 ) . "$data[0]->{name}";
        for my $i ( 1 .. $#data ) {
            print {$fh} ",$data[$i]->{name})";
        }
        print {$fh} ";\n";
        close $fh;
    }

    #----------------------------#
    # prep *.sh files
    #----------------------------#
    $self->gen_prep( $opt, $args );

    #----------------------------#
    # multi *.sh files
    #----------------------------#
    $self->gen_pair( $opt, $args );
    $self->gen_rawphylo( $opt, $args );
    $self->gen_multi( $opt, $args );
    $self->gen_vcf( $opt, $args );

    #----------------------------#
    # self *.sh files
    #----------------------------#
    $self->gen_self( $opt, $args );
    $self->gen_proc( $opt, $args );
    $self->gen_circos( $opt, $args );

    $self->gen_aligndb( $opt, $args );
    $self->gen_packup( $opt, $args );

}

sub gen_prep {
    my ( $self, $opt, $args ) = @_;

    return unless $opt->{mode} eq "prep";

    my @patterns = map {"*$_"} @{ $opt->{suffix} };
    my %perseq = map { $_ => 1, } @{ $opt->{perseq} };

    my @files;
    for ( @{$args} ) {
        push @files, File::Find::Rule->file->name(@patterns)->in($_);
    }

    {
        @files = grep { !/$opt->{exclude}/ } @files;
        @files = map  { Path::Tiny::path($_)->absolute()->stringify } @files;
        @files = map {
            {   basename => Path::Tiny::path($_)->parent()->basename(),
                perseq   => exists $perseq{ Path::Tiny::path($_)->parent()->basename() } ? 1 : 0,
                file     => $_,
            }
        } @files;

        print STDERR YAML::Syck::Dump \@files if $opt->{verbose};
    }

    my $tt = Template->new( INCLUDE_PATH => [ File::ShareDir::dist_dir('App-Egaz') ], );
    my $template;
    my $sh_name;

    $sh_name = "0_prep.sh";
    print STDERR "Create $sh_name\n";
    $template = <<'EOF';
[% INCLUDE header.tt2 %]

#----------------------------#
# [% sh %]
#----------------------------#
log_warn [% sh %]

[% FOREACH item IN files -%]
log_info [% item.basename %]

if [ -d [% item.basename %] ]; then
    log_debug "[% item.basename %] presents"
else
    log_debug Processing [% item.file %]

    egaz prepseq \
        [% item.file %] \
[% IF not item.perseq -%]
        --about [% opt.about %] \
[% END -%]
[% IF opt.repeatmasker -%]
        --repeatmasker "[% opt.repeatmasker %]" \
[% END -%]
        --min [% opt.min %] --gi -v \
        -o [% opt.outdir %]/[% item.basename %]
fi

[% END -%]

exit;

EOF
    $tt->process(
        \$template,
        {   args  => $args,
            opt   => $opt,
            files => \@files,
            sh    => $sh_name,
        },
        Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
    ) or Carp::confess Template->error;

}

sub gen_aligndb {
    my ( $self, $opt, $args ) = @_;

    return unless ( $opt->{mode} eq "multi" or $opt->{mode} eq "self" ) and $opt->{aligndb};

    my $tt = Template->new( INCLUDE_PATH => [ File::ShareDir::dist_dir('App-Egaz') ], );
    my $template;
    my $sh_name;

    $sh_name = "6_chr_length.sh";
    print STDERR "Create $sh_name\n";
    $template = <<'EOF';
[% INCLUDE header.tt2 %]

#----------------------------#
# [% sh %]
#----------------------------#
log_warn [% sh %]

mkdir -p Results;

echo "common_name,taxon_id,chr,length,assembly" > Results/chr_length.csv

[% FOREACH item IN opt.data -%]
# [% item.name %]
perl -nla -F"\t" -e '
    print qq{[% item.name %],[% item.taxon %],$F[0],$F[1],}
    ' \
    [% item.dir %]/chr.sizes \
    >> Results/chr_length.csv;

[% END -%]

log_info chr_length.csv generated

exit;

EOF
    $tt->process(
        \$template,
        {   args => $args,
            opt  => $opt,
            sh   => $sh_name,
        },
        Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
    ) or Carp::confess Template->error;

    if ( $opt->{mode} eq "multi" ) {
        $sh_name = "7_multi_aligndb.sh";
        print STDERR "Create $sh_name\n";
        $template = <<'EOF';
[% INCLUDE header.tt2 %]

#----------------------------#
# [% sh %]
#----------------------------#
log_warn [% sh %]

mkdir -p Results;

cd Results

#----------------------------#
# Create anno.yml
#----------------------------#
log_info create anno.yml

if [ -e [% opt.data.0.dir -%]/anno.yml ]; then
    cp [% opt.data.0.dir -%]/anno.yml anno.yml;
else
    if [ -e [% opt.data.0.dir -%]/cds.yml ]; then
        cp [% opt.data.0.dir -%]/cds.yml cds.yml;
    else
        runlist gff --tag CDS --remove \
            [% opt.data.0.dir -%]/*.gff \
            -o cds.yml
    fi

    if [ -e [% opt.data.0.dir -%]/repeat.yml ]; then
        cp [% opt.data.0.dir -%]/repeat.yml repeat.yml;
    else
        runlist gff --remove \
            [% opt.data.0.dir -%]/*.rm.gff \
            -o repeat.yml
    fi

    # create empty cds.yml or repeat.yml
    runlist genome [% opt.data.0.dir -%]/chr.sizes -o chr.yml
    runlist compare --op diff chr.yml chr.yml -o empty.yml

    for type in cds repeat; do
        if [ ! -e ${type}.yml ]; then
            cp empty.yml ${type}.yml
        fi
    done

    runlist merge \
        cds.yml repeat.yml \
        -o anno.yml

    rm -f repeat.yml cds.yml chr.yml empty.yml
fi

#----------------------------#
# alignDB.pl
#----------------------------#
log_info run alignDB.pl

alignDB.pl \
    -d [% opt.multiname %] \
    --da [% opt.outdir %]/[% opt.multiname %]_refined \
    -a [% opt.outdir %]/Results/anno.yml \
[% IF opt.outgroup -%]
    --outgroup \
[% END -%]
    --chr [% opt.outdir %]/Results/chr_length.csv \
    --lt [% opt.length %] --parallel [% opt.parallel %] --batch 10 \
    --run 1,2,5,10,21,30-32,40-42,44

exit;

EOF
        $tt->process(
            \$template,
            {   args => $args,
                opt  => $opt,
                sh   => $sh_name,
            },
            Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
        ) or Carp::confess Template->error;
    }
    elsif ( $opt->{mode} eq "self" ) {
        $sh_name = "7_self_aligndb.sh";
        print STDERR "Create $sh_name\n";
        $template = <<'EOF';
[% INCLUDE header.tt2 %]

#----------------------------#
# [% sh %]
#----------------------------#
log_warn [% sh %]

mkdir -p Results;

cd Results

#----------------------------#
# [% opt.multiname %]
#----------------------------#
# steal multiname from --multi

log_info init_alignDB

alignDB.pl \
    -d [% opt.multiname %]_self \
    --chr [% opt.outdir %]/Results/chr_length.csv \
    --run 1


#----------------------------#
# gen_alignDB.pl
#----------------------------#
# gen_alignDB to existing database

log_info gen_alignDB

[% FOREACH item IN opt.data -%]
# [% item.name %]
alignDB.pl \
    -d [% opt.multiname %]_self \
    --da [% opt.outdir %]/Results/[% item.name %]/[% item.name %].pair.fas \
    --lt 1000 --parallel [% opt.parallel %] \
    --run 2

[% END -%]

#----------------------------#
# rest steps
#----------------------------#
alignDB.pl \
    -d [% opt.multiname %]_self \
    --parallel [% opt.parallel %] --batch 10 \
    --run 5,10,21,30-32,40,42,44

exit;

EOF
        $tt->process(
            \$template,
            {   args => $args,
                opt  => $opt,
                sh   => $sh_name,
            },
            Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
        ) or Carp::confess Template->error;

    }
}

sub gen_packup {
    my ( $self, $opt, $args ) = @_;

    return unless ( $opt->{mode} eq "multi" or $opt->{mode} eq "self" );

    my $tt = Template->new( INCLUDE_PATH => [ File::ShareDir::dist_dir('App-Egaz') ], );
    my $template;
    my $sh_name;

    $sh_name = "9_pack_up.sh";
    print STDERR "Create $sh_name\n";
    $template = <<'EOF';
[% INCLUDE header.tt2 %]

#----------------------------#
# [% sh %]
#----------------------------#
log_warn [% sh %]

find . -type f |
    grep -v -E "\.(sh|2bit)$" |
    grep -v -E "(_fasta|_raw)\/" |
    grep -v -F "fake_tree.nwk" \
    > file_list.txt

tar -czvf [% opt.multiname %].tar.gz -T file_list.txt

log_info [% opt.multiname %].tar.gz generated

exit;

EOF
    $tt->process(
        \$template,
        {   args => $args,
            opt  => $opt,
            sh   => $sh_name,
        },
        Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
    ) or Carp::confess Template->error;

}

sub gen_pair {
    my ( $self, $opt, $args ) = @_;

    return unless $opt->{mode} eq "multi";

    my $tt = Template->new( INCLUDE_PATH => [ File::ShareDir::dist_dir('App-Egaz') ], );
    my $template;
    my $sh_name;

    $sh_name = "1_pair.sh";
    print STDERR "Create $sh_name\n";
    $template = <<'EOF';
[% INCLUDE header.tt2 %]

#----------------------------#
# [% sh %]
#----------------------------#
log_warn [% sh %]

mkdir -p Pairwise

[% FOREACH item IN opt.data -%]
[% IF loop.first -%]
# Target [% item.name %]

[% ELSE -%]
[% t = opt.data.0.name -%]
[% q = item.name -%]
if [ -e Pairwise/[% t %]vs[% q %] ]; then
    log_info Skip Pairwise/[% t %]vs[% q %]
else
    log_info lastz Pairwise/[% t %]vs[% q %]
    egaz lastz \
        --set set01 -C 0 --parallel [% opt.parallel %] --verbose \
        [% opt.data.0.dir %] [% item.dir %] \
        -o Pairwise/[% t %]vs[% q %]

    log_info lpcnam Pairwise/[% t %]vs[% q %]
    egaz lpcnam \
        --syn --parallel [% opt.parallel %] --verbose \
        [% opt.data.0.dir %] [% item.dir %] Pairwise/[% t %]vs[% q %]
fi

[% END -%]
[% END -%]

exit;

EOF
    $tt->process(
        \$template,
        {   args => $args,
            opt  => $opt,
            sh   => $sh_name,
        },
        Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
    ) or Carp::confess Template->error;
}

sub gen_rawphylo {
    my ( $self, $opt, $args ) = @_;

    return unless $opt->{mode} eq "multi" and $opt->{rawphylo};

    my $tt = Template->new( INCLUDE_PATH => [ File::ShareDir::dist_dir('App-Egaz') ], );
    my $template;
    my $sh_name;

    $sh_name = "2_rawphylo.sh";
    print STDERR "Create $sh_name\n";
    $template = <<'EOF';
[% INCLUDE header.tt2 %]

#----------------------------#
# [% sh %]
#----------------------------#
log_warn [% sh %]

if [ -e Results/[% opt.multiname %].raw.nwk ]; then
    log_info Results/[% opt.multiname %].raw.nwk exists
    exit;
fi

mkdir -p [% opt.multiname %]_raw
mkdir -p Results

#----------------------------#
# maf2fas
#----------------------------#
log_info Convert maf to fas

[% FOREACH item IN opt.data -%]
[% IF not loop.first -%]
[% t = opt.data.0.name -%]
[% q = item.name -%]
log_debug "    [% t %]vs[% q %]"
mkdir -p [% opt.multiname %]_raw/[% t %]vs[% q %]

find Pairwise/[% t %]vs[% q %] -name "*.maf" -or -name "*.maf.gz" |
    parallel --no-run-if-empty -j 1 \
        fasops maf2fas {} -o [% opt.multiname %]_raw/[% t %]vs[% q %]/{/}.fas

fasops covers \
    [% opt.multiname %]_raw/[% t %]vs[% q %]/*.fas \
    -n [% t %] -l [% opt.length %] -t 10 \
    -o [% opt.multiname %]_raw/[% t %]vs[% q %].yml

[% END -%]
[% END -%]

[% IF opt.data.size > 2 -%]
#----------------------------#
# Intersect
#----------------------------#
log_info Intersect

runlist compare --op intersect \
[% FOREACH item IN opt.data -%]
[% IF not loop.first -%]
[% t = opt.data.0.name -%]
[% q = item.name -%]
    [% opt.multiname %]_raw/[% t %]vs[% q %].yml \
[% END -%]
[% END -%]
    -o stdout |
    runlist span stdin \
        --op excise -n [% opt.length %] \
        -o [% opt.multiname %]_raw/intersect.yml
[% END -%]

#----------------------------#
# Coverage
#----------------------------#
log_info Coverage

runlist merge [% opt.multiname %]_raw/*.yml \
    -o stdout |
    runlist stat stdin \
        -s [% args.0 %]/chr.sizes \
        --all --mk \
        -o Results/pairwise.coverage.csv

[% IF opt.data.size > 2 -%]
#----------------------------#
# Slicing
#----------------------------#
log_info Slicing with intersect

[% FOREACH item IN opt.data -%]
[% IF not loop.first -%]
[% t = opt.data.0.name -%]
[% q = item.name -%]
log_debug "    [% t %]vs[% q %]"
if [ -e [% opt.multiname %]_raw/[% t %]vs[% q %].slice.fas ]; then
    rm [% opt.multiname %]_raw/[% t %]vs[% q %].slice.fas
fi
find [% opt.multiname %]_raw/[% t %]vs[% q %]/ -name "*.fas" -or -name "*.fas.gz" |
    sort |
    parallel --no-run-if-empty --keep-order -j 1 ' \
        fasops slice {} \
            [% opt.multiname %]_raw/intersect.yml \
            -n [% t %] -l [% opt.length %] -o stdout \
            >> [% opt.multiname %]_raw/[% t %]vs[% q %].slice.fas
        '

[% END -%]
[% END -%]

[% END -%]

#----------------------------#
# Joining
#----------------------------#
log_info Joining intersects

log_debug "    fasops join"
fasops join \
[% FOREACH item IN opt.data -%]
[% IF not loop.first -%]
[% t = opt.data.0.name -%]
[% q = item.name -%]
    [% opt.multiname %]_raw/[% t %]vs[% q %].slice.fas \
[% END -%]
[% END -%]
    -n [% opt.data.0.name %] \
    -o [% opt.multiname %]_raw/join.raw.fas

echo [% opt.data.0.name %] > [% opt.multiname %]_raw/names.list
[% FOREACH item IN opt.data -%]
[% IF not loop.first -%]
[% t = opt.data.0.name -%]
[% q = item.name -%]
echo [% q %] >> [% opt.multiname %]_raw/names.list
[% END -%]
[% END -%]

# Blocks not containing all queries, e.g. Mito, will be omitted
log_debug "    fasops subset"
fasops subset \
    [% opt.multiname %]_raw/join.raw.fas \
    [% opt.multiname %]_raw/names.list \
    --required \
    -o [% opt.multiname %]_raw/join.filter.fas

log_debug "    fasops refine"
fasops refine \
    --msa mafft --parallel [% opt.parallel %] \
    [% opt.multiname %]_raw/join.filter.fas \
    -o [% opt.multiname %]_raw/join.refine.fas

#----------------------------#
# RAxML
#----------------------------#
[% IF opt.data.size > 3 -%]
log_info RAxML

egaz raxml \
    --parallel [% IF opt.parallel > 3 %] [% opt.parallel - 1 %] [% ELSE %] 2 [% END %] \
[% IF opt.outgroup -%]
    --outgroup [% opt.outgroup %] \
[% END -%]
[% IF opt.verbose -%]
    -v \
[% END -%]
    [% opt.multiname %]_raw/join.refine.fas \
    -o Results/[% opt.multiname %].raw.nwk

egaz plottree Results/[% opt.multiname %].raw.nwk

[% ELSIF opt.data.size == 3 -%]
echo "(([% opt.data.0.name %],[% opt.data.1.name %]),[% opt.data.2.name %]);" > Results/[% opt.multiname %].raw.nwk

[% ELSE -%]
echo "([% opt.data.0.name %],[% opt.data.1.name %]);" > Results/[% opt.multiname %].raw.nwk

[% END -%]

exit;

EOF
    $tt->process(
        \$template,
        {   args => $args,
            opt  => $opt,
            sh   => $sh_name,
        },
        Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
    ) or Carp::confess Template->error;
}

sub gen_multi {
    my ( $self, $opt, $args ) = @_;

    return unless $opt->{mode} eq "multi";

    my $tt = Template->new( INCLUDE_PATH => [ File::ShareDir::dist_dir('App-Egaz') ], );
    my $template;
    my $sh_name;

    $sh_name = "3_multi.sh";
    print STDERR "Create $sh_name\n";
    $template = <<'EOF';
[% INCLUDE header.tt2 %]

#----------------------------#
# [% sh %]
#----------------------------#
log_warn [% sh %]

if [ -e Results/[% opt.multiname %].nwk ]; then
    log_info Results/[% opt.multiname %].nwk exists
    exit;
fi

if [ -d [% opt.multiname %]_mz ]; then
    rm -fr [% opt.multiname %]_mz;
fi;
mkdir -p [% opt.multiname %]_mz

if [ -d [% opt.multiname %]_fasta ]; then
    rm -fr [% opt.multiname %]_fasta;
fi;
mkdir -p [% opt.multiname %]_fasta

if [ -d [% opt.multiname %]_refined ]; then
    rm -fr [% opt.multiname %]_refined;
fi;
mkdir -p [% opt.multiname %]_refined

mkdir -p Results

#----------------------------#
# mz
#----------------------------#
log_info multiz

[% IF opt.tree -%]
egaz multiz \
[% FOREACH item IN opt.data -%]
[% IF not loop.first -%]
[% t = opt.data.0.name -%]
[% q = item.name -%]
    Pairwise/[% t %]vs[% q %] \
[% END -%]
[% END -%]
    --tree [% opt.tree %] \
    -o [% opt.multiname %]_mz \
    --parallel [% opt.parallel %]

[% ELSIF opt.order %]
egaz multiz \
[% FOREACH item IN opt.data -%]
[% IF not loop.first -%]
[% t = opt.data.0.name -%]
[% q = item.name -%]
    Pairwise/[% t %]vs[% q %] \
[% END -%]
[% END -%]
    --tree fake_tree.nwk \
    -o [% opt.multiname %]_mz \
    --parallel [% opt.parallel %]

[% ELSE %]
if [ -f Results/[% opt.multiname %].raw.nwk ]; then
    egaz multiz \
[% FOREACH item IN opt.data -%]
[% IF not loop.first -%]
[% t = opt.data.0.name -%]
[% q = item.name -%]
        Pairwise/[% t %]vs[% q %] \
[% END -%]
[% END -%]
        --tree Results/[% opt.multiname %].raw.nwk \
        -o [% opt.multiname %]_mz \
        --parallel [% opt.parallel %]

else
    egaz multiz \
[% FOREACH item IN opt.data -%]
[% IF not loop.first -%]
[% t = opt.data.0.name -%]
[% q = item.name -%]
        Pairwise/[% t %]vs[% q %] \
[% END -%]
[% END -%]
        --tree fake_tree.nwk \
        -o [% opt.multiname %]_mz \
        --parallel [% opt.parallel %]

fi
[% END -%]

find [% opt.multiname %]_mz -type f -name "*.maf" |
    parallel --no-run-if-empty -j 2 pigz -p [% opt.parallel2 %] {}

#----------------------------#
# maf2fas
#----------------------------#
log_info Convert maf to fas
find [% opt.multiname %]_mz -name "*.maf" -or -name "*.maf.gz" |
    parallel --no-run-if-empty -j [% opt.parallel %] \
        fasops maf2fas {} -o [% opt.multiname %]_fasta/{/}.fas

#----------------------------#
# refine fasta
#----------------------------#
log_info Refine fas
find [% opt.multiname %]_fasta -name "*.fas" -or -name "*.fas.gz" |
    parallel --no-run-if-empty -j 2 '
        fasops refine \
            --msa [% opt.msa %] --parallel [% opt.parallel2 %] \
            --quick --pad 100 --fill 100 \
[% IF opt.outgroup -%]
            --outgroup \
[% END -%]
            {} \
            -o [% opt.multiname %]_refined/{/}
    '

find [% opt.multiname %]_refined -type f -name "*.fas" |
    parallel --no-run-if-empty -j 2 pigz -p [% opt.parallel2 %] {}

#----------------------------#
# RAxML
#----------------------------#
[% IF opt.data.size > 3 -%]
log_info RAxML

egaz raxml \
    --parallel [% IF opt.parallel > 3 %] [% opt.parallel - 1 %] [% ELSE %] 2 [% END %] \
[% IF opt.outgroup -%]
    --outgroup [% opt.outgroup %] \
[% END -%]
[% IF opt.verbose -%]
    -v \
[% END -%]
    [% opt.multiname %]_refined/*.fas.gz \
    -o Results/[% opt.multiname %].nwk

egaz plottree Results/[% opt.multiname %].nwk

[% ELSIF opt.data.size == 3 -%]
echo "(([% opt.data.0.name %],[% opt.data.1.name %]),[% opt.data.2.name %]);" > Results/[% opt.multiname %].nwk

[% ELSE -%]
echo "([% opt.data.0.name %],[% opt.data.1.name %]);" > Results/[% opt.multiname %].nwk

[% END -%]

exit;

EOF
    $tt->process(
        \$template,
        {   args => $args,
            opt  => $opt,
            sh   => $sh_name,
        },
        Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
    ) or Carp::confess Template->error;
}

sub gen_vcf {
    my ( $self, $opt, $args ) = @_;

    return unless $opt->{mode} eq "multi" and $opt->{vcf};

    my $tt = Template->new( INCLUDE_PATH => [ File::ShareDir::dist_dir('App-Egaz') ], );
    my $template;
    my $sh_name;

    $sh_name = "4_vcf.sh";
    print STDERR "Create $sh_name\n";
    $template = <<'EOF';
[% INCLUDE header.tt2 %]

#----------------------------#
# [% sh %]
#----------------------------#
log_warn [% sh %]

if [ -e [% opt.multiname %]_vcf/[% opt.multiname %].vcf ]; then
    log_info [% opt.multiname %]_vcf/[% opt.multiname %].vcf exists
    exit;
fi

mkdir -p [% opt.multiname %]_vcf

log_info Write name.list

# Make sure all queries present
# Don't write outgroup
rm -f [% opt.multiname %]_vcf/name.list
[% FOREACH item IN opt.data -%]
[% IF not loop.last -%]
echo [% item.name %] >> [% opt.multiname %]_vcf/name.list
[% ELSE -%]
[% IF not opt.outgroup -%]
echo [% item.name %] >> [% opt.multiname %]_vcf/name.list
[% END -%]
[% END -%]
[% END -%]

log_info fas2vcf
find [% opt.multiname %]_refined -type f -name "*.fas" -or -type f -name "*.fas.gz" |
    sort |
    parallel --no-run-if-empty -j [% opt.parallel %] '
        egaz fas2vcf \
            {} \
            [% args.0 %]/chr.sizes \
            --verbose --list [% opt.multiname %]_vcf/name.list \
            -o [% opt.multiname %]_vcf/{/}.vcf
        '

log_info concat and sort vcf
bcftools concat [% opt.multiname %]_vcf/*.vcf |
    bcftools sort \
    > [% opt.multiname %]_vcf/[% opt.multiname %].vcf

find [% opt.multiname %]_vcf -type f -name "*.vcf" -not -name "multi4.vcf" |
    parallel --no-run-if-empty -j 1 rm

exit;

EOF
    $tt->process(
        \$template,
        {   args => $args,
            opt  => $opt,
            sh   => $sh_name,
        },
        Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
    ) or Carp::confess Template->error;

}

sub gen_self {
    my ( $self, $opt, $args ) = @_;

    return unless $opt->{mode} eq "self";

    my $tt = Template->new( INCLUDE_PATH => [ File::ShareDir::dist_dir('App-Egaz') ], );
    my $template;
    my $sh_name;

    $sh_name = "1_self.sh";
    print STDERR "Create $sh_name\n";
    $template = <<'EOF';
[% INCLUDE header.tt2 %]

#----------------------------#
# [% sh %]
#----------------------------#
log_warn [% sh %]

mkdir -p Pairwise

[% FOREACH item IN opt.data -%]
if [ -e Pairwise/[% item.name %]vsSelf ]; then
    log_info Skip Pairwise/[% item.name %]vsSelf
else
    log_info lastz Pairwise/[% item.name %]vsSelf
    egaz lastz \
        --isself --set set01 -C 0 --parallel [% opt.parallel %] --verbose \
        [% item.dir %] [% item.dir %] \
        -o Pairwise/[% item.name %]vsSelf

    log_info lpcnam Pairwise/[% item.name %]vsSelf
    egaz lpcnam \
        --parallel [% opt.parallel %] --verbose \
        [% item.dir %] [% item.dir %] Pairwise/[% item.name %]vsSelf
fi

[% END -%]

exit;

EOF
    $tt->process(
        \$template,
        {   args => $args,
            opt  => $opt,
            sh   => $sh_name,
        },
        Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
    ) or Carp::confess Template->error;
}

sub gen_proc {
    my ( $self, $opt, $args ) = @_;

    return unless $opt->{mode} eq "self";

    my $tt = Template->new( INCLUDE_PATH => [ File::ShareDir::dist_dir('App-Egaz') ], );
    my $template;
    my $sh_name;

    $sh_name = "3_proc.sh";
    print STDERR "Create $sh_name\n";
    $template = <<'EOF';
[% INCLUDE header.tt2 %]

#----------------------------#
# [% sh %]
#----------------------------#
log_warn [% sh %]

mkdir -p Processing
mkdir -p Results

#----------------------------#
# genome sequences
#----------------------------#
[% FOREACH item IN opt.data -%]
if [ -d Processing/[% item.name %] ]; then
    log_info Skip Processing/[% item.name %]
else
    log_info Symlink genome sequences for [% item.name %]
    mkdir -p Processing/[% item.name %]

    ln -s [% item.dir %]/chr.fasta Processing/[% item.name %]/genome.fa
    cp -f [% item.dir %]/chr.sizes Processing/[% item.name %]/chr.sizes
fi

[% END -%]

#----------------------------#
# parallel
#----------------------------#
log_info Blast paralogs against genomes and each other

parallel --no-run-if-empty --linebuffer -k -j 2 '

if [ -d Results/{} ]; then
    echo >&2 "==> Skip Results/{}";
    exit;
fi

cd Processing/{}

#----------------------------#
# Get exact copies in the genome
#----------------------------#
echo >&2 "==> Get exact copies in the genome"

echo >&2 "    * axt2fas"
fasops axt2fas \
    ../../Pairwise/{}vsSelf/axtNet/*.axt.gz \
    -l [% opt.length %] -s chr.sizes -o stdout > axt.fas
fasops separate axt.fas -o . --nodash -s .sep.fasta

echo >&2 "    * Target positions"
egaz exactmatch target.sep.fasta genome.fa \
    --length 500 --discard 50 -o replace.target.tsv
fasops replace axt.fas replace.target.tsv -o axt.target.fas

echo >&2 "    * Query positions"
egaz exactmatch query.sep.fasta genome.fa \
    --length 500 --discard 50 -o replace.query.tsv
fasops replace axt.target.fas replace.query.tsv -o axt.correct.fas

#----------------------------#
# Coverage stats
#----------------------------#
echo >&2 "==> Coverage stats"
fasops covers axt.correct.fas -o axt.correct.yml
runlist split axt.correct.yml -s .temp.yml
runlist compare --op union target.temp.yml query.temp.yml -o axt.union.yml
runlist stat --size chr.sizes axt.union.yml -o union.csv

# links by lastz-chain
fasops links axt.correct.fas -o stdout |
    perl -nl -e "s/(target|query)\.//g; print;" \
    > links.lastz.tsv

# remove species names
# remove duplicated sequences
# remove sequences with more than 250 Ns
fasops separate axt.correct.fas --nodash --rc -o stdout |
    perl -nl -e "/^>/ and s/^>(target|query)\./\>/; print;" |
    faops filter -u stdin stdout |
    faops filter -n 250 stdin stdout \
    > axt.gl.fasta

[% IF opt.noblast -%]
#----------------------------#
# Lastz paralogs
#----------------------------#
cat axt.gl.fasta > axt.all.fasta
[% ELSE -%]
#----------------------------#
# Get more paralogs
#----------------------------#
echo >&2 "==> Get more paralogs"
egaz blastn axt.gl.fasta genome.fa -o axt.bg.blast --parallel [% opt.parallel2 %]
egaz blastmatch axt.bg.blast -c 0.95 --perchr -o axt.bg.region --parallel [% opt.parallel2 %]
faops region -s genome.fa axt.bg.region axt.bg.fasta

cat axt.gl.fasta axt.bg.fasta |
    faops filter -u stdin stdout |
    faops filter -n 250 stdin stdout \
    > axt.all.fasta
[% END -%]

#----------------------------#
# Link paralogs
#----------------------------#
echo >&2 "==> Link paralogs"
egaz blastn axt.all.fasta axt.all.fasta -o axt.all.blast --parallel [% opt.parallel2 %]
egaz blastlink axt.all.blast -c 0.95 -o links.blast.tsv --parallel [% opt.parallel2 %]

#----------------------------#
# Merge paralogs
#----------------------------#
echo >&2 "==> Merge paralogs"

echo >&2 "    * Sort links"
rangeops sort -o links.sort.tsv \
[% IF opt.noblast -%]
   links.lastz.tsv
[% ELSE -%]
    links.lastz.tsv links.blast.tsv
[% END -%]

echo >&2 "    * Clean links"
[% IF jrange -%]
jrange clean   links.sort.tsv       -o links.sort.clean.tsv
jrange merge   links.sort.clean.tsv -o links.merge.tsv       -c 0.95
jrange clean   links.sort.clean.tsv -o links.clean.tsv       -r links.merge.tsv --bundle 500
[% ELSE -%]
rangeops clean links.sort.tsv       -o links.sort.clean.tsv
rangeops merge links.sort.clean.tsv -o links.merge.tsv       -c 0.95 --parallel [% opt.parallel2 %]
rangeops clean links.sort.clean.tsv -o links.clean.tsv       -r links.merge.tsv --bundle 500
[% END -%]

echo >&2 "    * Connect links"
rangeops connect links.clean.tsv    -o links.connect.tsv     -r 0.9
rangeops filter  links.connect.tsv  -o links.filter.tsv      -r 0.8

    ' ::: [% FOREACH item IN opt.data %][% item.name %] [% END %]

[% FOREACH item IN opt.data -%]
[% id = item.name -%]
#----------------------------#
# [% id %]
#----------------------------#
if [ -d Results/[% id %] ]; then
    log_info Skip Results/[% id %]
else

mkdir -p Results/[% id %]
pushd Processing/[% id %] > /dev/null

log_info Create multiple/pairwise alignments for [% id %]

log_debug multiple links
rangeops create links.filter.tsv -o multi.temp.fas    -g genome.fa
fasops   refine multi.temp.fas   -o multi.refine.fas  --msa mafft -p [% opt.parallel %] --chop 10
fasops   links  multi.refine.fas -o stdout |
    rangeops sort stdin -o stdout |
    rangeops filter stdin -n 2-50 -o links.refine.tsv

log_debug pairwise links
fasops   links  multi.refine.fas    -o stdout     --best |
    rangeops sort stdin -o links.best.tsv
rangeops create links.best.tsv   -o pair.temp.fas    -g genome.fa --name [% id %]
fasops   refine pair.temp.fas    -o pair.refine.fas  --msa mafft -p [% opt.parallel %]

cat links.refine.tsv |
    perl -nla -F"\t" -e "print for @F" |
    runlist cover stdin -o cover.yml

log_debug Stats of links
echo "key,count" > links.count.csv
for n in 2 3 4 5-50; do
    rangeops filter links.refine.tsv -n ${n} -o stdout \
        > links.copy${n}.tsv

    cat links.copy${n}.tsv |
        perl -nla -F"\t" -e "print for @F" |
        runlist cover stdin -o copy${n}.temp.yml

    wc -l links.copy${n}.tsv |
        perl -nl -e "
            @fields = grep {/\S+/} split /\s+/;
            next unless @fields == 2;
            next unless \$fields[1] =~ /links\.([\w-]+)\.tsv/;
            printf qq{%s,%s\n}, \$1, \$fields[0];
        " \
        >> links.count.csv

    rm links.copy${n}.tsv
done

runlist merge copy2.temp.yml copy3.temp.yml copy4.temp.yml copy5-50.temp.yml -o copy.yml
runlist stat --size chr.sizes copy.yml --mk --all -o links.copy.csv

fasops mergecsv links.copy.csv links.count.csv --concat -o copy.csv

log_debug Coverage figure
runlist stat --size chr.sizes cover.yml
#perl cover_figure.pl --size chr.sizes -f cover.yml

log_info Results for [% id %]

cp cover.yml        ../../Results/[% id %]/[% id %].cover.yml
cp copy.yml         ../../Results/[% id %]/[% id %].copy.yml
mv cover.yml.csv    ../../Results/[% id %]/[% id %].cover.csv
mv copy.csv         ../../Results/[% id %]/[% id %].copy.csv
cp links.refine.tsv ../../Results/[% id %]/[% id %].links.tsv
#mv cover.png        ../../Results/[% id %]/[% id %].cover.png
mv multi.refine.fas ../../Results/[% id %]/[% id %].multi.fas
mv pair.refine.fas  ../../Results/[% id %]/[% id %].pair.fas

log_info Clean up

find . -type f -name "*genome.fa*"   | parallel --no-run-if-empty rm
find . -type f -name "*all.fasta*"   | parallel --no-run-if-empty rm
find . -type f -name "*.sep.fasta"   | parallel --no-run-if-empty rm
find . -type f -name "axt.*"         | parallel --no-run-if-empty rm
find . -type f -name "replace.*.tsv" | parallel --no-run-if-empty rm
find . -type f -name "*.temp.yml"    | parallel --no-run-if-empty rm
find . -type f -name "*.temp.fas"    | parallel --no-run-if-empty rm

popd > /dev/null

fi

[% END -%]

exit;

EOF
    $tt->process(
        \$template,
        {   args   => $args,
            opt    => $opt,
            sh     => $sh_name,
            jrange => IPC::Cmd::can_run('jrange'),
        },
        Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
    ) or Carp::confess Template->error;
}

sub gen_circos {
    my ( $self, $opt, $args ) = @_;

    return unless $opt->{mode} eq "self" and $opt->{circos};

    my $tt = Template->new( INCLUDE_PATH => [ File::ShareDir::dist_dir('App-Egaz') ], );

    # circos.conf and karyotype.id.txt
    for my $item ( @{ $opt->{data} } ) {
        print STDERR "Create circos.conf for $item->{name}\n" if $opt->{verbose};
        $tt->process(
            "circos.conf.tt2",
            {   dir => $opt->{outdir},
                id  => $item->{name},
            },
            Path::Tiny::path( $opt->{outdir}, 'Circos', $item->{name}, "circos.conf" )->stringify
        ) or Carp::confess Template->error;

        # copy prebuilt karyotype file
        if ( $item->{taxon} != 0 ) {
            my $karyo = Path::Tiny::path( File::ShareDir::dist_dir('App-Egaz'),
                "share", "karyotype", "karyotype.$item->{taxon}.txt" );

            if ( $karyo->is_file ) {
                print STDERR "    Copy prebuilt karyotype.$item->{name}.txt\n" if $opt->{verbose};
                $karyo->copy( $opt->{outdir}, 'Circos', $item->{name},
                    "karyotype.$item->{name}.txt" );
            }
        }
    }

    # 4_circos.sh
    my $template;
    my $sh_name;

    $sh_name = "4_circos.sh";
    print STDERR "Create $sh_name\n";
    $template = <<'EOF';
[% INCLUDE header.tt2 %]

#----------------------------#
# [% sh %]
#----------------------------#
log_warn [% sh %]

mkdir -p Pairwise

[% FOREACH item IN opt.data -%]
[% id = item.name -%]
#----------------------------#
# [% id %]
#----------------------------#
log_info [% id %]
cd [% opt.outdir %]/Circos/[% id %]

#----------------------------#
# karyotype
#----------------------------#
log_debug Adjust karyotype

# generate karyotype files
if [ ! -e karyotype.[% id %].txt ]; then
    log_debug Create default karyotype
    perl -anl -e '$i++; print qq{chr - $F[0] $F[0] 0 $F[1] chr$i}' \
        [% item.dir %]/chr.sizes \
        > karyotype.[% id %].txt
fi

# spaces among chromosomes
if [[ $(perl -n -e '$l++; END{print qq{$l\n}}' [% item.dir %]/chr.sizes ) > 1 ]]; then
    log_debug Multiple chromosomes
    perl -nlpi -e 's/    default = 0r/    default = 0.005r/;' circos.conf
    perl -nlpi -e 's/show_label     = no/show_label     = yes/;' circos.conf
fi

# chromosome units
SIZE=$(perl -an -F'\t' -e '$s += $F[1]; END{print qq{$s\n}}' [% item.dir %]/chr.sizes )
log_debug "Genome size ${SIZE}"
if [ ${SIZE} -ge 1000000000 ]; then
    echo "    * Set chromosome unit to 1 Mbp"
    perl -nlpi -e 's/chromosomes_units = 1000/chromosomes_units = 100000/;' circos.conf
elif [ ${SIZE} -ge 100000000 ]; then
    echo "    * Set chromosome unit to 100 kbp"
    perl -nlpi -e 's/chromosomes_units = 1000/chromosomes_units = 100000/;' circos.conf
elif [ ${SIZE} -ge 10000000 ]; then
    echo "    * Set chromosome unit to 10 kbp"
    perl -nlpi -e 's/chromosomes_units = 1000/chromosomes_units = 10000/;' circos.conf
else
    echo "    * Keep chromosome unit as 1 kbp"
fi

#----------------------------#
# gff to highlight
#----------------------------#
log_debug Create highlight files

# coding and other features
perl -anl -e '
    /^#/ and next;
    $F[0] =~ s/\.\d+//;
    $color = q{};
    $F[2] eq q{CDS} and $color = q{chr9};
    $F[2] eq q{ncRNA} and $color = q{dark2-8-qual-1};
    $F[2] eq q{rRNA} and $color = q{dark2-8-qual-2};
    $F[2] eq q{tRNA} and $color = q{dark2-8-qual-3};
    $F[2] eq q{tmRNA} and $color = q{dark2-8-qual-4};
    $color and ($F[4] - $F[3] > 49) and print qq{$F[0] $F[3] $F[4] fill_color=$color};
    ' \
    [% item.dir %]/*.gff \
    > highlight.features.[% id %].txt

# repeats
perl -anl -e '
    /^#/ and next;
    $F[0] =~ s/\.\d+//;
    $color = q{};
    $F[2] eq q{region} and $F[8] =~ /mobile_element|Transposon/i and $color = q{chr15};
    $F[2] =~ /repeat/ and $F[8] !~ /RNA/ and $color = q{chr15};
    $color and ($F[4] - $F[3] > 49) and print qq{$F[0] $F[3] $F[4] fill_color=$color};
    ' \
    [% item.dir %]/*.gff \
    > highlight.repeats.[% id %].txt

#----------------------------#
# links of paralog ranges
#----------------------------#
log_debug Create link files

for n in 2 3 4 5-50; do
    rangeops filter [% opt.outdir %]/Results/[% id %]/[% id %].links.tsv -n ${n} -o stdout \
        > links.copy${n}.tsv

    if [ "${n}" == "5-50" ]; then
        rangeops circos links.copy${n}.tsv -o [% id %].linkN.txt --highlight
    else
        rangeops circos links.copy${n}.tsv -o [% id %].link${n}.txt
    fi

    rm links.copy${n}.tsv
done

#----------------------------#
# run circos
#----------------------------#
log_info Run circos
circos -noparanoid -conf circos.conf

[% END -%]

exit;

EOF
    $tt->process(
        \$template,
        {   args => $args,
            opt  => $opt,
            sh   => $sh_name,
        },
        Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
    ) or Carp::confess Template->error;

}

1;
