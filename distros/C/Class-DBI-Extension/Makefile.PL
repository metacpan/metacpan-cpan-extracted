use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Class::DBI::Extension',
    'VERSION_FROM' => 'lib/Class/DBI/Extension.pm', # finds $VERSION
    'PREREQ_PM' => 'Class::DBI',
    'dist' => {
	PREOP => build_docs(),
    },
);


sub build_docs {
    return <<EOF
pod2text lib/Class/DBI/Extension.pm > README
EOF
    ;
}
    
