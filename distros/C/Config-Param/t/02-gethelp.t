#!perl

use Test::More tests => 15;
use Config::Param;
use Storable qw(dclone);
use File::Basename qw(basename);
# For debugging failures.
#use Text::Diff;

use strict;

# Check if generated help messages match expectation.

my %default =
(
	 parm1=>'a string'
	,parm2=>'a number'
	,parmA=>[1, 2, 'free', 'beer']
	,parmH=>{'key'=>3, 'donkey'=>'animal'}
	,parmX=>'Y'
);

my @pardef =
(
	 'parm1', $default{parm1}, 'a', 'help text for scalar 1'
	,'parm2', $default{parm2}, 'b', 'help text for scalar 2'
	,'parmA', $default{parmA}, 'A', 'help text for array A'
	,'parmH', $default{parmH}, 'H', 'help text for hash H'
	,'parmX', $default{parmX}, '',  'help text for last one (scalar)'
);

my $output;

sub get_output
{
	my $variant = shift;
	my $output = "";
	open my $oh, '>>', \$output;
	#open my $oh, '>>', 'test.dat'; print $oh "------\n";
	my %config =
	(
		 noexit=>1, linewidth=>49
		,copyright=>'Copyright (c) 1234 mine'
		,output=>$oh, nofile=>1, lazy=>1
		,author=>'Thomas Orgis <some@place.tld>'
		,extrapod=>
		[
			 { head=>'ADDENDUM', body=>'Just some note with accidental B<POD> syntax.
  plus something indented, also with B<POD>', }
			,{ head=>'VERBATIM', body=>'A B<verbatim> section', verbatim=>1 }
		]
	);
	my $tagline = 'just a program for testing';
	my $descr = 'This is a longer description of the thing.';
	my $usage = basename($0)." [something]";

	if($variant eq 'infoline')
	{
		$config{info} = $tagline;
	} elsif($variant eq 'tagline')
	{
		$config{tagline} = $tagline;
	} elsif($variant eq 'tagdescr')
	{
		$config{tagline} = $tagline;
		$config{info}    = $descr;
	} elsif($variant eq 'tagusage')
	{
		$config{tagline} = $tagline;
		$config{usage}   = $usage;
	} elsif($variant eq 'tagusagedescr')
	{
		$config{tagline} = $tagline;
		$config{usage}   = $usage;
		$config{info}    = $descr;
	} elsif($variant eq 'allinfo')
	{
		$config{info} = "$tagline\n\nUsage:\n\t$usage\n\n$descr";
	}

	# no dclone of config because of the handle in it
	Config::Param::get(\%config, dclone(\@pardef), \@_);

	close $oh;
	return $output;
}

my $hbegin = <<EOT;

02-gethelp.t - just a program for testing

EOT

my $cpr = <<EOT;
Copyright (c) 1234 mine

EOT

my $hus = <<EOT;
Usage:
	02-gethelp.t [something]

EOT
my $huss = <<EOT;
Usage:
	02-gethelp.t [something]

EOT
my $des = <<EOT;
This is a longer description of the thing.

EOT

my $hmain .= <<EOT;
Generic parameter example (list of real
parameters follows):

	02-gethelp.t [-]s [-]xyz [-]s=value --long [-[-]]long=value - [files/stuff]

Just mentioning -s equals -s=1 (true), while +s
equals -s=0 (false). The separator "--" stops
option parsing.

Recognized parameters:

NAME, SHORT VALUE [# DESCRIPTION]
config, I   [] # Which configfile(s) to use
            (overriding automatic search in
            likely paths);
            special: just -I or --config causes
            printing a current config file to
            STDOUT
help, h ... 1 # Show the help message. Value
            1..9: help level, par: help for
            paramter par (long name) only.
parm1, a .. 'a string' # help text for scalar 1
parm2, b .. 'a number' # help text for scalar 2
parmA, A .. [1,2,'free','beer'] # help text for
            array A
parmH, H .. {donkey => 'animal',key => 3} # help
            text for hash H
parmX ..... 'Y' # help text for last one (scalar)

EOT

my $help = $hbegin.$cpr.$hmain;
$output = get_output('infoline', 'h');
ok( $output eq $help, 'normal help output' );

$output = get_output('tagline', 'h');
ok( $output eq $help, 'normal help output with tagline' );

my $help = $hbegin.$huss.$des.$cpr.$hmain;
$output = get_output('allinfo', 'h');
ok( $output eq $help, 'normal help output with all info' );

my $help = $hbegin.$hus.$des.$cpr.$hmain;
$output = get_output('tagusagedescr', 'h');
ok( $output eq $help, 'normal help output with tag, usage, description' );

$output = get_output('infoline', 'help=2');
$help = <<EOT;

02-gethelp.t - just a program for testing

Copyright (c) 1234 mine

Generic parameter example (list of real
parameters follows):

	02-gethelp.t [-]s [-]xyz [-]s=value --long [-[-]]long=value - [files/stuff]

The [ ] notation means that the enclosed - is
optional, saving typing time for really lazy
people. Note that "xyz" as well as "-xyz" mention
three short options, opposed to the long option
"--long". In trade for the shortage of "-", the
separator for additional unnamed parameters is
mandatory (supply as many "-" grouped together as
you like;-).

You mention the options to change parameters in
any order or even multiple times. They are
processed in the oder given, later operations
overriding/extending earlier settings. Using the
separator "--" stops option parsing
An only mentioned short/long name (no "=value")
means setting to 1, which is true in the logical
sense. Also, prepending + instead of the usual -
negates this, setting the value to 0 (false).
Specifying "-s" and "--long" is the same as
"-s=1" and "--long=1", while "+s" and "++long" is
the sames as "-s=0" and "--long=0".

There are also different operators than just "="
available, notably ".=", "+=", "-=", "*=" and
"/=" for concatenation / appending array/hash
elements and scalar arithmetic operations on the
value. Arrays are appended to via
"array.=element", hash elements are set via
"hash.=name=value". You can also set more
array/hash elements by specifying a separator
after the long parameter line like this for comma
separation:

	--array/,/=1,2,3  --hash/,/=name=val,name2=val2

Recognized parameters:

NAME, SHORT VALUE [# DESCRIPTION]
config, I   [] # Which configfile(s) to use
            (overriding automatic search in
            likely paths);
            special: just -I or --config causes
            printing a current config file to
            STDOUT
help, h ... 2 # Show the help message. Value
            1..9: help level, par: help for
            paramter par (long name) only.
            Additional fun with negative values,
            optionally followed by
            comma-separated list of parameter
            names:
            -1: list par names, -2: list one line
            per name, -3: -2 without builtins,
            -10: dump values (Perl style), -11:
            dump values (lines), -100: print POD.
parm1, a .. 'a string' # help text for scalar 1
parm2, b .. 'a number' # help text for scalar 2
parmA, A .. [1,2,'free','beer'] # help text for
            array A
parmH, H .. {donkey => 'animal',key => 3} # help
            text for hash H
parmX ..... 'Y' # help text for last one (scalar)

EOT

ok( $output eq $help, 'elaborate help output' );

$output = get_output('tagline', 'h=2');

ok( $output eq $help, 'elaborate help output with tagline' );

$output = get_output('infoline', '-help=-1');
$help = <<EOT;
List of parameters: config help parm1 parm2 parmA
	parmH parmX
EOT

ok( $output eq $help, 'parameter list 1' );

$output = get_output('infoline', 'h=-2');
$help = <<EOT;
config
help
parm1
parm2
parmA
parmH
parmX
EOT

ok( $output eq $help, 'parameter list 2' );

$output = get_output('infoline', 'h=-3');
$help = <<EOT;
parm1
parm2
parmA
parmH
parmX
EOT

ok( $output eq $help, 'parameter list 3' );

$output = get_output('infoline', '--help=-10,parmH,parmX');
$help = <<EOT;
{
  donkey => 'animal',
  key => 3
}
, 'Y'
EOT

ok( $output eq $help, 'perl-stype values' );

$output = get_output('infoline', 'help=-11,parmA,parmX,parmH');
$help = <<EOT;
1
2
free
beer
Y
donkey=animal
key=3
EOT

ok( $output eq $help, 'lined values' );


$output = get_output('infoline', '-h=-100');
#print STDERR "output:\n$output\n";

my $helphead = <<EOT;

=head1 NAME

02-gethelp.t - just a program for testing

EOT
my $helpusage = <<EOT;
=head1 SYNOPSIS

	02-gethelp.t [something]

EOT
my $helpdescr = <<EOT;
=head1 DESCRIPTION

This is a longer description of the thing.

EOT

my $helpbody = <<EOT;
=head1 PARAMETERS

These are the general rules for specifying parameters to this program:

	02-gethelp.t [-]s [-]xyz [-]s=value --long [-[-]]long=value - [files/stuff]

The [ ] notation means that the enclosed - is optional, saving typing time for really lazy people. Note that "xyz" as well as "-xyz" mention three short options, opposed to the long option "--long". In trade for the shortage of "-", the separator for additional unnamed parameters is mandatory (supply as many "-" grouped together as you like;-).

You mention the options to change parameters in any order or even multiple times. They are processed in the oder given, later operations overriding/extending earlier settings. Using the separator "--" stops option parsing
An only mentioned short/long name (no "=value") means setting to 1, which is true in the logical sense. Also, prepending + instead of the usual - negates this, setting the value to 0 (false).
Specifying "-s" and "--long" is the same as "-s=1" and "--long=1", while "+s" and "++long" is the sames as "-s=0" and "--long=0".

There are also different operators than just "=" available, notably ".=", "+=", "-=", "*=" and "/=" for concatenation / appending array/hash elements and scalar arithmetic operations on the value. Arrays are appended to via "array.=element", hash elements are set via "hash.=name=value". You can also set more array/hash elements by specifying a separator after the long parameter line like this for comma separation:

	--array/,/=1,2,3  --hash/,/=name=val,name2=val2

The available parameters are these, default values (in Perl-compatible syntax) at the time of generating this document following the long/short names:

=over 2

=item B<config>, B<I> (array)

	[]

Which configfile(s) to use (overriding automatic search in likely paths);
special: just -I or --config causes printing a current config file to STDOUT

=item B<help>, B<h> (scalar)

	0

Show the help message. Value 1..9: help level, par: help for paramter par (long name) only.

Additional fun with negative values, optionally followed by comma-separated list of parameter names:
-1: list par names, -2: list one line per name, -3: -2 without builtins, -10: dump values (Perl style), -11: dump values (lines), -100: print POD.

=item B<parm1>, B<a> (scalar)

	'a string'

help text for scalar 1

=item B<parm2>, B<b> (scalar)

	'a number'

help text for scalar 2

=item B<parmA>, B<A> (array)

	[
	  1,
	  2,
	  'free',
	  'beer'
	]

help text for array A

=item B<parmH>, B<H> (hash)

	{
	  donkey => 'animal',
	  key => 3
	}

help text for hash H

=item B<parmX> (scalar)

	'Y'

help text for last one (scalar)

=back

=head1 ADDENDUM

Just some note with accidental BZ<><POD> syntax.
  plus something indented, also with B<POD>

=head1 VERBATIM

A B<verbatim> section

=head1 AUTHOR

Thomas Orgis <some\@place.tld>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 1234 mine

=cut
EOT

$help = $helphead.$helpbody;
#print STDERR diff(\$help, \$output);
ok( $output eq $help, 'POD 1' );

$output = get_output('tagline', '-h=-100');
ok( $output eq $help, 'POD 2' );

$help = $helphead.$helpusage.$helpbody;
$output = get_output('tagusage', '-h=-100');
ok( $output eq $help, 'POD 3' );

$help = $helphead.$helpusage.$helpdescr.$helpbody;
$output = get_output('allinfo', '-h=-100');
ok( $output eq $help, 'POD 4' );
#print STDERR "output:\n$output\n";
#print STDERR "expect:\n$help";

