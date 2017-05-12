use strict;
use warnings;
use Test::More;
use File::Temp qw/ tempfile tempdir /;
use File::Spec;
use File::Basename 'dirname';
use lib ( File::Spec->catdir(dirname(__FILE__), qw/TestApp lib/) );
use TestApp;

subtest 'default' => sub {
    my $t = TestApp->new;
    is $t->foo, 'development';
};

subtest 'staging' => sub {
    my $t = TestApp->new( env => 'staging');
    is $t->foo, 'staging';
};

subtest 'product' => sub {
    $ENV{PLACK_ENV} = 'product';
    my $t = TestApp->new;
    is $t->foo, 'product';
};

subtest 'updir' => sub {
    my $t = TestApp->new( env => 'test', dir => File::Spec->catdir( '..', '..' ) );
    is $t->foo, 'test';
};

subtest 'absdir' => sub {
    my $tmpdir  = tempdir( CLEANUP => 1 );
    open my $fh, '>', File::Spec->catfile( $tmpdir, 'absdir.pl' );
    print $fh '+{ env => "absdir" };'."\n";
    close $fh;
    my $t = TestApp->new( env => 'absdir', dir => $tmpdir );
    is $t->foo, 'absdir';
};

done_testing;
