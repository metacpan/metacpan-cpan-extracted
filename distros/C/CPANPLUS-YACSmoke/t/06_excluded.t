### make sure we can find our conf.pl file
BEGIN {
    use FindBin;
    require "$FindBin::Bin/inc/conf.pl";
}

use strict;
use warnings;
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
exclude_dists=<<HERE
^Foo
HERE
exclude_auths=<<THERE
^MSCHWERN\$
THERE
EOF
close INIFILE;

my $self = CPANPLUS::YACSmoke->new($conf);
isa_ok($self,'CPANPLUS::YACSmoke');
ok( $ENV{$_}, "$_ is set" ) for @env_vars;
isa_ok( $self->{conf}, 'CPANPLUS::Configure' );
isa_ok( $self->{cpanplus}, 'CPANPLUS::Backend' );
$self->{conf}->set_conf( md5 => 0 );
my @excluded;
capture_merged { @excluded = $self->excluded( 'Foo::Bar' ); };
ok( ( grep { $_ eq 'Foo-Bar-0.01' } @excluded ), 'Foo-Bar-0.01 is excluded' );
capture_merged { @excluded = $self->excluded( 'ExtUtils::MakeMaker' ); };
ok( ( grep { $_ eq 'ExtUtils-MakeMaker-6.54' } @excluded ), );
