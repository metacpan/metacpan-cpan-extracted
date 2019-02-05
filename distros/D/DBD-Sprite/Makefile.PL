use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'DBD::Sprite',
    'AUTHOR'        => 'Jim Turner',
    'VERSION_FROM' => 'lib/DBD/Sprite.pm', # finds $VERSION
    'ABSTRACT_FROM' => 'lib/DBD/Sprite.pm',
    'INC'	=> $DBI_INC_DIR,
    'dist'	=> {
        'SUFFIX' => '.gz',
        'COMPRESS' => 'gzip -9f'
    },
    'realclean'	=> {FILES => '*.xsi'},
    'CONFIGURE_REQUIRES' => {
        'DBI' => 1.03,
        'ExtUtils::MakeMaker' => 6.52,
    },
    'PREREQ_PM'     => {
        'DBI'       => 1.03,
    },
	'EXE_FILES' => ['makesdb.pl']
);

package MY;

sub postamble {
    eval {require DBI;};
    return ''  if ($@);
    eval {require DBI::DBD;};
    return $@ ? '' : DBI::DBD::dbd_postamble(@_);
}

sub libscan {
	my ($self, $path) = @_;
	($path =~ /\~$/) ? undef : $path;
}

