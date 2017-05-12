

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# Try to find gpg
my $GPG_PATH;

if($ENV{GPG} && -e $ENV{GPG}) {
    $GPG_PATH = $ENV{GPG};
}
else {
    $GPG_PATH = `which gpg`;
    chomp $GPG_PATH;
}

# Exit if no GPG found
unless(-e $GPG_PATH) {
    print "Could not find gpg executable in your path or in \$ENV{GPG}.\n";
    print "Set GPG=/path/to/gpg or add the directory to your PATH and try again.\n";
    exit 0;
}

WriteMakefile(
    NAME         => 'Crypt::SimpleGPG',
    VERSION_FROM => 'lib/Crypt/SimpleGPG.pm', # finds \$VERSION
    AUTHOR       => 'Corey Cossentino ()',
    ABSTRACT     => 'easy encryption and decryption using GPG',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'IPC::Run' => 0.84,
                     'File::Temp' => 0.22,
                    },
);
