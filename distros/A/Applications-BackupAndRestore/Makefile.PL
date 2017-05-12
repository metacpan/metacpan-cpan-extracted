#package Makefile
use 5.006;
use ExtUtils::MakeMaker;

BEGIN {

   # See lib/ExtUtils/MakeMaker.pm for Details of how to influence
   # the Contents of the Makefile that is written.
   WriteMakefile(
      'NAME' => 'Applications::BackupAndRestore',

      #'VERSION'   => 0.009,    # finds $VERSION
      'VERSION_FROM' => 'lib/Applications/BackupAndRestore.pm',
      'PREREQ_PM'    => {
         Test::More => 0.62,

         base     => 2.07,
         strict   => 1.03,
         warnings => 1.05,
         enum     => 1.016,

         #Universal
         Exporter => 5.58,
         Carp     => 1.04,

         #App
         Gnome2::GConf => 1.043,    # libgnome2-gconf-perl

         Glib           => 1.161,
         Gtk2           => 1.161,
         Gtk2::GladeXML => 1.006,

         Unicode::MapUTF8     => 1.11,
         Unicode::UTF8simple  => 1.06,
         Number::Bytes::Human => 0.07,
         Tie::DataDumper      => 0.03,

         Cwd            => 3.12,
         File::Basename => 2.74,

         POSIX => 1.09,

         #
         #Gtk2::Ex::FileLocator::RecycleButton => 0,
         #
         Gnome2           => 1.040,
         Gnome2::VFS      => 1.080,
         CGI              => 3.15,
         Unicode::MapUTF8 => 1.11,

      },    # e.g., Module::Name => 1.1

      EXE_FILES => [ "bin/BackupAndRestore", "bin/BackupAndRestore.glade" ],
      ABSTRACT  => 'Backup and Restore your Files and Folders incrementally.',
      AUTHOR    => 'Holger Seelig <holger.seelig@yahoo.de>',

      #NO_META  => 1,
      #NORECURS => 0,
   );
}
__END__

#clean
cd '/home/holger/perl/cpan/X3D'
perl Makefile.PL | grep OK
sudo make clean | grep OK
sudo rm Makefile.old 2>&1 | grep OK
sudo rm MANIFEST 2>&1 | grep OK
sudo rm MANIFEST.bak 2>&1 | grep OK


#mk dist
perl Makefile.PL | grep OK
make manifest 2>&1 | grep OK
cat MANIFEST | cpanversion+ 0.0001 | grep OK
perl Makefile.PL | grep OK
make test | grep OK
make dist | grep OK
mv *.gz ../


#mk install
sudo cpan . | grep OK


#mk test
perl Makefile.PL | grep OK
make test

install Unicode::String
install Package::Alias
install Algorithm::Numerical::Shuffle
install Hash::NoRef
install Math::Quaternion
install Sub::Name
install Want
install enum
