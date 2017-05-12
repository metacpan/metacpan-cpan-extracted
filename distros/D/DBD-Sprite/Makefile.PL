use 5.006;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'DBD::Sprite',
    'AUTHOR'        => 'Jim Turner',
    'VERSION_FROM' => 'lib/DBD/Sprite.pm', # finds $VERSION
    'ABSTRACT_FROM' => 'lib/DBD/Sprite.pm',
    'INC'	=> $DBI_INC_DIR,
	'EXE_FILES' => ['makesdb.pl'],
    'PREREQ_PM'     => {
        'DBI'           => 0,
    },
    'dist'	=> { 'SUFFIX' => '.gz',
		     'COMPRESS' => 'gzip -9f' },
    #'realclean'	=> '*.xsi'
    'realclean'	=> {FILES => '*.xsi'}
);

package MY;

sub libscan {
	my ($self, $path) = @_;
	($path =~ /\~$/) ? undef : $path;
}

