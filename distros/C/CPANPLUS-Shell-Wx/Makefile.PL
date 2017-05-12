use 5.005;
use inc::Module::Install;

# Define metadata
name           'CPANPLUS-Shell-Wx';
#author           'Skaman Sam Tyler <skamansam@gmail.com>';
#license        'perl';
#perl_version   '5.006';
all_from       'lib/CPANPLUS/Shell/Wx.pm';

#list deps that aren't in perl 5.005 (new since 1998)
#the commented out modules are in perl 5.005
requires       'Class::Struct'    			=> '0.0';
requires       'CPANPLUS'	    			=> '0.078';
#requires       'Cwd'    	 				=> '0.0';
requires       'File::HomeDir'    			=> '0.0';
#requires       'File::Path'  				=> '0.80';
#requires       'File::Spec'    			=> '0.0';
requires       'IPC::Cmd'    				=> '0.0';
requires       'Locale::Maketext::Simple'	=> '0.0';
requires       'LWP::Simple'			    => '0.0';
requires       'Module::Load'   			=> '0.0';
requires       'Module::Load::Conditional'	=> '0.0';
requires       'Params::Check'  			=> '0.0';
requires       'URI::Escape'			    => '0.0';
requires       'Wx'          				=> '0.74';
requires       'YAML'					    => '0.0';

#these are the modules used by CPANPLUS. added here 
# because there are no deps listed for CPANPLUS on CPAN
#the commented out modules are in perl 5.005
requires       'Archive::Extract'		    => '0.0';
#requires       'Carp'					    => '0.0';
requires       'Config'					    => '0.0';
#requires       'File::Basename'			    => '0.0';
#requires       'File::Copy'				    => '0.0';
requires       'File::Fetch'			    => '0.0';
#requires       'File::Find'				    => '0.0';
#requires       'File::Spec::Unix'		    => '0.0';
requires       'File::Temp'				    => '0.0';
#requires       'FileHandle'				    => '0.0';
requires       'Locale::Maketext::Simple'   => '0.0';
requires       'Log::Message'			    => '0.0';
requires       'Module::Loaded'			    => '0.0';
requires       'Object::Accessor'		    => '0.0';
requires       'Package::Constants'		    => '0.0';
#requires       'Term::ReadLine'				=> '0.0';
requires       'Term::UI'				    => '0.0';


#test_requires  'Test::More'  => '0.42';
#recommends     'Text::CSV_XS'=> '0.50';
no_index       'directory'   => 'blib';
install_script 'bin/wxcpan';
install_script 'bin/wxpodreader';


WriteAll;
