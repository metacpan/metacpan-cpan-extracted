# -*-Perl-*- mode (for emacs)
use Test::More tests => 5;
use Data::Dumper;
use File::Spec;

use FindBin qw($Bin);

sub test_input_file {
    return File::Spec->catfile('t', 'data', @_);
}

diag( "Testing spipe from command line" );
my $conffile = test_input_file('string_manipulation.yml');

ok `$Bin/../bin/spipe 2>&1` =~ /ERROR/, 'die without config' ;
ok `$Bin/../bin/spipe -v` =~ /spipe, version /, '--version' ;
ok `$Bin/../bin/spipe -help` =~ /User Contributed Perl Documentation/, '--help' ;
ok `$Bin/../bin/spipe  -conf $conffile -debug  --verbose=-1` =~ /s1/, '--debug' ;
unlink 'config.yml', 'pipeline.log';

$conffile = test_input_file('input.yml');
`$Bin/../bin/spipe -conf $conffile --input=ABC --itype=unnamed --verbose=-1`;
is `cat s1_string.txt`, "ABC\n", 'command line input';
`cat s1_string.txt`;
unlink 'config.yml', 'pipeline.log', 's1_string.txt';
