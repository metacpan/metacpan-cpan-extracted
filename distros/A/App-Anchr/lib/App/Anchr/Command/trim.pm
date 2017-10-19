package App::Anchr::Command::trim;
use strict;
use warnings;
use autodie;

use App::Anchr -command;
use App::Anchr::Common;

use constant abstract => "trim PE Illumina fastq files";

sub opt_spec {
    return (
        [ "outfile|o=s",  "output filename, [stdout] for screen",      { default => "trim.sh" }, ],
        [ "basename|b=s", "prefix of fastq filenames",                 { default => "R" }, ],
        [ "len|l=i",      "filter reads less or equal to this length", { default => 80 }, ],
        [ "qual|q=i",     "quality threshold",                         { default => 20 }, ],
        [   "adapter|a=s", "adapter file",
            { default => File::ShareDir::dist_file( 'App-Anchr', 'illumina_adapters.fa' ) },
        ],
        [ "noscythe", "skip the scythe step", ],
        [ "parallel|p=i", "number of threads", { default => 8 }, ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "anchr trim [options] <PE file1> <PE file2>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= "\tFastq files can be gzipped\n";
    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} != 2 ) {
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
    echo >&2 -e "==> $@"
}

#----------------------------#
# Run
#----------------------------#

[% IF opt.noscythe -%]
log_info "Skip the scythe step"
[% ELSE -%]
#----------------------------#
# scythe
#----------------------------#
log_info "scythe [% args.0 %]"
scythe \
    [% args.0 %] \
    -q sanger \
    -M [% opt.len %] \
    -a [% opt.adapter %] \
    --quiet \
    | pigz -p [% opt.parallel %] -c \
    > R1.scythe.fq.gz

log_info "scythe [% args.1 %]"
scythe \
    [% args.1 %] \
    -q sanger \
    -M [% opt.len %] \
    -a [% opt.adapter %] \
    --quiet \
    | pigz -p [% opt.parallel %] -c \
    > R2.scythe.fq.gz
[% END -%]

#----------------------------#
# sickle
#----------------------------#
log_info "sickle [% args.0 %] [% args.1 %]"
[% IF opt.noscythe -%]
sickle pe \
    -t sanger \
    -l [% opt.len %] \
    -q [% opt.qual %] \
    -f [% args.0 %] \
    -r [% args.1 %] \
    -o R1.sickle.fq \
    -p R2.sickle.fq \
    -s single.sickle.fq
[% ELSE -%]
sickle pe \
    -t sanger \
    -l [% opt.len %] \
    -q [% opt.qual %] \
    -f R1.scythe.fq.gz \
    -r R2.scythe.fq.gz \
    -o R1.sickle.fq \
    -p R2.sickle.fq \
    -s single.sickle.fq
[% END -%]

find . -type f -name "*.sickle.fq" | xargs pigz -p [% opt.parallel %]

#----------------------------#
# outputs
#----------------------------#
mv R1.sickle.fq.gz [% opt.basename %]1.fq.gz
mv R2.sickle.fq.gz [% opt.basename %]2.fq.gz
mv single.sickle.fq.gz [% opt.basename %]s.fq.gz

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
