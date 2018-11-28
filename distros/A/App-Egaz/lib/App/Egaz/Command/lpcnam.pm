package App::Egaz::Command::lpcnam;
use strict;
use warnings;
use autodie;

use App::Egaz -command;
use App::Egaz::Common;

sub abstract {
    return 'the pipeline of pairwise lav-psl-chain-net-axt-maf';
}

sub opt_spec {
    return (
        [ "outdir|o=s", "Output directory", ],
        [ "lineargap=s",  "axtChain linearGap, loose or medium", { default => "loose" }, ],
        [ "minscore=i",   "minimum score for axtChain",          { default => 1000 }, ],
        [ "tname|t=s",    "target name", ],
        [ "qname|q=s",    "query name", ],
        [ "syn",          "create .synNet.maf instead of .net.maf", ],
        [ "parallel|p=i", "number of threads",                   { default => 2 }, ],
        [ "verbose|v",    "verbose mode", ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "egaz lpcnam [options] <path/target> <path/query> <path/lav>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

* <path/target> and <path/query> are directories containing .fa, chr.sizes and chr.2bit files
* <path/lav> can be a .lav file, lav.tar.gz or a directory containing .lav files
* Many binaries from kent-tools are needed and should be found in $PATH:
    * axtChain
    * chainAntiRepeat
    * chainMergeSort
    * chainPreNet
    * chainNet
    * netSyntenic
    * netChainSubset
    * chainStitchId
    * netSplit
    * netToAxt
    * axtSort
    * axtToMaf
    * netFilter
    * chainSplit
* [Prebuild binaries](http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/)
* `--lineargap` and `--minscore`:
    * Human18vsChimp2 use loose and 1000
    * Human19vsChimp3 use medium and 5000
    * loose is chicken/human linear gap costs
    * medium is mouse/human linear gap costs
* Default names of target and query in .maf are defined by basename of <path/target> and <path/query>

MARKDOWN

    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} != 3 ) {
        my $message = "This command need three input files/directories.\n\tIt found";
        $message .= sprintf " [%s]", $_ for @{$args};
        $message .= ".\n";
        $self->usage_error($message);
    }
    for ( @{$args} ) {
        if ( !( Path::Tiny::path($_)->is_file or Path::Tiny::path($_)->is_dir ) ) {
            $self->usage_error("The input file/directory [$_] doesn't exist.");
        }
    }

    # set default --outdir
    if ( Path::Tiny::path( $args->[2] )->is_file ) {
        if ( !$opt->{outdir} ) {
            $opt->{outdir} = ".";
            print STDERR "--outdir set to [.]\n" if $opt->{verbose};
        }
    }
    if ( Path::Tiny::path( $args->[2] )->is_dir ) {
        $opt->{outdir} = $args->[2];
        print STDERR "--outdir set to [$args->[2]]\n" if $opt->{verbose};
    }

    if ( !$opt->{tname} ) {
        $opt->{tname} = Path::Tiny::path( $args->[0] )->basename();
    }
    if ( !$opt->{qname} ) {
        $opt->{qname} = Path::Tiny::path( $args->[1] )->basename();
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #@type Path::Tiny
    my $outdir = Path::Tiny::path( $opt->{outdir} );
    $outdir->mkpath();

    #----------------------------------------------------------#
    # lav-psl-chain-net-axt section
    #----------------------------------------------------------#
    for my $d (qw{net axtNet}) {
        $outdir->child($d)->mkpath();
    }

    my $gzip_bin = "gzip";
    if ( IPC::Cmd::can_run('pigz') ) {
        $gzip_bin = "pigz -p " . $opt->{parallel};
    }

    #----------------------------#
    # lavToPsl
    #----------------------------#
    {
        my @files;
        if ( Path::Tiny::path( $args->[2] )->is_file ) {
            my $basename = Path::Tiny::path( $args->[2] )->basename();
            if ( $basename =~ m{\.lav$} ) {    # a single .lav file
                if ( !$outdir->child($basename)->is_file ) {
                    Path::Tiny::path( $args->[2] )->copy($outdir);
                    printf STDERR "* copy [%s] to [%s]\n", $args->[2], $outdir;
                }
                @files = ( $outdir->child($basename)->stringify );
            }
            else {                             # lav.tar.gz
                system "tar xvfz $args->[2] -C $outdir";
                @files = File::Find::Rule->file->name('*.lav')->in( $outdir->stringify );
            }
        }
        else {
            @files = File::Find::Rule->file->name('*.lav')->in( $outdir->stringify );
        }
        printf STDERR "* .lav files: [%d]\n", scalar @files;

        my $mce = MCE->new( chunk_size => 1, max_workers => $opt->{parallel}, );
        $mce->foreach(
            [ sort @files ],
            sub {
                my ( $self, $chunk_ref, $chunk_id ) = @_;

                my $file   = $chunk_ref->[0];
                my $output = $file;
                $output =~ s/lav$/psl/;

                my $cmd = "egaz lav2psl" . " $file" . " -o $output";
                App::Egaz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
            }
        );
    }

    #----------------------------#
    # axtChain
    #----------------------------#
    {
        my @files = File::Find::Rule->file->name('*.psl')->in( $outdir->stringify );
        printf STDERR "* .psl files: [%d]\n", scalar @files;

        my $mce = MCE->new( chunk_size => 1, max_workers => $opt->{parallel}, );
        $mce->foreach(
            [ sort @files ],
            sub {
                my ( $self, $chunk_ref, $chunk_id ) = @_;

                my $file   = $chunk_ref->[0];
                my $output = $file;
                $output =~ s/psl$/chain/;

                # axtChain - Chain together axt alignments.
                # usage:
                #   axtChain -linearGap=loose in.axt tNibDir qNibDir out.chain
                # Where tNibDir/qNibDir are either directories full of nib files, or the
                # name of a .2bit file
                #
                # chainAntiRepeat - Get rid of chains that are primarily the results of
                # repeats and degenerate DNA
                # usage:
                #    chainAntiRepeat tNibDir qNibDir inChain outChain
                # options:
                #    -minScore=N - minimum score (after repeat stuff) to pass
                #    -noCheckScore=N - score that will pass without checks (speed tweak)
                my $cmd
                    = "axtChain -minScore=$opt->{minscore} -linearGap=$opt->{lineargap} -psl"
                    . " $file"
                    . " $args->[0]/chr.2bit"
                    . " $args->[1]/chr.2bit"
                    . " stdout"
                    . " | chainAntiRepeat"
                    . " $args->[0]/chr.2bit"
                    . " $args->[1]/chr.2bit"
                    . " stdin"
                    . " $output";
                App::Egaz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
            }
        );
    }

    #----------------------------#
    # chainMergeSort and chainPreNet
    #----------------------------#
    {
        # This step would open all .chain files and reach system's maxfile limit.
        # So merge 100 files a time.
        #
        # chainMergeSort - Combine sorted files into larger sorted file
        # usage:
        #    chainMergeSort file(s)
        # Output goes to standard output
        # options:
        #    -saveId - keep the existing chain ids.
        #    -inputList=somefile - somefile contains list of input chain files.
        #    -tempDir=somedir/ - somedir has space for temporary sorting data, default ./
        my @files = File::Find::Rule->file->name('*.chain')->in( $outdir->stringify );
        my $i     = 1;
        while ( scalar @files ) {
            my @batching = splice @files, 0, 100;

            Path::Tiny::path( $outdir, "chainList.tmp" )->spew( [ map {"$_\n"} @batching ] );

            my $cmd
                = "chainMergeSort"
                . " -inputList="
                . Path::Tiny::path( $outdir, "chainList.tmp" )->stringify
                . " > $outdir/all.$i.chain.tmp";
            App::Egaz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
            Path::Tiny::path( $outdir, "chainList.tmp" )->remove;

            $i++;
        }

        my $cmd = "chainMergeSort" . " $outdir/all.*.chain.tmp" . " > $outdir/all.chain";
        App::Egaz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );

        # chainPreNet - Remove chains that don't have a chance of being netted
        # usage:
        #   chainPreNet in.chain target.sizes query.sizes out.chain
        $cmd
            = "chainPreNet"
            . " $outdir/all.chain"
            . " $args->[0]/chr.sizes"
            . " $args->[1]/chr.sizes"
            . " $outdir/all.pre.chain";
        App::Egaz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
    }

    #----------------------------#
    # chain-net
    #----------------------------#
    {
        # chainNet - Make alignment nets out of chains
        # usage:
        #   chainNet in.chain target.sizes query.sizes target.net query.net
        #
        # netSyntenic - Add synteny info to net.
        # usage:
        #   netSyntenic in.net out.net
        my $cmd
            = "chainNet -minSpace=1"
            . " $outdir/all.pre.chain"
            . " $args->[0]/chr.sizes"
            . " $args->[1]/chr.sizes"
            . " stdout"    # $dir_lav/target.chainnet
            . " $outdir/query.chainnet" . " | netSyntenic" . " stdin" . " $outdir/noClass.net";
        App::Egaz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );

        # netChainSubset - Create chain file with subset of chains that appear in
        # the net
        # usage:
        #    netChainSubset in.net in.chain out.chain
        # options:
        #    -gapOut=gap.tab - Output gap sizes to file
        #    -type=XXX - Restrict output to particular type in net file
        #    -splitOnInsert - Split chain when get an insertion of another chain
        #    -wholeChains - Write entire chain references by net, don't split
        #     when a high-level net is encoundered.  This is useful when nets
        #     have been filtered.
        #    -skipMissing - skip chains that are not found instead of generating
        #     an error.  Useful if chains have been filtered.
        #
        # chainStitchId - Join chain fragments with the same chain ID into a single
        #    chain per ID.  Chain fragments must be from same original chain but
        #    must not overlap.  Chain fragment scores are summed.
        # usage:
        #    chainStitchId in.chain out.chain
        $cmd
            = "netChainSubset -verbose=0 $outdir/noClass.net"
            . " $outdir/all.chain"
            . " stdout"
            . " | chainStitchId"
            . " stdin"
            . " $outdir/over.chain";
        App::Egaz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );

        # netSplit - Split a genome net file into chromosome net files
        # usage:
        #   netSplit in.net outDir
        $cmd = "netSplit" . " $outdir/noClass.net" . " $outdir/net";
        App::Egaz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
    }

    #----------------------------#
    # netToAxt
    #----------------------------#
    {
        my @files = File::Find::Rule->file->name('*.net')->in("$outdir/net");
        printf STDERR "* .net files: [%d]\n", scalar @files;

        my $mce = MCE->new( chunk_size => 1, max_workers => $opt->{parallel}, );
        $mce->foreach(
            [ sort @files ],
            sub {
                my ( $self, $chunk_ref, $chunk_id ) = @_;

                my $file   = $chunk_ref->[0];
                my $output = Path::Tiny::path($file)->basename;
                $output .= ".axt.gz";

                # netToAxt - Convert net (and chain) to axt.
                # usage:
                #   netToAxt in.net in.chain target.2bit query.2bit out.axt
                # note:
                # directories full of .nib files (an older format)
                # may also be used in place of target.2bit and query.2bit.
                #
                # axtSort - Sort axt files
                # usage:
                #   axtSort in.axt out.axt
                my $cmd
                    = "netToAxt"
                    . " $file"
                    . " $outdir/all.pre.chain"
                    . " $args->[0]/chr.2bit"
                    . " $args->[1]/chr.2bit"
                    . " stdout"
                    . " | axtSort stdin stdout"
                    . " | $gzip_bin >"
                    . " $outdir/axtNet/$output";
                App::Egaz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
            }
        );

    }

    #----------------------------#
    # clean
    #----------------------------#
    {
        my $cwd = Path::Tiny->cwd;
        chdir $outdir;

        # bsdtar (mac) doesn't support `--remove-files`
        if ( !-e "lav.tar.gz" ) {
            App::Egaz::Common::exec_cmd( "tar -cvf - *.lav | $gzip_bin > lav.tar.gz",
                { verbose => $opt->{verbose}, } );
        }
        for ( Path::Tiny::path(".")->children(qr/\.lav$/) ) {
            $_->remove;
        }

        App::Egaz::Common::exec_cmd( "tar -cvf - net/ | $gzip_bin > net.tar.gz",
            { verbose => $opt->{verbose}, } );
        Path::Tiny::path("net")->remove_tree;

        App::Egaz::Common::exec_cmd( "tar -cvf - *.psl | $gzip_bin > psl.tar.gz",
            { verbose => $opt->{verbose}, } );
        for ( Path::Tiny::path(".")->children(qr/^.+\.psl$/) ) {
            $_->remove;
        }

        for ( Path::Tiny::path(".")->children(qr/\.tmp$/) ) {
            $_->remove;
        }

        for my $p (qw{all all.pre over}) {
            App::Egaz::Common::exec_cmd( "$gzip_bin $p.chain", { verbose => $opt->{verbose}, } );
        }

        App::Egaz::Common::exec_cmd( "tar -cvf - *.chain | $gzip_bin > chain.tar.gz",
            { verbose => $opt->{verbose}, } );
        for ( Path::Tiny::path(".")->children(qr/^.+\.chain$/) ) {
            $_->remove;
        }

        chdir $cwd;
    }

    #----------------------------------------------------------#
    # axt-maf section
    #----------------------------------------------------------#
    if ( !$opt->{syn} ) {
        $outdir->child("mafNet")->mkpath();

        my @files = File::Find::Rule->file->name('*.axt')->in( $outdir->stringify );
        @files = File::Find::Rule->file->name('*.axt.gz')->in( $outdir->stringify )
            if scalar @files == 0;
        printf STDERR "* .axt files: [%d]\n", scalar @files;

        #----------------------------#
        # axtToMaf
        #----------------------------#
        my $worker = sub {
            my ( $self, $chunk_ref, $chunk_id ) = @_;

            my $file = $chunk_ref->[0];
            my $output = Path::Tiny::path($file)->basename( ".axt", ".axt.gz" );
            $output = Path::Tiny::path( $outdir, "mafNet", "$output.maf.gz" )->stringify;

            # axtToMaf - Convert from axt to maf format
            # usage:
            #    axtToMaf in.axt tSizes qSizes out.maf
            # Where tSizes and qSizes is a file that contains
            # the sizes of the target and query sequences.
            # Very often this with be a chrom.sizes file
            # Options:
            #     -qPrefix=XX. - add XX. to start of query sequence name in maf
            #     -tPrefix=YY. - add YY. to start of target sequence name in maf
            #     -tSplit Create a separate maf file for each target sequence.
            #             In this case output is a dir rather than a file
            #             In this case in.maf must be sorted by target.
            #     -score       - recalculate score
            #     -scoreZero   - recalculate score if zero
            my $cmd
                = "axtToMaf"
                . " -tPrefix=$opt->{tname}."
                . " -qPrefix=$opt->{qname}."
                . " $file"
                . " $args->[0]/chr.sizes"
                . " $args->[1]/chr.sizes"
                . " stdout"
                . " | $gzip_bin >"
                . " $output";
            App::Egaz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
        };

        my $mce = MCE->new( chunk_size => 1, max_workers => $opt->{parallel}, );
        $mce->foreach( [ sort @files ], $worker );
    }
    else {
        for my $d (qw{chain synNet mafSynNet}) {
            $outdir->child($d)->mkpath();
        }

        #----------------------------#
        # synNetMaf
        #----------------------------#

        {
            # netFilter - Filter out parts of net.  What passes
            # filter goes to standard output.  Note a net is a
            # recursive data structure.  If a parent fails to pass
            # the filter, the children are not even considered.
            # usage:
            #    netFilter in.net(s)
            my $cmd
                = "netFilter" . " -syn"
                . " $outdir/noClass.net"
                . " | netSplit stdin"
                . " $outdir/synNet";
            App::Egaz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
        }

        {
            # chainSplit - Split chains up by target or query sequence
            # usage:
            #    chainSplit outDir inChain(s)
            # options:
            #    -q  - Split on query (default is on target)
            #    -lump=N  Lump together so have only N split files.
            my $cmd = "chainSplit" . " $outdir/chain" . " $outdir/all.chain.gz";
            App::Egaz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
        }

        {
            my @files = File::Find::Rule->file->name('*.net')->in("$outdir/synNet");
            printf STDERR "* .net files: [%d]\n", scalar @files;

            my $worker = sub {
                my ( $self, $chunk_ref, $chunk_id ) = @_;

                my $file = $chunk_ref->[0];
                my $base = Path::Tiny::path($file)->basename(".net");
                my $output
                    = Path::Tiny::path( $outdir, "mafSynNet", "$base.synNet.maf.gz" )->stringify;
                my $chain_file = Path::Tiny::path( $outdir, "chain", "$base.chain" )->stringify;

                my $cmd
                    = "netToAxt"
                    . " $file"
                    . " $chain_file"
                    . " $args->[0]/chr.2bit"
                    . " $args->[1]/chr.2bit"
                    . " stdout"
                    . " | axtSort stdin stdout"
                    . " | axtToMaf"
                    . " -tPrefix=$opt->{tname}."
                    . " -qPrefix=$opt->{qname}."
                    . " stdin"
                    . " $args->[0]/chr.sizes"
                    . " $args->[1]/chr.sizes"
                    . " stdout"
                    . " | $gzip_bin >"
                    . " $output";
                App::Egaz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );

                return;
            };

            my $mce = MCE->new( chunk_size => 1, max_workers => $opt->{parallel}, );
            $mce->foreach( [ sort @files ], $worker );
        }

        #----------------------------#
        # clean
        #----------------------------#
        {
            Path::Tiny::path( $outdir, "synNet" )->remove_tree;
            Path::Tiny::path( $outdir, "chain" )->remove_tree;
        }
    }

    return;
}

1;
