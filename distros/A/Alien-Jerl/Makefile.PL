use ExtUtils::MakeMaker;

# if java is not available to the commandline, there will be problems, let them know
my $javaIsMissingMessage = 'Java is mising ... Alien::Jerl requires Java to be available to the commandline'; 

# Pattern for non *nix errors that will find its way to standard out
my $nonNixError = 'error';

# check for Java
print "[Alien::Jerl] ... do you have java available to the commandline ? ...\n";
my $commandlineJava = `java -version 2>&1` || '';
if (!$commandlineJava) {
    $commandlineJava  = `java -version`;   
}

if (!$commandlineJava || 
     $commandlineJava =~ m/$nonNixError/ig)  {
    print "ERROR [Alien::Jerl] $commandlineJava \n";
    print "$javaIsMissingMessage\n\n";
    exit(1);
}
print "[Alien::Jerl] $commandlineJava \n";
print "[Alien::Jerl] ... yes 'java -version' is available .\n";

# Initial checks for Java have passed, generate the makefile
WriteMakefile (
               AUTHOR        => 'michaelt shomsky <17michaelt@gmail.com>',
               ABSTRACT      => 'mJERL is a mips compiled micro perl that runs in a JVM',
               NAME          => 'Alien::Jerl',
               VERSION_FROM  => 'lib/Alien/Jerl.pm',
               PREREQ_PM     => {
                                 'Test::More' => '0.47',
                                },
              );
