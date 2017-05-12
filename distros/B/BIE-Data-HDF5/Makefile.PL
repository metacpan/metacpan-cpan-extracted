use 5.014002;
use ExtUtils::MakeMaker;  
use Config;

die "The Perl seems not 64bit. Sorry that this module only supports 64bit Perl now\n"
  if ($Config{ivsize} != 8);

my $url = ($Config{osname} eq 'linux' ?
	   'http://www.hdfgroup.org/ftp/HDF5/current/bin/linux-x86_64/hdf5-1.8.10-linux-x86_64-shared.tar.gz' :
	   die "Only Linux is supported now\n"
	  );
$url =~ /[^\/]+gz$/;
my $file = $&;

&downloadLib;

my %defaultArgs = (
		NAME              => 'BIE::Data::HDF5',
		VERSION_FROM      => 'lib/BIE/Data/HDF5.pm', # finds $VERSION
		   PREREQ_PM         => {
					}, # e.g., Module::Name => 1.1
		   ($] >= 5.005 ? ## Add these new keywords supported since 5.005
		 (ABSTRACT_FROM  => 'lib/BIE/Data/HDF5.pm', # retrieve abstract from module
		  AUTHOR         => 'Xin Zheng <zhengxin@mail.nih.gov>') : ()),
		LIBS              => ['-L./blib/arch/auto/BIE/Data/HDF5 -lhdf5', '-L./blib/arch/auto/BIE/Data/HDF5 -lhdf5_hl'], # e.g., '-lm'
#		LDDLFLAGS	=> '-L./blib/arch/auto/BIE/Data/HDF5 ' . $Config{lddlflags}, #to override system hdf5 if it exists.
		DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
		INC               => '-I. -I./include', # e.g., '-I. -I/usr/include/other'
		# Un-comment this if you add C files to link with later:
		# OBJECT            => '$(O_FILES)', # link all the C files too
		INSTALL_BASE => '/usr/local/',
	       );

(my $args = join ',', @ARGV) =~ s/\=/\=\>\'/g;
$args =~ s/\,/\'\,/g;
my %extraArgs = eval $args;
my $v = WriteMakefile(%defaultArgs, %extraArgs);


use v5.10;
say "to use this module, please append following lines to \.bashrc in your home folder:";
say "export LD_LIBRARY_PATH=" . $v->{INSTALL_BASE} . '/lib/perl5/' . $Config{archname} . '/auto/BIE/Data/HDF5:' . '$LD_LIBRARY_PATH';
say "export PERL5LIB=" . $v->{INSTALL_BASE} . '/lib/perl5:' . '$PERL5LIB';

sub downloadLib {
  (my $folder = $file) =~ s/\.tar\.gz//;
  my $libdir = 'blib/arch/auto/BIE/Data/HDF5';
  if (!(-e $file) and (system 'wget ' . $url)!=0) {
    die "Cannot download library files from hdfgroup.org. Do you have wget? And please check your internet connection.\n"
  }
  
  system 'tar  -xzf ' . $file . ' --wildcards ' . $folder . '/lib/* ' . $folder .  '/include/*';
  system 'mkdir -p ' . $libdir;
  system 'mv -f ' . $folder . '/lib/* ' . $libdir;
  system 'cp -Rf ' . $folder . '/include ' . '.';
  system 'rm -rf ' . $folder;
}
