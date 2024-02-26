use strict;
use warnings;

use Log::Handler;
use Chess::ELO::FIDE;

my $federation = shift || '';

my $log = Log::Handler->new();
$log->add( screen => {log_to=> 'STDOUT', message_layout=> "%T [%L] %m (%C)", maxlevel=> "debug"} );

my $ratings = Chess::ELO::FIDE->new(
    federation=> $federation,
    sqlite    => 'elo.sqlite',
    $log      => $log
);

my $s_ini = time();
my $count = $ratings->load;
my $s_end = time();
$log->info("Loaded $count players in " . ($s_end - $s_ini) . " seconds");