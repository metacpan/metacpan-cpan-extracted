package App::Egaz::Command::multiz;
use strict;
use warnings;
use autodie;

use MCE;
use MCE::Flow;

use App::Egaz -command;
use App::Egaz::Common;

sub abstract {
    return 'multiz step by step';
}

sub opt_spec {
    return (
        [ "outdir|o=s", "Output directory", ],
        [ "tree=s",     "a rooted newick tree", ],
        [ "target=s",   "target name, this command can automatically pick one", ],
        [ "keeptmp",    "keep intermediate files", ],
        [ "parallel|p=i", "number of threads", { default => 2 }, ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "egaz multiz [options] <maf dir> [more dirs]";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

* <maf dirs> are directories containing multiple .maf or .maf.gz files
* `multiz` should be in $PATH
* Use a modified [`multiz`](https://github.com/wang-q/multiz) supports gzipped .maf files
* [Original `multiz`](https://www.bx.psu.edu/miller_lab/)

MARKDOWN

    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} < 1 ) {
        my $message = "This command need one or more input directories.\n\tIt found";
        $message .= sprintf " [%s]", $_ for @{$args};
        $message .= ".\n";
        $self->usage_error($message);
    }
    for ( @{$args} ) {
        if ( !( Path::Tiny::path($_)->is_dir ) ) {
            $self->usage_error("The input directory [$_] doesn't exist.");
        }
    }

    if ( $opt->{tree} ) {
        if ( !( Path::Tiny::path( $opt->{tree} )->is_file ) ) {
            $self->usage_error("The newick tree file [$opt->{tree}] doesn't exist.");
        }
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #----------------------------#
    # inputs
    #----------------------------#
    my $suffix = '.maf';
    my @files  = File::Find::Rule->file->name("*$suffix")->in( @{$args} );
    if ( scalar @files == 0 ) {
        $suffix = '.maf.gz';
        @files  = sort File::Find::Rule->file->name("*$suffix")->in( @{$args} );
    }
    printf STDERR "* $suffix files: [%d]\n", scalar @files;

    if ( scalar @files == 0 ) {
        Carp::croak "Can't find .maf or .maf.gz files\n";
    }

    #----------------------------#
    # Gather species list
    #----------------------------#
    #---
    #Q_aliena:
    #  NC_020152:
    #    - t/Q_rubravsQ_aliena/mafSynNet/NC_020152.synNet.maf.gz
    #Q_aquifolioides:
    #  NC_020152:
    #    - t/Q_rubravsQ_aquifolioides/mafSynNet/NC_020152.synNet.maf.gz
    my $file_of = {};    # all info here
    my %seen;            # count
    my @potential_targets;
    my @species;         # species list gathered from maf files; and then shift target out

    {
        print STDERR "Get species list\n";
        my $worker = sub {
            my ( $self, $chunk_ref, $chunk_id ) = @_;
            my $file = $chunk_ref->[0];

            my $cmd
                = "gzip -dcf $file "
                . q{ | perl -nl -e '/^s (\w+)/ or next; print $1' }
                . q{ | sort | uniq};
            my @list = grep { defined $_ } split /\n/, `$cmd`;
            if ( @list > 2 ) {
                Carp::croak "There are three or more species in [$file].\n"
                    . YAML::Syck::Dump( \@list );
            }

            MCE->gather( $file, [@list] );
        };
        MCE::Flow::init {
            chunk_size  => 1,
            max_workers => $opt->{parallel},
        };
        my %list_of = mce_flow $worker, \@files;
        MCE::Flow::finish;

        print STDERR "Assign files to species\n";
        for my $file (@files) {
            my @list = @{ $list_of{$file} };
            $seen{$_}++ for @list;

            my $chr_name
                = Path::Tiny::path($file)->basename( ".net$suffix", ".synNet$suffix", $suffix );
            for my $sp (@list) {
                if ( exists $file_of->{$sp} ) {
                    if ( exists $file_of->{$sp}{$chr_name} ) {
                        push @potential_targets, $sp;
                        push @{ $file_of->{$sp}{$chr_name} }, $file;
                    }
                    else {
                        $file_of->{$sp}{$chr_name} = [$file];
                    }
                    $file_of->{$sp}{chr_set}->insert($chr_name);
                }
                else {
                    my $chr_set = Set::Scalar->new;
                    $chr_set->insert($chr_name);
                    $file_of->{$sp} = { $chr_name => [$file], chr_set => $chr_set };
                }
            }
        }

        @potential_targets = List::MoreUtils::PP::uniq(@potential_targets);
        (@species) = map { $_->[0] }
            sort { $b->[1] <=> $a->[1] }
            map { [ $_, $seen{$_} ] }
            keys %seen;
    }

    #----------------------------#
    # check number of species
    #----------------------------#
    if ( scalar @species < 3 ) {
        print STDERR "There're too few species, [@species].\n";
        print STDERR "Can't run multiz.\n";

        if ( !$opt->{outdir} ) {
            if ( $opt->{target} ) {
                $opt->{outdir} = $opt->{target} . "_n2";
            }
            else {
                $opt->{outdir} = $species[0] . "_n2";
            }
        }

        Path::Tiny::path( $opt->{outdir} )->mkpath();
        print STDERR "Just copy pairwise maf to [$opt->{outdir}]\n";

        for my $file (@files) {
            Path::Tiny::path($file)->copy( $opt->{outdir} );
        }

        return;
    }

    #----------------------------#
    # check target
    #----------------------------#
    if ( @potential_targets > 1 ) {
        Carp::croak "There are more than 1 potential targets\n"
            . YAML::Syck::Dump( \@potential_targets );
    }
    else {
        if ( !$opt->{target} ) {
            $opt->{target} = shift @species;
            if ( $opt->{target} eq $potential_targets[0] ) {
                printf STDERR "%s appears %d times, use it as target.\n", $opt->{target},
                    $seen{ $opt->{target} };
            }
            else {
                Carp::croak "Can't find target.\n";
            }
        }
        else {
            my ($dummy) = grep { $_ eq $opt->{target} } @species;
            if ( !defined $dummy ) {
                Carp::croak "Can't find target_name [$opt->{target}] in .maf files.\n";
            }
            elsif ( $opt->{target} eq $potential_targets[0] ) {
                print STDERR "Assigned target [$opt->{target}] is OK\n";
                @species = grep { $_ ne $opt->{target} } @species;
            }
            else {
                Carp::croak "Assigned target [$opt->{target}] isn't OK.\n"
                    . "It should be [$potential_targets[0]].\n";
            }
        }
    }

    #----------------------------#
    # Find chromosomes
    #----------------------------#
    my @chrs = sort $file_of->{ $opt->{target} }{chr_set}->members;    # all target chromosomes
    {
        print STDERR "Target chromosomes are [@chrs]\n";

        # check other species occurrence number
        my @occurrence = sort { $b <=> $a } List::MoreUtils::PP::uniq( @seen{@species} );
        if ( @occurrence > 1 ) {
            print STDERR "Species occurrence number inconsistency [@occurrence]\n";
            print STDERR "We will skip some chromosomes\n";
            print STDERR YAML::Syck::Dump \%seen;
            print STDERR "\n";

            my $intersect_chr_set = $file_of->{ $opt->{target} }{chr_set}->clone;
            for my $sp ( keys %{$file_of} ) {
                $intersect_chr_set = $intersect_chr_set->intersection( $file_of->{$sp}{chr_set} );
            }
            @chrs = sort $intersect_chr_set->members;
            print STDERR "Chromosomes to be processed are [@chrs]\n";
        }

        # sort @species by distances in tree
        if ( $opt->{tree} ) {
            my $ladder = App::Egaz::Common::ladder( $opt->{tree}, $opt->{target} );
            my @orders = map { ref eq 'ARRAY' ? @$_ : $_ } @{$ladder};
            my %item_order = map { $orders[$_] => $_ } 0 .. $#orders;

            @species = map { $_->[0] }
                sort { $a->[1] <=> $b->[1] }
                map { [ $_, $item_order{$_} ] } @species;
        }

        print STDERR "Order of stitch [@species]\n";
    }

    if ( !$opt->{outdir} ) {
        $opt->{outdir} = $opt->{target} . "_n" . ( scalar(@species) + 1 );
        print STDERR "--outdir set to [$opt->{outdir}]\n";
    }
    Path::Tiny::path( $opt->{outdir} )->mkpath();

    YAML::Syck::DumpFile(
        Path::Tiny::path( $opt->{outdir}, 'info.yml' )->stringify,
        {   file_of => $file_of,
            chrs    => \@chrs,
        }
    );

    #----------------------------#
    # Finally, multiz comes
    #----------------------------#
    my $worker = sub {
        my ( $self, $chunk_ref, $chunk_id ) = @_;

        my $chr_name = $chunk_ref->[0];

        # multiz.v11.2: -- aligning two files of alignment blocks where top rows are
        # always the reference, reference in both files cannot have duplicats
        # args: [R=?] [M=?] file1 file2 v? [out1 out2] [nohead] [all]
        #         R(30) radius in dynamic programming.
        #         M(1) minimum output width.
        #         out1 out2(null) null: stdout; out1 out2: file names for collecting unused input.
        #         nohead(null) null: output maf header; nohead: not to output maf header.
        #         all(null) null: not to output single-row blocks; all: output all blocks.
        #
        # multiz t/Q_rubravsQ_aliena/mafSynNet/NC_020152.synNet.maf.gz \
        #       t/Q_rubravsQ_aquifolioides/mafSynNet/NC_020152.synNet.maf.gz \
        #       1 out1 out2 > step1.chr1.maf
        # multiz step1.chr1.maf t/Q_rubravsQ_baronii/mafSynNet/NC_020152.synNet.maf.gz \
        #       1 out1 out2 > step2.chr1.maf

        my @species_copy = @species;
        my ( $species1, $species2 );
        my $maf_step;
        my $step = 1;
        my $str  = '';
        while (@species_copy) {
            my ( $maf1, $maf2 );

            if ( !defined $species1 ) {
                $species1 = shift @species_copy;
                $maf1     = $file_of->{$species1}{$chr_name}[0];
            }
            else {
                $maf1 = $maf_step;
            }
            if ( !defined $species2 ) {
                $species2 = shift @species_copy;
                $maf2     = $file_of->{$species2}{$chr_name}[0];
            }

            my $out1 = "$opt->{outdir}/$chr_name.out1";
            my $out2 = "$opt->{outdir}/$chr_name.out2";

            $maf_step
                = @species_copy
                ? "$opt->{outdir}/$chr_name.step$step.maf"
                : "$opt->{outdir}/$chr_name.maf";

            # here we set out1 and out2 to discard unused synteny
            # Omit out1 and out2, unused synteny will be printed to stdout and
            # reused by following multiz processes
            my $cmd
                = "multiz" . " M=10"
                . " $maf1"
                . " $maf2" . " 1 "
                . " $out1"
                . " $out2"
                . " > $maf_step";
            App::Egaz::Common::exec_cmd( $cmd, { verbose => 1, } );
            print STDERR "Step [$step] .maf file generated.\n";

            $str .= "$chr_name.step$step,";
            $str .= "$species1,$species2,";
            for my $file ( $maf1, $maf2, $out1, $out2, $maf_step ) {
                $str .= Number::Format::format_bytes( -s $file, base => 1000 );
                $str .= ",";
            }
            $str .= Number::Format::format_bytes( ( -s $maf_step ) / ( $step + 2 ), base => 1000 );
            $str .= "\n";

            $species1 = "step$step";
            $species2 = undef;
            $step++;
        }

        if ( !$opt->{keeptmp} ) {
            Path::Tiny::path( $opt->{outdir}, "$chr_name.out1" )->remove;
            Path::Tiny::path( $opt->{outdir}, "$chr_name.out2" )->remove;
            for ( Path::Tiny::path( $opt->{outdir} )->children(qr/^$chr_name\.step/) ) {
                $_->remove;
            }
        }

        my $cmd = "gzip " . "$opt->{outdir}/$chr_name.maf";
        App::Egaz::Common::exec_cmd( $cmd, { verbose => 1, } );

        print STDERR $str;
        Path::Tiny::path( $opt->{outdir}, "$chr_name.temp.csv" )->remove;
        Path::Tiny::path( $opt->{outdir}, "$chr_name.temp.csv" )->spew($str);

        return;
    };

    my $mce = MCE->new( chunk_size => 1, max_workers => $opt->{parallel}, );
    $mce->foreach( \@chrs, $worker );

    #----------------------------#
    # Summary
    #----------------------------#
    {
        my $cmd = "echo 'step,spe1,spe2,maf1,maf2,out1,out2,size,per_size'"
            . " > $opt->{outdir}/steps.csv";
        App::Egaz::Common::exec_cmd( $cmd, { verbose => 1, } );

        $cmd
            = "find $opt->{outdir} -type f -name '*.temp.csv'"
            . " | sort -n"
            . " | xargs cat >> $opt->{outdir}/steps.csv";
        App::Egaz::Common::exec_cmd( $cmd, { verbose => 1, } );

        $cmd = "find $opt->{outdir} -type f -name '*.temp.csv'" . " | xargs rm";
        App::Egaz::Common::exec_cmd( $cmd, { verbose => 1, } );
    }

    return;
}

1;
