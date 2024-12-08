package App::Egaz::Command::repeatmasker;
use strict;
use warnings;
use autodie;

use App::Egaz -command;
use App::Egaz::Common;

sub abstract {
    return 'RepeatMasker wrapper';
}

sub opt_spec {
    return (
        [ "outdir|o=s",   "Output directory",  { default => "." }, ],
        [ "species=s",    "the species or clade of the input sequence", ],
        [ "opt=s",        "other options be passed to RepeatMasker", ],
        [ "gff",          "create .rm.gff by rmOutToGFF3.pl", ],
        [ "tmp=s",        "user defined tempdir", ],
        [ "parallel|p=i", "number of threads", { default => 2 }, ],
        [ "verbose|v",    "verbose mode", ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "egaz repeatmasker [options] <infile> [more infiles]";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

* <infile> should be fasta files (*.fa, *.fasta)
* setting --outdir to the same one of infiles will replace original files
* `repeatmasker` should be in $PATH
* suffix of masked files is .fa, when --outdir is the same as infile:
    * infile.fa may be replaced
    * infile.fasta or infile.others will coexist with infile.fa

MARKDOWN

    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} < 1 ) {
        my $message = "This command need one or more input files.\n\tIt found";
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
    my @infiles;
    for my $infile ( @{$args} ) {
        push @infiles, Path::Tiny::path($infile)->absolute->stringify;
    }
    $opt->{outdir} = Path::Tiny::path( $opt->{outdir} )->absolute->stringify;

    # record cwd, we'll return there
    my $cwd = Path::Tiny->cwd;
    my $tempdir;
    if ( $opt->{tmp} ) {
        $tempdir = Path::Tiny->tempdir(
            TEMPLATE => "repeatmasker_XXXXXXXX",
            DIR      => $opt->{tmp},
        );
    }
    else {
        $tempdir = Path::Tiny->tempdir("repeatmasker_XXXXXXXX");
    }
    chdir $tempdir;

    for my $infile (@infiles) {
        my $filename = Path::Tiny::path($infile)->basename();
        my $basename = Path::Tiny::path($infile)->basename(qr/\..+?/);

        my $cmd = "RepeatMasker";
        $cmd .= " $infile";
        $cmd .= " -dir .";
        $cmd .= " -species $opt->{species}" if $opt->{species};
        $cmd .= " $opt->{opt}" if $opt->{opt};
        $cmd .= " -xsmall --parallel $opt->{parallel}";
        App::Egaz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
        if ( !$tempdir->child("$filename.masked")->is_file ) {
            Carp::croak "RepeatMasker on [$infile] failed\n";
        }

        Path::Tiny::path("$filename.masked")->copy("$opt->{outdir}/$basename.fa");
        Path::Tiny::path("$filename.out")->copy("$opt->{outdir}/$basename.rm.out");

        if ( $opt->{gff} ) {

            # RepeatMasker can be
            # a symlink
            #   /home/linuxbrew/.linuxbrew/bin/RepeatMasker
            # or a real executable file
            #   /home/linuxbrew/.linuxbrew/Cellar/repeatmasker/4.0.7_2/bin/RepeatMasker
            #   /home/linuxbrew/.linuxbrew/Cellar/repeatmasker/4.0.7_2/libexec/RepeatMasker
            #
            # We want find here
            #   /home/linuxbrew/.linuxbrew/Cellar/repeatmasker/4.0.7_2/libexec/util/rmOutToGFF3.pl
            my $rm_bin  = IPC::Cmd::can_run("RepeatMasker");
            my $rm_path = Path::Tiny::path($rm_bin)->realpath;

            #@type Path::Tiny
            my $rm2gff;

            if ( $rm_path->parent->child("util")->is_dir ) {
                $rm2gff = $rm_path->parent()->child("util/rmOutToGFF3.pl");
            }
            else {
                $rm2gff = $rm_path->parent(2)->child("libexec/util/rmOutToGFF3.pl");
            }
            if ( !$rm2gff->is_file ) {
                print STDERR YAML::Syck::Dump(
                    {   "rm_bin"  => $rm_bin,
                        "rm_path" => $rm_path,
                        "rm2gff"  => $rm2gff
                    }
                );
                Carp::croak "Can't find rmOutToGFF3.pl\n";
            }

            $cmd = "perl $rm2gff";
            $cmd .= " $filename.out";
            $cmd .= " > $filename.gff";
            App::Egaz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
            if ( !$tempdir->child("$filename.gff")->is_file ) {
                Carp::croak "rmOutToGFF3.pl on [$infile] failed\n";
            }

            Path::Tiny::path("$filename.gff")->copy("$opt->{outdir}/$basename.rm.gff");
        }
    }

    chdir $cwd;
}

1;
