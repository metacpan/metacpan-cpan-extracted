use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# Check endian and add -DSEED_LITTLE_ENDIAN or -DSEED_BIG_ENDIAN to 'DEFINE' option

my $endian = join(" ", map { sprintf "%02x", $_ }
		unpack("C*",pack("L",0x12345678))) eq '12 34 56 78'
		? '-DSEED_BIG_ENDIAN' : '-DSEED_LITTLE_ENDIAN';

WriteMakefile(
    'NAME'		=> 'Crypt::SEED',
    'VERSION_FROM'	=> 'SEED.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'SEED.pm', # retrieve abstract from module
       AUTHOR     => 'A. U. Thor <a.u.thor@a.galaxy.far.far.away>') : ()),
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> "$endian", # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    'INC'		=> '', # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    'OBJECT'		=> '$(BASEEXT)$(OBJ_EXT) SEED_KISA$(OBJ_EXT)', # link all the C files too
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);

__END__
