use inc::Module::Install;

all_from       'lib/CPAN/Metrics.pm';
requires       'File::HomeDir'       => '0.69';
requires       'Perl::Metrics'       => '0.08';
requires       'CPAN::Mini::Extract' => '1.19';
install_script 'cpanmetrics';

WriteAll;
