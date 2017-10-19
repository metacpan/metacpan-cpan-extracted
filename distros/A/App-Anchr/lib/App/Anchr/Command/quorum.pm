package App::Anchr::Command::quorum;
use strict;
use warnings;
use autodie;

use App::Anchr -command;
use App::Anchr::Common;

use constant abstract => "Run quorum to discard bad reads";

sub opt_spec {
    return (
        [ "outfile|o=s", "output filename, [stdout] for screen", { default => "quorum.sh" }, ],
        [ 'size|s=i',    'fragment size',                        { default => 300, }, ],
        [ 'std|d=i',     'fragment size standard deviation',     { default => 30, }, ],
        [ 'jf=i',        'jellyfish hash size',                  { default => 500_000_000, }, ],
        [ 'estsize=s',   'estimated genome size',                { default => "auto", }, ],
        [   "adapter|a=s", "adapter file",
            { default => File::ShareDir::dist_file( 'App-Anchr', 'adapter.jf' ) },
        ],
        [ 'parallel|p=i', 'number of threads', { default => 8, }, ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "anchr quorum [options] <PE file1> <PE file2> [SE file]";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= "\tFastq files can be gzipped\n";
    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( !( @{$args} == 2 or @{$args} == 3 ) ) {
        my $message = "This command need two or three input files.\n\tIt found";
        $message .= sprintf " [%s]", $_ for @{$args};
        $message .= ".\n";
        $self->usage_error($message);
    }
    for ( @{$args} ) {
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

    if ( $opt->{adapter} ) {
        if ( !Path::Tiny::path( $opt->{adapter} )->is_file ) {
            $self->usage_error("The adapter file [$opt->{adapter}] doesn't exist.");
        }
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    # A stream to 'stdout' or a standard file.
    my $out_fh;
    if ( lc $opt->{outfile} eq "stdout" ) {
        $out_fh = *STDOUT{IO};
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    my $tt   = Template->new;
    my $text = <<'EOF';
#!/usr/bin/env bash

#----------------------------#
# Colors in term
#----------------------------#
# http://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
GREEN=
RED=
NC=
if tty -s < /dev/fd/1 2> /dev/null; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    NC='\033[0m' # No Color
fi

log_warn () {
    echo >&2 -e "${RED}==> $@ <==${NC}"
}

log_info () {
    echo >&2 -e "${GREEN}==> $@${NC}"
}

log_debug () {
    echo >&2 -e "  * $@"
}

#----------------------------#
# masurca
#----------------------------#
set +e
# Set some paths and prime system to save environment variables
save () {
    printf ". + {%s: \"%s\"}" $1 $(eval "echo -n \"\$$1\"") > jq.filter.txt

    if [ -e environment.json ]; then
        cat environment.json \
            | jq -f jq.filter.txt \
            > environment.json.new
        rm environment.json
    else
        jq -f jq.filter.txt -n \
            > environment.json.new
    fi

    mv environment.json.new environment.json
    rm jq.filter.txt
}

signaled () {
    log_warn Interrupted
    exit 1
}
trap signaled TERM QUIT INT

START_TIME=$(date +%s)
save START_TIME

NUM_THREADS=[% opt.parallel %]
save NUM_THREADS

#----------------------------#
# Renaming reads
#----------------------------#
log_info 'Processing pe and/or se library reads'
rm -rf meanAndStdevByPrefix.pe.txt
echo 'pe [% opt.size %] [% opt.std %]' >> meanAndStdevByPrefix.pe.txt

if [ ! -e pe.renamed.fastq ]; then
    rename_filter_fastq \
        'pe' \
        <(exec expand_fastq '[% args.0 %]' ) \
        <(exec expand_fastq '[% args.1 %]' ) \
        > 'pe.renamed.fastq'
fi

[% IF args.2 -%]
echo 'se [% opt.size %] [% opt.std %]' >> meanAndStdevByPrefix.pe.txt

if [ ! -e se.renamed.fastq ]; then
    rename_filter_fastq \
        'se' \
        <(exec expand_fastq '[% args.2 %]' ) \
        '' \
        > 'se.renamed.fastq'
fi
[% END -%]

#----------------------------#
# Stats of PE reads
#----------------------------#
head -n 80000 pe.renamed.fastq > pe_data.tmp
export PE_AVG_READ_LENGTH=$(
    head -n 40000 pe_data.tmp \
    | grep --text -v '^+' \
    | grep --text -v '^@' \
    | awk '{if(length($1)>31){n+=length($1);m++;}}END{print int(n/m)}'
)
save PE_AVG_READ_LENGTH
log_debug "Average PE read length $PE_AVG_READ_LENGTH"

KMER=$(
    tail -n 40000 pe_data.tmp \
    | perl -e '
        my @lines;
        while ( my $line = <STDIN> ) {
            $line = <STDIN>;
            chomp($line);
            push( @lines, $line );
            $line = <STDIN>;
            $line = <STDIN>;
        }
        my @legnths;
        my $min_len    = 100000;
        my $base_count = 0;
        for my $l (@lines) {
            $base_count += length($l);
            push( @lengths, length($l) );
            for $base ( split( "", $l ) ) {
                if ( uc($base) eq "G" or uc($base) eq "C" ) { $gc_count++; }
            }
        }
        @lengths  = sort { $b <=> $a } @lengths;
        $min_len  = $lengths[ int( $#lengths * .75 ) ];
        $gc_ratio = $gc_count / $base_count;
        $kmer     = 0;
        if ( $gc_ratio < 0.5 ) {
            $kmer = int( $min_len * .7 );
        }
        elsif ( $gc_ratio >= 0.5 && $gc_ratio < 0.6 ) {
            $kmer = int( $min_len * .5 );
        }
        else {
            $kmer = int( $min_len * .33 );
        }
        $kmer++ if ( $kmer % 2 == 0 );
        $kmer = 31  if ( $kmer < 31 );
        $kmer = 127 if ( $kmer > 127 );
        print $kmer;
    ' )
save KMER
log_debug "Choosing kmer size of $KMER"

MIN_Q_CHAR=$(
    head -n 40000 pe_data.tmp \
    | awk 'BEGIN{flag=0}{if($0 ~ /^\+/){flag=1}else if(flag==1){print $0;flag=0}}' \
    | perl -ne '
        BEGIN { $q0_char = "@"; }

        chomp;
        for $v ( split "" ) {
            if ( ord($v) < ord($q0_char) ) { $q0_char = $v; }
        }

        END {
            $ans = ord($q0_char);
            if   ( $ans < 64 ) { print "33\n" }
            else               { print "64\n" }
        }
    ')
save MIN_Q_CHAR
log_debug "MIN_Q_CHAR: $MIN_Q_CHAR"

#----------------------------#
# Error correct PE
#----------------------------#
JF_SIZE=$( ls -l *.fastq \
    | awk '{n+=$5} END{s=int(n / 50 * 1.1); if(s>[% opt.jf %])print s;else print "[% opt.jf %]";}' )
save JF_SIZE
perl -e '
    if(int('$JF_SIZE') > [% opt.jf %]) {
        print "WARNING: JF_SIZE set too low, increasing JF_SIZE to at least '$JF_SIZE'.\n";
    }
    '

if [ ! -e quorum_mer_db.jf ]; then
    log_info Creating mer database for Quorum.

    quorum_create_database \
        -t [% opt.parallel %] \
        -s $JF_SIZE -b 7 -m 24 -q $((MIN_Q_CHAR + 5)) \
        -o quorum_mer_db.jf.tmp \
        pe.renamed.fastq [% IF args.2 %]se.renamed.fastq [% END %]\
        && mv quorum_mer_db.jf.tmp quorum_mer_db.jf
    if [ $? -ne 0 ]; then
        log_warn Increase JF_SIZE by --jf, the recommendation value is genome_size*coverage/2
        exit 1
    fi
fi

# -m Minimum count for a k-mer to be considered "good" (1)
# -g Number of good k-mer in a row for anchor (2)
# -a Minimum count for an anchor k-mer (3)
# -w Size of window (10)
# -e Maximum number of error in a window (3)
# As we have trimmed reads with sickle, we lower `-e` to 1 from original value of 3,
# remove `--no-discard`.
# And we only want most reliable parts of the genome other than the whole genome, so dropping rare
# k-mers is totally OK for us. Raise `-m` from 1 to 3, `-g` from 1 to 3, and `-a` from 1 to 4.
if [ ! -e pe.cor.fa ]; then
    log_info Error correct PE.
    quorum_error_correct_reads \
        -q $((MIN_Q_CHAR + 40)) \
        --contaminant=[% opt.adapter %] \
        -m 3 -s 1 -g 3 -a 4 -t [% opt.parallel %] -w 10 -e 1 \
        quorum_mer_db.jf \
        pe.renamed.fastq [% IF args.2 %]se.renamed.fastq [% END %]\
        -o pe.cor --verbose 1>quorum.err 2>&1 \
    || {
        mv pe.cor.fa pe.cor.fa.failed;
        log_warn Error correction of PE reads failed. Check pe.cor.log.;
        exit 1;
    }
    log_debug "Discard any reads with subs"
    mv pe.cor.fa pe.cor.sub.fa
    cat pe.cor.sub.fa | grep -E '^>\w+\s*$' -A 1 | sed '/^--$/d' > pe.cor.fa
fi

SUM_IN=$( faops n50 -H -N 0 -S pe.renamed.fastq [% IF args.2 %]se.renamed.fastq [% END %])
save SUM_IN
SUM_OUT=$( faops n50 -H -N 0 -S pe.cor.fa )
save SUM_OUT

#----------------------------#
# Estimating genome size.
#----------------------------#
log_info Estimating genome size.

[% IF opt.estsize == 'auto' -%]
if [ ! -e k_u_hash_0 ]; then
    jellyfish count -m 31 -t [% opt.parallel %] -C -s $JF_SIZE -o k_u_hash_0 pe.cor.fa
fi
ESTIMATED_GENOME_SIZE=$(jellyfish histo -t [% opt.parallel %] -h 1 k_u_hash_0 | tail -n 1 |awk '{print $2}')
save ESTIMATED_GENOME_SIZE
log_debug "Estimated genome size: $ESTIMATED_GENOME_SIZE"
[% ELSE -%]
ESTIMATED_GENOME_SIZE=[% opt.estsize %]
save ESTIMATED_GENOME_SIZE
log_debug "You set ESTIMATED_GENOME_SIZE of $ESTIMATED_GENOME_SIZE"
[% END -%]

#----------------------------#
# Done.
#----------------------------#
END_TIME=$(date +%s)
save END_TIME

RUNTIME=$((END_TIME-START_TIME))
save RUNTIME

log_info Done.

exit 0

EOF
    my $output;
    $tt->process(
        \$text,
        {   args => $args,
            opt  => $opt,
        },
        \$output
    );

    print {$out_fh} $output;
    close $out_fh;
}

1;
