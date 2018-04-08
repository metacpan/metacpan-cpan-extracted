package App::Egaz::Command::lastz;
use strict;
use warnings;
use autodie;

use App::Egaz -command;
use App::Egaz::Common;

sub abstract {
    return 'lastz wrapper for two genomes or self alignments';
}

sub opt_spec {
    return (
        [ "outdir|o=s",   "Output directory",  { default => "." }, ],
        [ "tp",           "target sequences are partitioned", ],
        [ "qp",           "query sequences are partitioned", ],
        [ "paired",       "relationships between target and query are one-to-one", ],
        [ "isself",       "self-alignment", ],
        [ "set|s=s",      "use a predefined lastz parameter set", ],
        [ "O=i",          "Scoring: gap-open penalty", ],
        [ "E=i",          "Scoring: gap-extension penalty", ],
        [ "Q=s",          "Scoring: matrix file", ],
        [ "C=i",          "Aligning: chain option", ],
        [ "T=i",          "Aligning: words option", ],
        [ "M=i",          "Aligning: mask any base in seq1 hit this many times", ],
        [ "K=i",          "Dropping hsp: threshold for MSPs for the first pass", ],
        [ "L=i",          "Dropping hsp: threshold for gapped alignments for the second pass", ],
        [ "H=i",          "Dropping hsp: threshold to be interpolated between alignments", ],
        [ "Y=i",          "Dropping hsp: X-drop parameter for gapped extension", ],
        [ "Z=i",          "Speedup: increment between successive words", ],
        [ "parallel|p=i", "number of threads", { default => 2 }, ],
        [ "verbose|v",    "verbose mode", ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "egaz lastz [options] <path/target> <path/query>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

* <path/target> or <path/query> can be .fa files or directory containing multiple .fa files
* Lastz will take the first sequence in target fasta files and all sequences in query fasta files.
* For less confusions, each fasta files should contain only one sequence. Use `egaz prepseq` to do this.
* Fasta file naming rules: "seqfile.fa" or "seqfile.fa[from,to]"
* Lav file naming rules: "[target]vs[query].N.lav"
* Predefined parameter sets and scoring matrix can be found in `share/`
* `lastz` should be in $PATH
* [`lastz` help](http://www.bx.psu.edu/~rsharris/lastz/README.lastz-1.04.00.html)
* [`--isself`](http://www.bx.psu.edu/~rsharris/lastz/README.lastz-1.04.00.html#ex_self)

MARKDOWN

    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} != 2 ) {
        my $message = "This command need two input files/directories.\n\tIt found";
        $message .= sprintf " [%s]", $_ for @{$args};
        $message .= ".\n";
        $self->usage_error($message);
    }
    for ( @{$args} ) {
        if ( !( Path::Tiny::path($_)->is_file or Path::Tiny::path($_)->is_dir ) ) {
            $self->usage_error("The input file/directory [$_] doesn't exist.");
        }
    }

    # load parameter sets
    if ( $opt->{set} ) {
        print STDERR "* Use parameter set $opt->{set}\n";
        my $yml_file = File::ShareDir::dist_file( 'App-Egaz', 'parameters.yml' );
        my $yml = YAML::Syck::LoadFile($yml_file);

        if ( !exists $yml->{ $opt->{set} } ) {
            $self->usage_error("--set [$opt->{set}] doesn't exist.");
        }

        # Getopt::Long::Descriptive store opts in small cases
        my $para_set = $yml->{ $opt->{set} };
        for my $key ( map {lc} keys %{$para_set} ) {
            next if $key eq "comment";
            next if defined $opt->{$key};
            $opt->{$key} = $para_set->{ uc $key };
        }
    }

    # scoring matrix
    if ( $opt->{q} ) {
        if ( $opt->{q} eq "default" ) {
            $opt->{q} = File::ShareDir::dist_file( 'App-Egaz', 'matrix/default' );
        }
        elsif ( $opt->{q} eq "distant" ) {
            $opt->{q} = File::ShareDir::dist_file( 'App-Egaz', 'matrix/distant' );
        }
        elsif ( $opt->{q} eq "similar" ) {
            $opt->{q} = File::ShareDir::dist_file( 'App-Egaz', 'matrix/similar' );
        }
        elsif ( $opt->{q} eq "similar2" ) {
            $opt->{q} = File::ShareDir::dist_file( 'App-Egaz', 'matrix/similar2' );
        }
        elsif ( !Path::Tiny::path( $opt->{q} )->is_file ) {
            $self->usage_error("The matrix file [$opt->{q}] doesn't exist.\n");
        }
    }

}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #@type Path::Tiny
    my $outdir = Path::Tiny::path( $opt->{outdir} );
    $outdir->mkpath();

    #----------------------------#
    # inputs
    #----------------------------#
    my ( @t_files, @q_files );
    if ( $opt->{tp} ) {
        @t_files = File::Find::Rule->file->name(qr{\.fa\[.+\]$})->in( $args->[0] );
    }
    else {
        @t_files = File::Find::Rule->file->name('*.fa')->in( $args->[0] );
    }
    if ( $opt->{qp} ) {
        @q_files = File::Find::Rule->file->name(qr{\.fa\[.+\]$})->in( $args->[1] );
    }
    else {
        @q_files = File::Find::Rule->file->name('*.fa')->in( $args->[1] );
    }
    printf STDERR "* T files: [%d]; Q files: [%d]\n", scalar @t_files, scalar @q_files;

    #----------------------------#
    # lastz
    #----------------------------#
    {
        my $lz_opt;
        for my $key (qw{O E Q C T M K L H Y Z }) {
            my $value = $opt->{ lc $key };
            if ( defined $value ) {
                $lz_opt .= " $key=$value";
            }
        }
        print STDERR $lz_opt if $lz_opt and $opt->{verbose};

        my $worker = sub {
            my ( $self, $chunk_ref, $chunk_id ) = @_;

            my $job = $chunk_ref->[0];

            my ( $target, $query ) = split /\t/, $job;

            # naming the .lav file
            # remove .fa or .fa[1,10000]
            my $t_base = Path::Tiny::path($target)->basename;
            $t_base =~ s/\..+?$//;
            my $q_base = Path::Tiny::path($query)->basename;
            $q_base =~ s/\..+?$//;

            my $lav_file;
            my $i = 0;
            while (1) {
                my $file = "[${t_base}]vs[${q_base}].$i.lav";
                $file = $outdir . "/" . $file;
                if ( !-e $file ) {
                    $lav_file = $file;
                    last;
                }
                $i++;
            }

            my $cmd = "lastz $target $query";
            if ( $opt->{isself} and $target eq $query ) {
                $cmd = "lastz $target --self";
            }
            $cmd .= " $lz_opt" if $lz_opt;
            $cmd .= " > $lav_file";

            App::Egaz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );

            return;
        };

        # All jobs to be done
        my @jobs;
        if ( $opt->{paired} ) {    # use the most similar chr name
            for my $t_file ( sort @t_files ) {
                my $t_base = Path::Tiny::path($t_file)->basename;
                my ($q_file) = map { $_->[0] }
                    sort { $b->[1] <=> $a->[1] }
                    map { [ $_, similarity( Path::Tiny::path($_)->basename, $t_base ) ] } @q_files;
                push @jobs, "$t_file\t$q_file";
            }
        }
        else {
            for my $t_file ( sort @t_files ) {
                for my $q_file ( sort @q_files ) {
                    push @jobs, "$t_file\t$q_file";
                }
            }
        }

        my $mce = MCE->new( chunk_size => 1, max_workers => $opt->{parallel}, );
        $mce->foreach( \@jobs, $worker );
    }

    #----------------------------#
    # normalize
    #----------------------------#
    if ( $opt->{tp} or $opt->{qp} ) {
        my @files = File::Find::Rule->file->name('*.lav')->in( $outdir->stringify );
        printf STDERR "* .lav files: [%d]\n", scalar @files;

        my ( %t_length, %q_length );
        if ( $opt->{tp} ) {
            %t_length = %{
                App::RL::Common::read_sizes(
                    Path::Tiny::path( $args->[0], 'chr.sizes' )->stringify
                )
            };
        }
        if ( $opt->{qp} ) {
            %q_length = %{
                App::RL::Common::read_sizes(
                    Path::Tiny::path( $args->[1], 'chr.sizes' )->stringify
                )
            };
        }

        my $mce = MCE->new( chunk_size => 1, max_workers => $opt->{parallel}, );
        $mce->foreach(
            [ sort @files ],
            sub {
                my ( $self, $chunk_ref, $chunk_id ) = @_;

                my $file = $chunk_ref->[0];

                $file =~ /\[(.+?)\]vs\[(.+?)\]/;
                my $t_name = $1;
                my $q_name = $2;

                my $outfile = $file;
                $outfile =~ s/\.lav$/\.norm\.lav/;

                my $t_len = $opt->{tp} ? $t_length{$t_name} : 0;
                my $q_len = $opt->{qp} ? $q_length{$q_name} : 0;

                my $cmd = "egaz normalize" . " --tlen $t_len --qlen $q_len" . " $file -o $outfile";

                App::Egaz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
                Path::Tiny::path($file)->remove;
            }
        );
    }

    return;
}

1;
