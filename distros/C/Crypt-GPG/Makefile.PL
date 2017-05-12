use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile (
	       'NAME'	      =>   'Crypt::GPG',
	       'AUTHOR'        =>  'Ashish Gulhati <crypt-gpg@neomailbox.com>',
	       'ABSTRACT_FROM' =>  'GPG.pm',
	       'VERSION_FROM'  =>  'GPG.pm',
	       'PREREQ_PM'     =>  {
				    'Carp'         =>  0,
				    'Fcntl'        =>  0,
				    'IPC::Run'     =>  0,
				    'File::Path'   =>  0,
				    'File::Temp'   =>  0,
				    'Date::Parse'  =>  0,
				   },
	      );

