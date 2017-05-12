# -*-Perl-*- mode (for emacs)
use Test::More tests => 8;
use Data::Dumper;
use File::Spec;

BEGIN {
      use_ok( 'App::Pipeline::Simple' );
}

sub test_input_file {
    return File::Spec->catfile('t', 'data', @_);
}

diag( "Testing App::Pipeline::Simple run from file" );


# reading in a configuration
my $dir = "/tmp/pl$$";

my $pl = App::Pipeline::Simple->new
   (config=>test_input_file('string_manipulation.yml'),
    dir=>$dir, verbose=> -1);

ok $pl->dir() eq $dir, 'dir()';
my $string = $pl->stringify;

ok $string =~ /# ->/, 'stringify()';
ok $pl->each_step, 'each_step';

ok $pl->run, 'run()';

my $dot = $pl->graphviz;
ok $dot =~ /^digraph /, 'graphviz()';
ok $pl->start('s3'), 'start()';
ok $pl->stop('s4'), 'stop()';

END {
    `rm -rf $dir` if $pl->verbose <0;
}
