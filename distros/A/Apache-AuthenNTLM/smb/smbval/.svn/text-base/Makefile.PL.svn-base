use ExtUtils::MakeMaker;

WriteMakefile(
	NAME      => 'Authen::Smb::smbvalid',
	SKIP      => [qw(all pure_all static static_lib dynamic dynamic_lib test)],
	clean     => {'FILES' => 'smbvalid$(LIB_EXT)'},
);

sub MY::top_targets {
     '
pure_all all :: static

static ::       smbvalid$(LIB_EXT)

test:

INCLUDES = smblib.h smblib-priv.h

RFCNB = session.o rfcnb-util.o rfcnb-io.o

OBJS = smblib.o smblib-util.o file.o smb-errors.o exper.o smblib-api.o smbencrypt.o smbdes.o md4.o

VALIDATE = valid.o session.o rfcnb-util.o \
           rfcnb-io.o smblib-util.o smblib.o smbencrypt.o smbdes.o md4.o

smbvalid$(LIB_EXT): $(VALIDATE)
	$(AR) cr smbvalid$(LIB_EXT) $(VALIDATE)
	$(RANLIB) smbvalid$(LIB_EXT)
';
}
