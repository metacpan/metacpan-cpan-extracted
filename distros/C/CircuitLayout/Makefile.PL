## this file is for CPAN use only
use Cwd;
use File::Spec;

unless ( eval "use Module::Build::Compat 0.03; 1" ) {
    require ExtUtils::MakeMaker;

    print "This module requires Module::Build::Compat to install itself.\n";

    my $yn =
        ExtUtils::MakeMaker::prompt
            ( '  Install Module::Build::Compat from CPAN', 'y' );

    if ($yn =~ /^y(es)?/i) {
        # save this cause CPAN will chdir all over the place.
        my $cwd = cwd();
        my $makefile = File::Spec->rel2abs($0);

        require CPAN;
        CPAN->install('Module::Build::Compat');

        chdir $cwd
            or die "Cannot chdir to $cwd: $!";

        exec( $^X, $makefile, @ARGV )
    } else {
        warn "Cannot install this module " .
             "without Module::Build.  Exiting ...\n";
        exit 0;
    }
}

Module::Build::Compat->run_build_pl( args => \@ARGV );
Module::Build::Compat->write_makefile;

