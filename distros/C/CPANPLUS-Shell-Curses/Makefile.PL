use strict;
### write the Makefile ###
use ExtUtils::MakeMaker;

my $name     = 'CPANPLUS::Shell::Curses';
my $mainfile = 'lib/CPANPLUS/Shell/Curses.pm';

WriteMakefile(
	      NAME		=> $name,
	      VERSION_FROM	=> $mainfile,
	      PREREQ_PM => {
		  'Curses::UI'          => 0.93,
		  'Module::ScanDeps'    => 0,
		  'File::Spec'          => 0,
		  'File::chdir'         => 0,
		  'Pod::Text'           => 0,
		  'Cwd'                 => 0,
		  'CPANPLUS'            => 0.045,
		  'Test::Pod'           => 0,
	      },

	      ABSTRACT_FROM => $mainfile,
	      AUTHOR => 'Marcus Thiesen (marcus@cpan.thiesenweb.de)',
	      
	      MAN3PODS => { $mainfile => $name }

	      );
