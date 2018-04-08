package App::Egaz::Command::raxml;
use strict;
use warnings;
use autodie;

use App::Egaz -command;
use App::Egaz::Common;

sub abstract {
    return 'raxml wrapper to construct phylogenetic trees';
}

sub opt_spec {
    return (
        [ "outfile|o=s",   "Output filename. [stdout] for screen", { default => "stdout" }, ],
        [ "outgroup=s",    "the name of outgroup if exists", ],
        [ "seed|s=i",      "specify a random number seed", ],
        [ "bootstrap|b=i", "the number of alternative runs",       { default => 100 }, ],
        [ "tmp=s",         "user defined tempdir", ],
        [ "parallel|p=i",  "number of threads",                    { default => 2 }, ],
        [ "verbose|v",     "verbose mode", ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "egaz raxml [options] <infile>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

* <infile> should be a blocked fasta file (*.fas)
* use `fasops concat` to create a temp relaxed phylip file
* `raxmlHPC` or `raxmlHPC-*` should be in $PATH
* `raxml` is very sensitive to CPU resources. Any competitions on cores will dramatically slow down it.

MARKDOWN

    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} != 1 ) {
        my $message = "This command need one input file.\n\tIt found";
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

    # absolute pathes as we will chdir to tempdir later
    my $infile = Path::Tiny::path( $args->[0] )->absolute->stringify;

    if ( lc $opt->{outfile} ne "stdout" ) {
        $opt->{outfile} = Path::Tiny::path( $opt->{outfile} )->absolute->stringify;
    }

    # record cwd, we'll return there
    my $cwd = Path::Tiny->cwd;
    my $tempdir;
    if ( $opt->{tmp} ) {
        $tempdir = Path::Tiny->tempdir(
            TEMPLATE => "raxml_XXXXXXXX",
            DIR      => $opt->{tmp},
        );
    }
    else {
        $tempdir = Path::Tiny->tempdir("raxml_XXXXXXXX");
    }
    chdir $tempdir;

    my $basename = $tempdir->basename();
    $basename =~ s/\W+/_/g;

    {    # .phy
        my $cmd = "fasops names $infile -o stdout > names.list";
        App::Egaz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
        if ( !$tempdir->child("names.list")->is_file ) {
            Carp::croak "Failed: fasops names\n";
        }

        $cmd = "fasops concat $infile names.list --relaxed -o stdout > $basename.phy";
        App::Egaz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
        if ( !$tempdir->child("$basename.phy")->is_file ) {
            Carp::croak "Failed: fasops concat\n";
        }
    }

    {    # run raxml
        my $exe;
        for (
            qw{raxmlHPC-AVX raxmlHPC-PTHREADS-AVX raxmlHPC-SSE3 raxmlHPC-PTHREADS-SSE3 raxmlHPC-PTHREADS raxmlHPC}
            )
        {
            if ( IPC::Cmd::can_run($_) ) {
                $exe = $_;
                last;
            }
        }
        if ( !defined $exe ) {
            Carp::croak "Failed: can't find raxmlHPC executables\n";
        }

        my $seed;
        if ( $opt->{seed} ) {
            $seed = $opt->{seed};
        }
        else {
            $seed = int( rand(10000) );
        }
        print STDERR "Random seed is [$seed]\n" if $opt->{verbose};

        my $cmd
            = "$exe -T $opt->{parallel} -f a -m GTRGAMMA -p $seed -x $seed -N $opt->{bootstrap}";
        if ( $opt->{outgroup} ) {
            $cmd .= " -o $opt->{outgroup}";
        }
        $cmd .= " -n $basename -s $basename.phy";
        App::Egaz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );

        if ( !$tempdir->child("RAxML_bipartitions.$basename")->is_file ) {
            Carp::croak "Failed: raxml\n";
        }
    }

    {    # outputs
        if ( lc $opt->{outfile} ne "stdout" ) {
            Path::Tiny::path("RAxML_bipartitions.$basename")->copy( $opt->{outfile} );
        }
        else {
            print Path::Tiny::path("RAxML_bipartitions.$basename")->slurp;
        }
    }

    chdir $cwd;
}

1;
