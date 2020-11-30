#!/usr/bin/perl
use 5.012;
use lib 'blib/lib', 'blib/arch';
use Benchmark qw/timethis timethese/;
use Data::Dumper qw/Dumper/;
use Path::Class;
use Config::MorePerl;

say "START";

my $cfg = Config::MorePerl->process('misc/inner.conf');
say Dumper($cfg);

exit;

my $initial_cfg = {
    a => 1,
    b => 2,
    c => [1,2,3],
    d => {a => 1, b => 2},
    root => Path::Class::Dir->new('/home/syber/poker/root'),
    home => Path::Class::Dir->new('/home/syber/poker'),
};
my $cfg;

$cfg = Config::MorePerl->process('misc/my.conf', $initial_cfg);
say Dumper($cfg);

#$cfg = Config::MorePerl->process('/home/syber/poker/local.conf', $initial_cfg);
#say Dumper($cfg);

timethese(-1, {
    medium => sub { Config::MorePerl->process('misc/my.conf', $initial_cfg); },
    #big    => sub { Config::MorePerl->process('/home/syber/poker/local.conf', $initial_cfg); },
}) unless $INC{'Devel/NYTProf.pm'};

#Config::MorePerl->process('/home/syber/poker/local.conf', $initial_cfg) for 1..1000;
