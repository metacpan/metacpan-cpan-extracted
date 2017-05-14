use ExtUtils::MakeMaker;

eval {
    WriteMakefile(
      'NAME'	=> 'CORBA::MICO::ccc',
      'EXE_FILES' => [ 'ccc' ],
      'PREREQ_PM' => {
	 Gtk2 => 1.140, 
      },
      'PREREQ_FATAL' => 1,
  );
};
if( $@ ) {
    print "$@\nSkip 'ccc' building.\n";
    ExtUtils::MakeMaker::WriteEmptyMakefile();
}
