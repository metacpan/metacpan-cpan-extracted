package App::Anchr::Command::anchors;
use strict;
use warnings;
use autodie;

use App::Anchr -command;
use App::Anchr::Common;

use constant abstract => "selete anchors from k-unitigs or superreads";

sub opt_spec {
    return (
        [ "outfile|o=s",  "output filename, [stdout] for screen",  { default => "anchors.sh" }, ],
        [ 'min=i',        'minimal length of anchors',             { default => 1000, }, ],
        [ 'unambi=i',     'minimal coverage of unambiguous reads', { default => 2, }, ],
        [ 'parallel|p=i', 'number of threads',                     { default => 8, }, ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "anchr anchors [options] <k_unitigs.fasta> <pe.cor.fa>";
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

if [ ! -e pe.cor.fa ]; then
    ln -s [% args.1 %] pe.cor.fa
fi

log_debug "SR sizes"
faops size SR.fasta > sr.chr.sizes

#----------------------------#
# unambiguous
#----------------------------#
log_info "Unambiguous regions"

log_debug "bbmap"
bbmap.sh \
    maxindel=0 strictmaxindel perfectmode \
    threads=[% opt.parallel %] \
    ambiguous=toss \
    nodisk \
    ref=SR.fasta in=pe.cor.fa \
    outm=unambiguous.sam outu=unmapped.sam \
    basecov=basecov.txt \
    1>bbmap.err 2>&1

# at least [% opt.unambi %] unambiguous reads covered
# Pos is 0-based
#RefName	Pos	Coverage
log_debug "covered"
cat basecov.txt \
    | grep -v '^#' \
    | perl -nla -e '
        BEGIN { our $name; our @list; }

        sub list_to_ranges {
            my @ranges;
            my $count = scalar @list;
            my $pos   = 0;
            while ( $pos < $count ) {
                my $end = $pos + 1;
                $end++ while $end < $count && $list[$end] <= $list[ $end - 1 ] + 1;
                push @ranges, ( $list[$pos], $list[ $end - 1 ] );
                $pos = $end;
            }

            return @ranges;
        }

        $F[2] < 2 and next;

        if ( !defined $name ) {
            $name = $F[0];
            @list = ( $F[1] );
        }
        elsif ( $name eq $F[0] ) {
            push @list, $F[1];
        }
        else {
            my @ranges = list_to_ranges();
            for ( my $i = 0; $i < $#ranges; $i += 2 ) {
                if ( $ranges[$i] == $ranges[ $i + 1 ] ) {
                    printf qq{%s:%s\n}, $name, $ranges[$i] + 1;
                }
                else {
                    printf qq{%s:%s-%s\n}, $name, $ranges[$i] + 1, $ranges[ $i + 1 ] + 1;
                }
            }

            $name = $F[0];
            @list = ( $F[1] );
        }

        END {
            my @ranges = list_to_ranges();
            for ( my $i = 0; $i < $#ranges; $i += 2 ) {
                if ( $ranges[$i] == $ranges[ $i + 1 ] ) {
                    printf qq{%s:%s\n}, $name, $ranges[$i] + 1;
                }
                else {
                    printf qq{%s:%s-%s\n}, $name, $ranges[$i] + 1, $ranges[ $i + 1 ] + 1;
                }
            }
        }
    ' \
    > unambiguous.covered.txt

#find . -type f -name "*.sam"   | parallel --no-run-if-empty -j 1 rm

#----------------------------#
# anchor
#----------------------------#
log_info "anchor - unambiguous"
jrunlist cover unambiguous.covered.txt -o unambiguous.covered.yml
jrunlist stat sr.chr.sizes unambiguous.covered.yml -o unambiguous.covered.csv

cat unambiguous.covered.csv \
    | perl -nla -F"," -e '
        $F[0] eq q{chr} and next;
        $F[0] eq q{all} and next;
        $F[2] < [% opt.min %] and next;
        $F[3] < 0.95 and next;
        print $F[0];
    ' \
    | sort -n \
    > anchor.txt

rm unambiguous.covered.txt

#----------------------------#
# anchor2
#----------------------------#
log_info "anchor2 - unambiguous2"

# contiguous unique region longer than [% opt.min %]
jrunlist span unambiguous.covered.yml --op excise -n [% opt.min %] -o unambiguous2.covered.yml
jrunlist stat sr.chr.sizes unambiguous2.covered.yml -o unambiguous2.covered.csv

cat unambiguous2.covered.csv \
    | perl -nla -F"," -e '
        $F[0] eq q{chr} and next;
        $F[0] eq q{all} and next;
        $F[2] < [% opt.min %] and next;
        print $F[0];
    ' \
    | sort -n \
    > unambiguous2.txt

cat unambiguous2.txt \
    | perl -nl -MPath::Tiny -e '
        BEGIN {
            %seen = ();
            @ls = grep {/\S/}
                  path(q{anchor.txt})->lines({ chomp => 1});
            $seen{$_}++ for @ls;
        }

        $seen{$_} and next;
        print;
    ' \
    > anchor2.txt

rm unambiguous2.*

#----------------------------#
# basecov
#----------------------------#
log_info "basecov"
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
            printf qq{%s\t%d\n}, $name, int $mean_cov;

            $name = $F[0];
            @list = ( $F[2] );
        }

        END {
            my $mean_cov = App::Fasops::Common::mean(@list);
            printf qq{%s\t%d\n}, $name, int $mean_cov;
        }
    ' \
    > unambiguous.coverage.tsv

# How to best eliminate values in a list that are outliers
# http://www.perlmonks.org/?node_id=1147296
# http://exploringdatablog.blogspot.com/2013/02/finding-outliers-in-numerical-data.html
cat unambiguous.coverage.tsv \
    | perl -nla -MStatistics::Descriptive -e '
        BEGIN {
            our $stat   = Statistics::Descriptive::Full->new();
            our %cov_of = ();
        }

        $cov_of{ $F[0] } = $F[1];
        $stat->add_data( $F[1] );

        END {
            my $median       = $stat->median();
            my @abs_res      = map { abs( $median - $_ ) } $stat->get_data();
            my $abs_res_stat = Statistics::Descriptive::Full->new();
            $abs_res_stat->add_data(@abs_res);
            my $MAD = $abs_res_stat->median();
            my $k   = 3;                         # the scale factor

            my $lower_limit = ( $median - $k * $MAD ) / 2;
            my $upper_limit = ( $median + $k * $MAD ) * 1.5;

            for my $key ( keys %cov_of ) {
                if ( $cov_of{$key} < $lower_limit or $cov_of{$key} > $upper_limit ) {
                    print $key;
                }
            }
        }
    ' \
    > outlier.txt

cat anchor.txt anchor2.txt \
    | grep -Fx -f outlier.txt -v \
    > wanted.txt

#----------------------------#
# Split SR.fasta to anchor and others
#----------------------------#
log_info "pe.anchor.fa & pe.others.fa"
faops some -l 0 SR.fasta wanted.txt pe.anchor.fa

faops some -l 0 -i SR.fasta wanted.txt pe.others.fa

#----------------------------#
# Done.
#----------------------------#
touch anchor.success
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
