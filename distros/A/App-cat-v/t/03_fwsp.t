use v5.14;
use warnings;
use Test::More 0.98;
use utf8;
use open IO => ':utf8', ':std';
use Data::Dumper;

use lib './t';
use Command;

use Text::ParseWords qw(shellwords);
use Getopt::Long 'Configure';
Configure qw(bundling no_getopt_compat no_ignore_case);
GetOptions(\my %opt,
           'data-section',	# produce data section
           'example',		# show command execution example
           'show',		# show test
           'number|n=i',	# select test number
) or die;

use File::Spec;
$ENV{HOME} = File::Spec->rel2abs('t/home');

use Data::Section::Simple qw(get_data_section);
my $expected = get_data_section;

use File::Slurper 'read_lines';
my $sh = $0 =~ s/\.t/.sh/r;
my @command = read_lines $sh or die;

if ($opt{show}) {
    for (keys @command) {
	printf "%4d: %s\n", $_, $command[$_];
    }
    exit;
}

if (defined(my $n = $opt{number})) {
    die "$n: invalid number\n" if $n > $#command;
    @command = $command[$n];
}

for (@command) {
    my @command = shellwords $_;
    if (-e (my $script = "script/$command[0]")) {
	$command[0] = $script;
    } else {
	unshift @command, '-S';
    }
    my $result = Command->new(@command)->exec();
    if ($opt{example}) {
	printf "\$ %s\n", $_;
	print $result;
    }
    elsif ($opt{'data-section'}) {
	printf "\@\@ %s\n", $_;
	print $result;
    }
    else {
	is($result, $expected->{$_}, $_);
    }
}

exit if %opt;

done_testing;

__DATA__

@@ cat-v t/fwsp.txt
〼吾輩は猫である。⏎
「ええ〼そう」╺─z⏎
@@ cat-v t/fwsp.txt --fwsp=0
　吾輩は猫である。⏎
「ええ　そう」╺─z⏎
@@ cat-v t/fwsp.txt -n -c fwsp=e
\x{3000}吾輩は猫である。
「ええ\x{3000}そう」	z
@@ cat-v t/fwsp.txt -n -c all=e,nl=0
\x{3000}吾輩は猫である。
「ええ\x{3000}そう」\tz
