use 5.014000;
use Devel::CheckLib;
use ExtUtils::MakeMaker;

check_lib_or_exit
  lib => 'opusfile';

WriteMakefile(
	NAME              => 'Audio::Opusfile',
	VERSION_FROM      => 'lib/Audio/Opusfile.pm',
	ABSTRACT_FROM     => 'lib/Audio/Opusfile.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	CONFIGURE_REQUIRES => {
		qw/Devel::CheckLib     0
		   ExtUtils::MakeMaker 0/,
	},
	PREREQ_PM         => {},
	LIBS              => ['-lopusfile'],
	INC               => '-I/usr/include/opus -I/usr/local/include/opus',
	META_ADD           => {
		dynamic_config => 1,
		resources      => {
			repository => 'https://git.ieval.ro/?p=audio-opusfile.git',
		},
	}
);

if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(OPUS_CHANNEL_COUNT_MAX OP_ABSOLUTE_GAIN OP_DEC_FORMAT_FLOAT
		 OP_DEC_FORMAT_SHORT OP_DEC_USE_DEFAULT OP_EBADHEADER
		 OP_EBADLINK OP_EBADPACKET OP_EBADTIMESTAMP OP_EFAULT OP_EIMPL
		 OP_EINVAL OP_ENOSEEK OP_ENOTAUDIO OP_ENOTFORMAT OP_EOF
		 OP_EREAD OP_EVERSION OP_FALSE OP_GET_SERVER_INFO_REQUEST
		 OP_HEADER_GAIN OP_HOLE OP_HTTP_PROXY_HOST_REQUEST
		 OP_HTTP_PROXY_PASS_REQUEST OP_HTTP_PROXY_PORT_REQUEST
		 OP_HTTP_PROXY_USER_REQUEST OP_PIC_FORMAT_GIF
		 OP_PIC_FORMAT_JPEG OP_PIC_FORMAT_PNG OP_PIC_FORMAT_UNKNOWN
		 OP_PIC_FORMAT_URL OP_SSL_SKIP_CERTIFICATE_CHECK_REQUEST
		 OP_TRACK_GAIN));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Audio::Opusfile',
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
