use ExtUtils::MakeMaker;
$Verbose = 1;
WriteMakefile(
    NAME   => 'Business::US::USPS::IMB::usps4cb',
    SKIP   => [qw(all static static_lib dynamic dynamic_lib)],
    clean  => {'FILES' => 'libusps4cb$(LIB_EXT)'},
);
sub MY::top_targets {
'
all::static
pure_all::static
static::libusps4cb$(LIB_EXT)
libusps4cb$(LIB_EXT):$(O_FILES)
	$(AR) cr libusps4cb$(LIB_EXT) $(O_FILES)
	$(RANLIB) libusps4cb$(LIB_EXT)
';
}
