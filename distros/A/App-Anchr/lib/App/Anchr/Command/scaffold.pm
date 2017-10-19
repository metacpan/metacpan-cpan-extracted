package App::Anchr::Command::scaffold;
use strict;
use warnings;
use autodie;

use App::Anchr -command;
use App::Anchr::Common;

use constant abstract => "scaffold anchors (k-unitigs/contigs) using paired-end reads";

sub opt_spec {
    return (
        [ "outfile|o=s",  "output filename, [stdout] for screen",  { default => "scaffold.sh" }, ],
        [ 'parallel|p=i', 'number of threads',                     { default => 8, }, ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "anchr scaffold [options] <anchor.fasta> <pe.fa>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
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
# helper functions
#----------------------------#
set +e

signaled () {
    log_warn Interrupted
    exit 1
}
trap signaled TERM QUIT INT

#----------------------------#
# Prepare SR
#----------------------------#
log_info Symlink/copy input files

if [ ! -e SR.fasta ]; then
    ln -s [% args.0 %] SR.fasta
fi

if [ ! -e pe.fa ]; then
    ln -s [% args.1 %] pe.fa
fi

#----------------------------#
# basecov
#----------------------------#
log_info "basecov"

log_debug "bbmap"
bbmap.sh \
    maxindel=0 strictmaxindel perfectmode \
    threads=[% opt.parallel %] \
    ambiguous=toss \
    nodisk \
    ref=SR.fasta in=pe.fa \
    outm=unambiguous.sam outu=unmapped.sam \
    basecov=basecov.txt \
    1>bbmap.err 2>&1

# Pos is 0-based
#RefName	Pos	Coverage
log_debug "coverage"
cat basecov.txt \
    | grep -v '^#' \
    | perl -nla -MApp::Fasops::Common -e '
        BEGIN { our $name; our @list; }

        if ( !defined $name ) {
            $name = $F[0];
            @list = ( $F[2] );
        }
        elsif ( $name eq $F[0] ) {
            push @list, $F[2];
        }
        else {
            my $mean_cov = App::Fasops::Common::mean(@list);
            printf qq{%s\t%s_cov%d\n}, $name, $name, int $mean_cov;

            $name = $F[0];
            @list = ( $F[2] );
        }

        END {
            my $mean_cov = App::Fasops::Common::mean(@list);
            printf qq{%s\t%s_cov%d\n}, $name, $name, int $mean_cov;
        }
    ' \
    > replace.tsv

log_debug "replace headers"
faops replace -l 0 SR.fasta replace.tsv SR.cov.fasta

#find . -type f -name "*.sam"   | parallel --no-run-if-empty -j 1 rm

#----------------------------#
# scaffold
#----------------------------#
log_info "scaffold"

log_debug "scaffold"
platanus scaffold -t [% opt.parallel %] \
    -c SR.cov.fasta \
    -ip1 pe.fa \
    2>&1 1> sca_log.txt

log_debug "gap_close"
platanus gap_close -t [% opt.parallel %]\
    -c out_scaffold.fa \
    -ip1 pe.fa \
    2>&1 1> gap_log.txt

#----------------------------#
# Done.
#----------------------------#
touch scaffold.success
log_info "Done."

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
