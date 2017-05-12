use inc::Module::Install 0.87;
use Module::Install::ReadmeFromPod;

name 'Catalyst-Log-Log4perl';
all_from 'lib/Catalyst/Log/Log4perl.pm';
readme_from;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/historical/Catalyst-Log-Log4perl';

requires( 'Catalyst'         => '5.60' );
requires( 'Log::Log4perl'    => '1.04');
requires( 'Params::Validate' => 0 );
requires( 'Data::Dump' => 0 );
requires( 'MRO::Compat' => 0 );

test_requires 'Test::More';

WriteAll;

