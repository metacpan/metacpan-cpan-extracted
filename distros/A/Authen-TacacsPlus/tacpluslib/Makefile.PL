use ExtUtils::MakeMaker;                                         
$Verbose = 1;                                                    
use Config;

$osname=$Config{osname};
%defines=(
        'linux'=>'-DLINUX',
        'freebsd'=>'-DFREEBSD',
        'netbsd'=>'-DNETBSD',
        'solaris'=>'-DSOLARIS',
        'sunos'=>'-DSOLARIS',
        'bsdi'=>'-DBSDI',
        'aix'=>'-DAIX',
        'hpux'=>'-DHPUX',
);


WriteMakefile(                                                   
    NAME      => 'Authen::TacacsPlus::tacplus',                               
    DEFINE    => $defines{$osname},
    SKIP      => [qw(static dynamic)],
    clean     => {'FILES' => 'libtacplus$(LIB_EXT)'},     
    CCFLAGS   => "$ENV{'CFLAGS'} $ENV{'CPPFLAGS'}",
);                                                               
                                                                 
sub MY::top_targets {     

'
all:	static                                   
                                                 
static:	libtacplus$(LIB_EXT)              
                                                 
libtacplus$(LIB_EXT):	$(O_FILES)                  
	$(AR) cr libtacplus$(LIB_EXT) $(O_FILES)  
	$(RANLIB) libtacplus$(LIB_EXT)  

pure_all : 
	$(NOECHO) $(NOOP)

                                                 
 ';                                              
 }                                               

