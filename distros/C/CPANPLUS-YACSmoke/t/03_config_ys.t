### make sure we can find our conf.pl file
BEGIN { 
    use FindBin; 
    require "$FindBin::Bin/inc/conf.pl";
}

use strict;
use warnings;
use Test::More tests => 7;
use File::Spec;
use_ok('CPANPLUS::YACSmoke');

delete $ENV{HARNESS_OPTIONS};
my @env_vars = qw(AUTOMATED_TESTING PERL_MM_USE_DEFAULT MAILDOMAIN NONINTERACTIVE_TESTING);
delete $ENV{$_} for @env_vars;

$ENV{PERL5_YACSMOKE_BASE} = File::Spec->rel2abs('.');

my $self = CPANPLUS::YACSmoke->new();
isa_ok($self,'CPANPLUS::YACSmoke');
ok( $ENV{$_}, "$_ is set" ) for @env_vars;
is($self->{conf}->get_conf('base'),File::Spec->catdir($ENV{PERL5_YACSMOKE_BASE},'.cpanplus'),'PERL5_YACSMOKE_BASE');
