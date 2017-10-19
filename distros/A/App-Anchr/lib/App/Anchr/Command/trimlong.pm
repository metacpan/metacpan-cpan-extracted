package App::Anchr::Command::trimlong;
use strict;
use warnings;
use autodie;

use App::Anchr - command;
use App::Anchr::Common;

use constant abstract => "trim long reads with minimap";

sub opt_spec {
    return (
        [ "outfile|o=s", "output filename, [stdout] for screen", ],
        [ "coverage|c=i", "minimal coverage",           { default => 3 }, ],
        [ "len|l=i",      "minimal length of overlaps", { default => 1000 }, ],
        [ "parallel|p=i", "number of threads",          { default => 8 }, ],
        [ "verbose|v",    "verbose mode", ],
        [   "jvm=s",
            "jvm parameters for jrange, e.g. '-d64 -server -Xms1g -Xmx64g -XX:-UseGCOverheadLimit'",
        ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "anchr trimlong [options] <infile>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= "\tAll operations are running in a tempdir and no intermediate files are kept.\n";
    $desc
        .= "\tThe inaccuracy of overlap boundary identified by mininap may loose some parts of reads, ";
    $desc .= "\tbut also prevent adaptor or chimeric sequences joining with good parts of reads.\n";
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

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".cover.fasta";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    # make paths absolute before we chdir
    my $infile = Path::Tiny::path( $args->[0] )->absolute->stringify;

    if ( lc $opt->{outfile} ne "stdout" ) {
        $opt->{outfile} = Path::Tiny::path( $opt->{outfile} )->absolute->stringify;
    }

    # record cwd, we'll return there
    my $cwd     = Path::Tiny->cwd;
    my $tempdir = Path::Tiny->tempdir("anchr_trimlong_XXXXXXXX");
    chdir $tempdir;

    my $basename = $tempdir->basename();
    $basename =~ s/\W+/_/g;

    {    # Call minimap
        my $cmd;
        $cmd .= "minimap";
        $cmd .= " -Sw5 -L100 -m0 -t$opt->{parallel}";
        $cmd .= " $infile $infile";
        $cmd .= " > $basename.paf";
        App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );

        if ( !$tempdir->child("$basename.paf")->is_file ) {
            Carp::croak "Failed: create $basename.paf\n";
        }
    }

    {    # paf to covered
        my $cmd;
        if ( $opt->{jvm} ) {
            my $jrange_path = `jrange path`;
            chomp $jrange_path;
            $cmd .= sprintf "java -jar %s %s", $opt->{jvm}, $jrange_path;
        }
        else {
            $cmd .= "jrange";
        }

        $cmd .= " covered $basename.paf";
        $cmd .= " --coverage $opt->{coverage} --len $opt->{len} --longest --paf";
        $cmd .= " -o $basename.covered.txt";
        App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );

        if ( !$tempdir->child("$basename.covered.txt")->is_file ) {
            Carp::croak "Failed: create $basename.covered.txt\n";
        }
    }

    {    # Outputs. stdout is handeld by faops
        my $cmd;
        $cmd .= "faops region -l 0 $infile $basename.covered.txt $opt->{outfile}";
        App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
    }

    chdir $cwd;
}

1;
