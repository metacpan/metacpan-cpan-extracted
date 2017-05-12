use 5.008;
use ExtUtils::MakeMaker;

use Config;

if (unpack("h*", pack("s", 1)) =~ /01/) {
    $BYTEORDER = "MPC_BIG_ENDIAN_MACHINE";
} elsif (unpack("h*", pack("s", 1)) =~ /^1/) {
    $BYTEORDER = "MPC_LITTLE_ENDIAN_MACHINE";
}

sub have_libmpcdec {
    my $CC = $Config{cc};
    my %args = map { split /\s*=\s*/ } @ARGV;
    my $LIBS = $args{ LIBS } || '-lmpcdec';
    my $INC = $args{ INC };
    return 1 if system("$CC $LIBS check.c -o check$Config{obj_ext}") == 0;
    return 0;
}

if (! have_libmpcdec()) {
    die <<EOD;
*******************************************
Couldn't find libmpcdec which is required 
for this module.

To obtain it, get it from
    http://www.musepack.net/
*******************************************
EOD
}

WriteMakefile(
    NAME            => 'Audio::MPC',
    VERSION_FROM    => 'lib/Audio/MPC.pm',
    PREREQ_PM       => {
	'Test::More'	    => 0,
	'Test::LongString'  => 0,
    }, 
    ABSTRACT	    => 'Decode Musepack audio streams',
    AUTHOR	    => 'Tassilo von Parseval <tassilo.von.parseval@rwth-aachen.de>',
    LIBS            => ['-lmusepack'],
    DEFINE          => "-D$BYTEORDER",
    INC             => '-I.',
    XSOPT	    => '-C++',
    CC		    => 'g++',
    LD		    => '$(CC)',
    clean	    => { FILES => "check$Config{obj_ext}" },
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  my @names = qw(MPC_LITTLE_ENDIAN MPC_BIG_ENDIAN);
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Audio::MPC',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}

sub MY::postamble {
    return <<EORULE;
readme:
	pod2readme lib/Audio/MPC.pm README readme
	pod2readme lib/Audio/MPC.pm Changes changes
EORULE
}
