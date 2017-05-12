### make sure we can find our conf.pl file
BEGIN { 
    use FindBin; 
    require "$FindBin::Bin/inc/conf.pl";
}

use strict;
use warnings;
use Test::More tests => 8;
use_ok('CPANPLUS::YACSmoke');

my @env_vars = qw(AUTOMATED_TESTING PERL_MM_USE_DEFAULT MAILDOMAIN NONINTERACTIVE_TESTING);
delete $ENV{$_} for @env_vars;

my $self = CPANPLUS::YACSmoke->new();
isa_ok($self,'CPANPLUS::YACSmoke');
ok( $ENV{$_}, "$_ is set" ) for @env_vars;
isa_ok( $self->{conf}, 'CPANPLUS::Configure' );
isa_ok( $self->{cpanplus}, 'CPANPLUS::Backend' );
