### make sure we can find our conf.pl file
BEGIN {
    use FindBin;
    require "$FindBin::Bin/inc/conf.pl";
}

use strict;
use warnings;
use File::Temp;
use File::Find;
use Test::More tests => 12;
use lib 't/inc';
use Capture::Tiny qw(capture_merged);
use_ok('CPANPLUS::YACSmoke');

my $dir = File::Temp::tempdir( CLEANUP => 1 );

delete $ENV{HARNESS_OPTIONS};
my @env_vars = qw(AUTOMATED_TESTING PERL_MM_USE_DEFAULT MAILDOMAIN NONINTERACTIVE_TESTING PERL_LOCAL_LIB_ROOT PERL_MB_OPT PERL_MM_OPT);
delete $ENV{$_} for @env_vars;

my $conf = gimme_conf();
my $ini  = File::Spec->catfile( $conf->get_conf('base'), 'cpansmoke.ini' );

open INIFILE, "> $ini" or die "$!\n";
print INIFILE <<EOF;
[CONFIG]
local::lib = 1
EOF
close INIFILE;

my $self = CPANPLUS::YACSmoke->new($conf);
isa_ok($self,'CPANPLUS::YACSmoke');
isa_ok( $self->{conf}, 'CPANPLUS::Configure' );
isa_ok( $self->{cpanplus}, 'CPANPLUS::Backend' );
is( $self->{local_lib}, 1, 'local::lib is defined' );
$self->{conf}->set_conf( md5 => 0 );
$self->_setup_local_lib();
ok( $ENV{$_}, "$_ is set" ) for @env_vars;
diag( "$_ $ENV{$_}\n" ) for @env_vars;
