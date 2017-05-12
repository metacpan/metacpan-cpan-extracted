### make sure we can find our conf.pl file
BEGIN {
    use FindBin;
    require "$FindBin::Bin/inc/conf.pl";
}

use strict;
use warnings;
use File::Spec;
use File::Temp;
use File::Find;
use Test::More tests => 10;
use lib 't/inc';
use Capture::Tiny qw(capture_merged);
use_ok('CPANPLUS::YACSmoke');

my $dir = File::Temp::tempdir( CLEANUP => 1 );

delete $ENV{HARNESS_OPTIONS};
my @env_vars = qw(AUTOMATED_TESTING PERL_MM_USE_DEFAULT MAILDOMAIN NONINTERACTIVE_TESTING);
delete $ENV{$_} for @env_vars;

my $conf = gimme_conf();
my $ini  = File::Spec->catfile( $conf->get_conf('base'), 'cpansmoke.ini' );

open INIFILE, "> $ini" or die "$!\n";
print INIFILE <<EOF;
[CONFIG]
exclude_auths=<<THERE
^ASSHAT\$
THERE
EOF
close INIFILE;

my $self = CPANPLUS::YACSmoke->new( $conf );
isa_ok($self,'CPANPLUS::YACSmoke');
ok( $ENV{$_}, "$_ is set" ) for @env_vars;
isa_ok( $self->{conf}, 'CPANPLUS::Configure' );
isa_ok( $self->{cpanplus}, 'CPANPLUS::Backend' );
$self->{conf}->set_conf( cpantest_reporter_args => { transport => 'File', transport_args => [ $dir ], } );
$self->{conf}->set_conf( md5 => 0 );
capture_merged { $self->test('E/EU/EUNOXS/Gobble-Bar-0.01.tar.gz'); };
my @reports;
find( sub {
    push @reports, $_ if -f;
}, $dir );
is( scalar @reports, 0, 'found a report in the directory' );
my $grade;
capture_merged { $grade = $self->mark('Gobble-Bar-0.01'); };
is($grade,undef,'No grade');
