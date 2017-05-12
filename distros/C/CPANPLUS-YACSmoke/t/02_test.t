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
use Test::More tests => 14;
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
$self->{conf}->set_conf( 'dist_type' => 'CPANPLUS::Dist::YACSmoke' );
my $merged_test = capture_merged { $self->test('E/EU/EUNOXS/Foo-Bar-0.01.tar.gz'); };
#diag($merged_test);
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
#diag($report);
ok( $report !~ /\[MSG\] \[[\w: ]+\] Extracted '\S*?'\n/s, 'No extraction messages in the report' );
TODO: {
  local $TODO = 'Mysteriously stopped working on anything less than 5.10.1';

  ok( $report =~ /\[MSG\] \[[\w: ]+\] Extracted '.*?' to '.*?'\n/s, 'But there is the final extraction message' );
  ok( $report =~ /\[MSG\] \[[\w: ]+\] CPANPLUS is prefering Build.PL\n/s, 'CPANPLUS is prefering Build.PL' );
  ok( $report =~ /\[MSG\] \[[\w: ]+\] Loading YACSmoke database ".*?"\n/s, 'Loading YACSmoke database' );
}
my $grade;
my $merged_grade = capture_merged { $grade = $self->mark('Foo-Bar-0.01'); };
is($grade,'fail','Grade was a FAIL');
