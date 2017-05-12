# -*-Perl-*- mode (for emacs)
use Test::More tests => 12;
use Data::Dumper;
use File::Spec;

BEGIN {
      use_ok( 'App::Pipeline::Simple' );
}

sub test_input_file {
    return File::Spec->catfile('t', 'data', @_);
}

diag( "Testing App::Pipeline::Simple methods in memory" );

# debug ignores the missing config file
my $p = App::Pipeline::Simple->new(debug => 1, verbose => -1);
ok ref($p) eq 'App::Pipeline::Simple', 'new()';

my $s2 = App::Pipeline::Simple->new(id=> 'S2', debug => 1, verbose => -1);
ok ref($s2) eq 'App::Pipeline::Simple', 'new()';

# method testing
ok $s2->id() eq 'S2', 'id()';
ok $s2->name('test'), 'name()';
ok $s2->name() eq 'test', 'name()';
ok $s2->path('/opt/scripts'), 'path()';
ok $s2->path() eq '/opt/scripts', 'path()';
ok $s2->description('test'), 'description()';
ok $s2->next_id('test'), 'next_id()';
ok $s2->dir('data'), 'dir()';

my @methods = qw(id name description next_id config
		 run input itype
	       );
can_ok 'App::Pipeline::Simple', @methods;

