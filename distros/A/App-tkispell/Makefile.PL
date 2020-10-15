use 5.006;
use ExtUtils::MakeMaker;
use English qw'-no_match_vars';

my $ispell_bin = '';

if( $OSNAME eq 'MSWin32' ) {

    # look for aspell first, as it the successor of ispell
    chomp( $ispell_bin = `where aspell` );
    
    # fallback: if no aspell is found, look for ispell
    if( !defined $ispell_bin or $ispell_bin eq '' ) {
        chomp( $ispell_bin = `where ispell` );
    }
    
}else{

    chomp( $ispell_bin = `which aspell` );
    
    # fallback: if no aspell is found, look for ispell
    if( !defined $ispell_bin or $ispell_bin eq '' ) {
        chomp( $ispell_bin = `which ispell` );
    }
    
}

# The first match is for Solaris which.  The second is for 
# Linux which. The 3rd one for Windows.
if( ($ispell_bin =~ /no ispell/) || (length($ispell_bin) == 0 || $ispell_bin !~ m/(?:i|a)spell.exe$/) ) {
    print "Could not find locate ispell or aspell.\n";
    print "Make sure that the program is installed in a directory\n";
    print "named in the PATH environment variable.\n";  
    exit(1);
}

print "We will use $ispell_bin for spelling\n";
WriteMakefile(
    AUTHOR => 'Robert Kiesling, rkies@cpan.org' ,
	NAME => 'App::tkispell',
	VERSION_FROM => 'lib/App/tkispell.pm',
	EXE_FILES => ['tkispell'],
    PREREQ_PM => {
        'Tk' => 800.004,
        'File::Copy' => 0,
        'English' => 0,
        # XXX: move to TEST_REQUIRES + xt folder in future
        'Test' => 0,
        'Test::More' => 0,
    },
);
