package App::Anchr::Command::kunitigs;
use strict;
use warnings;
use autodie;

use App::Anchr -command;
use App::Anchr::Common;

use constant abstract => "create k-unitigs from corrected reads";

sub opt_spec {
    return (
        [ "outfile|o=s",  "output filename, [stdout] for screen", { default => "kunitigs.sh" }, ],
        [ 'jf=s',         'jellyfish hash size',                  { default => "auto", }, ],
        [ 'estsize=s',    'estimated genome size',                { default => "auto", }, ],
        [ 'kmer=s',       'kmer size to be used for super reads', { default => "auto", }, ],
        [ 'min=i',        'minimal length of k-unitigs',          { default => 500, }, ],
        [ 'parallel|p=i', 'number of threads',                    { default => 8, }, ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "anchr kunitigs [options] <pe.cor.fa> <environment.json>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= "\tFasta files can be gzipped\n";
    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( !( @{$args} == 2 ) ) {
        my $message = "This command need two input files.\n\tIt found";
        $message .= sprintf " [%s]", $_ for @{$args};
        $message .= ".\n";
        $self->usage_error($message);
    }
    for ( @{$args} ) {
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

    if ( $opt->{kmer} ne 'auto' ) {
        unless ( $opt->{kmer} =~ /^[\d,]+$/ ) {
            $self->usage_error("Invalid k-mer [$opt->{kmer}].");
        }
        $opt->{kmer} = [ sort { $a <=> $b } grep {defined} split ",", $opt->{kmer} ];
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
# Read stats of PE reads
#----------------------------#
log_info Symlink/copy input files
if [ ! -e pe.cor.fa ]; then
    ln -s [% args.0 %] pe.cor.fa
fi
cp [% args.1 %] environment.json

log_info Read stats of PE reads

SUM_COR=$( faops n50 -H -N 0 -S pe.cor.fa )
save SUM_COR

[% IF opt.kmer == 'auto' -%]
KMER=$( cat environment.json | jq '.KMER' )
log_debug "Choosing kmer size of $KMER for the graph"
[% ELSE -%]
KMER=[% opt.kmer.join(',') %]
save KMER
log_debug "You set kmer size of $KMER for the graph"
[% END -%]

[% IF opt.jf == 'auto' -%]
JF_SIZE=$( cat environment.json | jq '.JF_SIZE | tonumber' )
[% ELSE -%]
JF_SIZE=[% opt.jf %]
save JF_SIZE
[% END -%]
log_debug "JF_SIZE: $JF_SIZE"

[% IF opt.estsize == 'auto' -%]
ESTIMATED_GENOME_SIZE=$( cat environment.json | jq '.ESTIMATED_GENOME_SIZE | tonumber' )
[% ELSE -%]
ESTIMATED_GENOME_SIZE=[% opt.estsize %]
save ESTIMATED_GENOME_SIZE
[% END -%]
log_debug "ESTIMATED_GENOME_SIZE: $ESTIMATED_GENOME_SIZE"

#----------------------------#
# Build k-unitigs
#----------------------------#
if [ ! -e k_unitigs.fasta ]; then
log_info Creating k-unitigs
[% IF opt.kmer == 'auto' -%]
    log_debug with k=$KMER
    create_k_unitigs_large_k -c $(($KMER-1)) -t [% opt.parallel %] \
        -m $KMER -n $ESTIMATED_GENOME_SIZE -l $KMER -f 0.000001 pe.cor.fa \
        > k_unitigs_K$KMER.fasta

    anchr contained \
        k_unitigs_K$KMER.fasta \
        --len [% opt.min %] --idt 0.99 --proportion 0.99999 --parallel [% opt.parallel %] \
        -o stdout \
        | faops filter -a [% opt.min %] -l 0 stdin k_unitigs.contained.fasta
[% ELSE -%]
[% FOREACH kmer IN opt.kmer -%]
    log_debug with k=[% kmer %]
    create_k_unitigs_large_k -c $(([% kmer %]-1)) -t [% opt.parallel %] \
        -m [% kmer %] -n $ESTIMATED_GENOME_SIZE -l [% kmer %] -f 0.000001 pe.cor.fa \
        > k_unitigs_K[% kmer %].fasta

[% END -%]
    log_info Merging k-unitigs
    anchr contained \
[% FOREACH kmer IN opt.kmer -%]
        k_unitigs_K[% kmer %].fasta \
[% END -%]
        --len 500 --idt 0.98 --proportion 0.99999 --parallel [% opt.parallel %] \
        -o stdout \
        | faops filter -a [% opt.min %] -l 0 stdin k_unitigs.contained.fasta
[% END -%]
    anchr orient k_unitigs.contained.fasta \
        --len [% opt.min %] --idt 0.99 --parallel [% opt.parallel %] \
        -o k_unitigs.orient.fasta
    anchr merge k_unitigs.orient.fasta \
        --len [% opt.min %] --idt 0.999 --parallel [% opt.parallel %] \
        -o k_unitigs.fasta
fi

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
