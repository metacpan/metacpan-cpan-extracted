use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::NNTPGateway',
    'VERSION_FROM'	=> 'NNTPGateway.pm', # finds $VERSION
    'PREREQ_PM'		=> 
	{
	'Apache'            => 1.20, 
	'Apache::Constants' => 1.0, 
	'Apache::URI'       => 1.0, 
	'Apache::Request'   => 0.30, 
	'Apache::Log'       => 1.0, 
	'CGI::Cookie'       => 1.10, 
	'Net::NNTP'         => 2.0, 
	'Net::Config'       => 1.10, 
	'Net::Cmd'          => 2.0, 
	'Net::Domain'       => 2.0, 
	'Mail::Address'     => 1.10, 
	'File::Spec'        => 0.80, 
	}, # e.g., Module::Name => 1.1
);
