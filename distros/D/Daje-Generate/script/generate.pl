#!/usr/bin/perl

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use Moo;
use MooX::Options;
use Cwd;
use Config::Tiny;
use Log::Log4perl qw(:easy);
use Mojo::Pg;
use feature 'say';
use feature 'signatures';
use Daje::GenerateSQL;
use namespace::clean -except => [qw/_options_data _options_config/];


option 'configpath' => (
    is 			=> 'ro',
    required 	=> 1,
    reader 		=> 'get_configpath',
    format 		=> 's',
    doc 		=> 'Configuration file',
    default 	=> '/home/jan/Project/SyntaxSorcery/Tools/Database/conf/'
);

option 'sourcepath' => (
    is 			=> 'ro',
    required 	=> 1,
    reader 		=> 'get_sourcepath',
    format 		=> 's',
    doc 		=> 'Source files',
    default 	=> '/home/jan/Project/SyntaxSorcery/Tools/Database/conf/'
);

sub generate($self) {
    Log::Log4perl->easy_init($ERROR);
    my $log = Log::Log4perl->get_logger();

    try {
        Log::Log4perl::init($self->get_configpath() . 'generate.conf');
    } catch ($e) {
        $log->error('Tables ' . $e);
        say $e;
    };

    my $config;
    try  {
        $config = get_config($self->get_configpath() . 'generate.ini');
    } catch($e) {
        $log->error('generate.ini ' . $e);
        say $e;
    };

    my $pg;
    try {
        $pg= Mojo::Pg->new()->dsn(
            $config->{DATABASE}->{pg}
        );
    } catch ($e) {
        $log->error('open pg ' . $e);
        say $e;
    };
    try {
        GenerateSQL->new(
            pg => $pg,
            config => $config,
            log => $log)->generate();
    } catch ($e) {
        $log->error('generate ' . $e);
        say $e;
    };

}

sub get_config ($configfile){

    my $log = Log::Log4perl->get_logger();
    $log->logdie("config file name is empty")
        unless ($configfile);

    my $config = Config::Tiny->read($configfile);
    $log->logdie("config file could not be read")
        unless ($config);

    return $config;
}

main->new_with_options->generate();