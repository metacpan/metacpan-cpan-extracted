use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

mkdir test;

print <<END;
This module would like to run comparison tests against the system tar

Enter the string 'none' if your platform does not have a tar program.
END
my $tar = prompt("Enter name of tar program: ",'tar');

if ($tar ne 'none') {

    `$tar cvf test/arch1.tar t/0*.t`;

    if (!-e 'test/arch1.tar') {
        warn "Tar did not create an archive. Disabling tests";
        $tar = 'none';
    }
}

open TPROG,'>','t/tarprog' or die "Cannot write t/tarprog, $!";
print TPROG $tar,"\n";
close TPROG;

WriteMakefile(
    NAME         => 'Archive::Tar::Streamed',
    VERSION_FROM => 'lib/Archive/Tar/Streamed.pm', # finds $VERSION
    AUTHOR       => 'I. Williams (bitumen@xemaps.com)',
    ABSTRACT_FROM => 'lib/Archive/Tar/Streamed.pm',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Archive::Tar' => 1.00,
                    },
);
