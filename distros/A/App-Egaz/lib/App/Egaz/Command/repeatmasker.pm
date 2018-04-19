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
        [ "outdir|o=s",   "Output directory",           { default => "." }, ],
        [ "species=s",    "the species or clade of the input sequence", ],
        [ "opt=s",        "other options should be passed to RepeatMasker", ],
        [ "tmp=s",        "user defined tempdir", ],
        [ "parallel|p=i", "number of threads",          { default => 2 }, ],
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
        my $basename = Path::Tiny::path($infile)->basename();

        my $cmd = "RepeatMasker";
        $cmd .= " $infile";
        $cmd .= " -dir .";
        $cmd .= " -species $opt->{species}" if $opt->{species};
        $cmd .= " $opt->{opt}" if $opt->{opt};
        $cmd .= " -xsmall --parallel $opt->{parallel}";
        App::Egaz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
        if ( !$tempdir->child("$basename.masked")->is_file ) {
            Carp::croak "RepeatMasker on [$infile] failed\n";
        }

        Path::Tiny::path("$basename.masked")->copy( "$opt->{outdir}/$basename" );
        Path::Tiny::path("$basename.out")->copy( "$opt->{outdir}" );
    }

    chdir $cwd;
}

1;
