use inc::Module::Install 0.77;

all_from      'lib/Apache2/PPI/HTML.pm';
requires      'CGI'                 => '3.10';
requires      'Apache2::RequestRec' => 0;
requires      'Apache2::RequestIO'  => 0;
requires      'PPI'                 => '1.000';
requires      'PPI::HTML'           => '0.05';
test_requires 'Test::More'          => '0.47';

WriteAll;
