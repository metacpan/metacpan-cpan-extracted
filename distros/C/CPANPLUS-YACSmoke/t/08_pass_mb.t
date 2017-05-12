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
use Test::More tests => 12;
use lib 't/inc';
use Capture::Tiny qw(capture_merged);
use_ok('CPANPLUS::YACSmoke');

my $dir = File::Temp::tempdir( CLEANUP => 1 );

delete $ENV{HARNESS_OPTIONS};
my @env_vars = qw(AUTOMATED_TESTING PERL_MM_USE_DEFAULT MAILDOMAIN NONINTERACTIVE_TESTING);
delete $ENV{$_} for @env_vars;

my $self = CPANPLUS::YACSmoke->new( gimme_conf() );
isa_ok($self,'CPANPLUS::YACSmoke');
ok( $ENV{$_}, "$_ is set" ) for @env_vars;
isa_ok( $self->{conf}, 'CPANPLUS::Configure' );
isa_ok( $self->{cpanplus}, 'CPANPLUS::Backend' );
$self->{conf}->set_conf( cpantest_reporter_args => { transport => 'File', transport_args => [ $dir ], } );
$self->{conf}->set_conf( md5 => 0 );
capture_merged { $self->test('E/EU/EUNOXS/Fabble-Bar-0.01.tar.gz'); };
my @reports;
find( sub {
    push @reports, $_ if -f;
}, $dir );
is( scalar @reports, 1, 'found a report in the directory' );
my $report;
{
  local $/ = undef;
  open my $file, '<', File::Spec->catfile( $dir, $reports[0] ) or die "$!\n";
  $report = <$file>;
}

ok( $report !~ /\[MSG\] \[[\w: ]+\] Extracted '\S*?'\n/s, 'No extraction messages in the report' );
ok( $report =~ m!All tests successful!, 'Report contains the result of the tests' );

my $grade;
capture_merged { $grade = $self->mark('Fabble-Bar-0.01'); };
is($grade,'pass','Grade was an PASS');
