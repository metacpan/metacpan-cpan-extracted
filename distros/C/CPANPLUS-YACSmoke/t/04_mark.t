### make sure we can find our conf.pl file
BEGIN { 
    use FindBin; 
    require "$FindBin::Bin/inc/conf.pl";
}

use strict;
use warnings;
use File::Temp;
use File::Find;
use Test::More tests => 17;
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
$self->{conf}->set_conf( md5 => 0 );
my $mark;
capture_merged { $mark = $self->mark('Foo::Bar'); };
ok( !defined $mark, 'No mark yet' );
foreach my $grade (qw(PASS FAIL NA UNKNOWN)) {
  my ($set,$got);
  capture_merged { $set = $self->mark('Foo::Bar',$grade); };
  is($set,lc $grade,"Setting Foo::Bar to '$grade'");
  capture_merged { $got = $self->mark('Foo::Bar'); };
  is($got,lc $grade,"Foo::Bar is '$grade'");
}
