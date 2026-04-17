#!/usr/bin/env perl

use utf8;
use v5.40;

use lib 'lib';

use Fcntl qw'S_IXUSR S_IXGRP S_IXOTH S_IRUSR S_IRGRP S_IROTH';
use Cwd 'abs_path';
use File::chdir;
use Path::Tiny;
use List::Util 'none';
use Getopt::Long qw(GetOptionsFromArray :config no_ignore_case auto_abbrev);

use IPC::Nosh;
use IPC::Nosh::Common;

our $modroot  = path(abs_path);
our @input    = ( path("$modroot/script")->children );
our $outdir   = path('./bin');
our $outfn    = '%s';
our $locallib = path("$modroot/local");
our $verbose  = 1;
our $debug    = $verbose;

our $patharg = sub ( $arg, %opt ) {
    $arg = path($arg)->assert(
        sub {
            $opt{assert} && $opt{assert} isa CODE ? $opt{assert}->(@_) : 1;
        }
    ) unless $arg isa Path::Tiny;

    if ( my $dest = $opt{dest} ) {

        if ( my $type = ref $dest ) {
            if ( $type eq 'ARRAY' ) {
                push @$dest, $arg
                  if none { $arg->absolute eq $_->absolute } @input;
            }
            elsif ( $type eq 'SCALAR' ) {
                $$dest = $arg;
            }
        }
        else {
            fatal '$dest must be a SCALAR, ARRAY, or CODE reference!';
            dmsg( $arg, $dest );
        }
    }
};

our %clidest = (
    modroot  => \$modroot,
    input    => [],
    outdir   => \$outdir,
    outfn    => \$outfn,
    locallib => \$locallib,
    verbose  => \$verbose,
    debug    => \$debug
);

GetOptions(
    \%clidest,
    'input|file|infile|infname|script=s{,}',
    => sub {
        $patharg->( shift, dest => \@input );
    },
    'outdir|fatpack-out=s',
    'outfn|outfname|out-filename|fnfmt|fmtfn|fmt-filename|fmt-outputfn=s',
    'modroot|module-root|module-dir=s',
    'locallib=s{,}',
    'verbose+',
    'debug',
    '<>' => sub ($in) { $patharg->( $in, dest => \@input ) }
);

my $cliopt_deref = {
    map {
        my $ref = ref $clidest{$_};
        ( $_ => ( $ref eq 'SCALAR' ? $clidest{$_}->$* : $clidest{$_} ) )
    } ( keys %clidest )
};

sub fatpack {
    $CWD = $modroot;
    run( [qw(carton install)] );

    $ENV{PERL5LIB} = "$locallib:$modroot/lib";

    $outdir->mkdir unless -d $outdir;
    dmsg(@input);
    foreach my $in ( map { $_->is_dir ? ( $_->children ) : $_ } @input ) {

        #fatpack($in->children) if $in->is_dir;
        my $fatline = [];
        my $fatstr  = "";
        my @cmd     = ( qw(fatpack pack), $in );

        binmode STDERR, ":encoding(UTF-8)";
        info( "Running " . join " ", @cmd );

        my $run = run( \@cmd, out => $fatline, autochomp => 1 );

        #dmsg($run);

        $fatstr = join "\n", $run->out->lines_utf8;

        my $fatout = $in->basename;
        $fatout = path("$outdir/$fatout")->spew_utf8($fatstr);

        # S_IXOTH  (00001)  execute/search by others
        $fatout->chmod(
            S_IRUSR | S_IRGRP | S_IROTH | S_IXUSR | S_IXGRP | S_IXOTH );

        success("Written to: $fatout");
    }
}

fatpack()
