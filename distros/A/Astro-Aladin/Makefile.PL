use ExtUtils::MakeMaker;
use Config;

# Astro::Aladin uses threads and threads::shared to manage the
# lowevel Astro::Aladin::LowLevel module, which in turn drives
# the CDS Aladin Java Application. However ithreads support only
# got introduced in Perl 5.7.3, so we need to check we have a
# shiny new version of Perl and not the distressingly common 5.6.1

print "Checking Perl version...\n";
if( $] < 5.007003 ) {
   print "Perl 5.7.3 or above needed to build and use " .
         "the Astro::Aladin module.\n";
   exit;
} else {
   print "Looks good.\n";  
}

# Good start, but alot of Perl distributions aren't compiled
# to use ithreads, so we need to check that ithreads support
# has actually been compiled into the binary

print "Checking to see whether your Perl uses ithreads...\n";
unless( $Config{'useithreads'} eq "define") {
   print "It doesn't! You need to recompile Perl with ithreads support.\n";
   exit;
} else {
   print "Looks good.\n"; 
}

# Almost there, make or break, can we actually load the threading
# modules?

eval('use threads;');
eval('use threads::shared;');

print "Checking to see whether threads::shared is loaded...\n";
unless( $threads::shared::threads_shared ) {
   print "Nope! threads::shared doesn't seem to be loaded.\n";
   exit;
} else {
   print "Looks good.\n"; 
}

# You've got a Perl binary with ithreads support, this thing
# might actually work out.

WriteMakefile( 
      'NAME'           => 'Astro::Aladin',
      'VERSION'        => '2.0.2',
      'PREREQ_PM'      => { },
      'dist'           => { COMPRESS => "gzip -9f"},
      ($] >= 5.005 ?   
	( ABSTRACT => 'Perl class giving access to images and catalogues',
	  AUTHOR   => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
      );

