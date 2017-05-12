#!/usr/bin/perl
#
# round.t
#
# This test compares two Rlists compiled with different compile options.
#
# $Writestamp: 2008-07-20 23:05:19 andreas$
# $Compile: perl -M'constant standalone => 1' round.t$

use warnings;
use strict;
use constant;
use Test;
BEGIN { plan tests => 7 + 1203 }
BEGIN { unshift @INC, '../lib' if $constant::declared{'main::standalone'} }

use Benchmark;
use Data::Rlist qw/:options/;

our $t0 = new Benchmark;
our $tempfile = "$0.tmp";
our $Pi = 3.14159_26535_89793_23846_26433_83279_50288_41971_69399_37510;

#########################

{
	ok(${[KeelhaulData([-.00057260], complete_options({precision => 4}, 'squeezed'))]->[1]} eq '(-0.0006)');

	ok(OutlineData(sub{sub{\\'Greetings, earthlings!'}}, { code_refs => 1 }) eq '"Greetings, earthlings!"');
	ok(OutlineData(0.994, { precision => 2 }) == 0.99);
	ok(OutlineData(0.0010710000000000, { precision => 2 }) eq '0.00');
	ok(Data::Rlist::round($Pi) == 3.141593); # default accuracy is 6 places
	ok(Data::Rlist::round($Pi, 15) == 3.141592653589793);

	my ($deep_copy, $as_text) = Data::Rlist->new(-data => [-.00057260])->keelhaul({precision => 4});
	ok($deep_copy->[0] == -0.0006);

	my $quote = \\"And death shall have no dominion. (Dylan Thomas)";
	my $data = KeelhaulData($quote);
	ok(exists $data->{$$$quote});

	$quote = sub { sub { q'The time to repair the roof is when the sun is shining. John F. Kennedy' } };
	$data = KeelhaulData($quote);
	ok([keys %$data]->[0] eq '?CODE?');		# code_refs shall be disabled
	$data = KeelhaulData($quote, { code_refs => 1 });
	ok(exists $data->{$quote->()->()});
}

#########################

{
    my(%A, %B);
	my %org =
    (
	 test=>undef,
	 messages => <<___,
SectorModel 1.8.14-RELEASE multi-threaded
___
	 db_instance => 2006073104,
	 runtime_in_seconds => 34471,
	 hello => sub { 'Greetings, earthlings!' },
	 numerical_precisions => 
	 {
	  standard_deviation => 703320386.52728247642517,
	  expected_loss_diff => 0.00193048336651,
	  Pi => $Pi
	 },
	 foo => 'bar',
	 numbers =>
	 [
	  [
	   .23E-10,							# a very small number
	   3.14_15_92,						# a very important number
	   4_294_967_296,					# underscore for legibility
	   [0xff,							# hex
		0xdead_beef						# more hex
	   ],
	   0377,							# octal (only numbers, begins with 0)
	   0b011011,						# binary
	   0b1010_0110,						# binary, maybe more legible
	   [ 0.00000000000000, 0.00000000001495, 
		 0.12674123095023, 0.99980376022990 ]
	  ]
	 ],

	 "\\ü" => [ "ßöü^!", ";\"\'^" ]
    );

	my $info;
	our($prea, $preb,  $scntfc, $oo, $prec, $to_string);
	our($opta, $optb);
	our @predefd = qw/default string squeezed outlined fast/;
	our $obj;
	our $stop = sub($$) { 
		die "$_[0] != $_[1]   $prea<=>$preb  oo=$oo  prec=$prec  ${\($scntfc ? 'scientific' : '')}\n"
	};
    sub getab(@) {
        my($a, $b) = (\%A, \%B); $info = '';
        foreach (@_) {
            $info.= "$_ => ";
            $a = exists $a->{$_} ? $a->{$_} : $stop->("$info: not exists in \%A\n");
            $b = exists $b->{$_} ? $b->{$_} : $stop->("$info: not exists in \%B\n");
        } ($a, $b)
    }
    sub okcmps(@) { my($a, $b) = getab(@_); ok($a eq $b) || $stop->($a, $b); }
    sub okcmpn(@) { my($a, $b) = getab(@_); ok($a == $b) || $stop->($a, $b); }
	sub okdata($$) { my($a, $b) = @_; ok(not CompareData($a, $b)); }
	sub compopts($;$$) {
		my($s, $prec, $scn) = @_;
		return $s if (not ref $s) && $s =~ /^(fast|perl)$/;
		my $opts = Data::Rlist::complete_options($s);
		$opts->{precision} = $prec;
		$opts->{scientific} = $scn;
		$opts->{auto_quote} = $scn;
		$opts
	}

    foreach $prea (@predefd) {
		foreach $preb (reverse @predefd) {
			next if $prea eq $preb;
			foreach $oo (0..1) {
				$to_string = !$oo;
				$scntfc = $oo;
				foreach $prec (undef, qw/0 2 12 15/) {
					# Get compile-options that determine how to make %A and %B
					# from %org. For non-refinable compile options "fast" and
					# "perl" clear the precision for both option sets
					# (undef). Also, when one set uses a precision of 0 use
					# this precision also in the other set.  Reason: numbers
					# with different precisions are not comparable.

					$opta = compopts($prea, $prec, $scntfc);
					$optb = compopts($preb, $prec, $scntfc);

					if ((not ref $opta) or
						(not ref $optb) or
						(not defined $opta->{precision}) or
						(not defined $optb->{precision})) {
						# Note that from all predefined option sets only
						# "squeezed" defines a precision.
						$opta = compopts($opta, undef, $scntfc);
						$optb = compopts($optb, undef, $scntfc);
					} elsif ($opta->{precision} == 0) {
						$optb = compopts($optb, 0, $scntfc) 
					} elsif ($optb->{precision} == 0) {
						$opta = compopts($opta, 0, $scntfc);
					}

					# Make %A from %org by writing the hash to disk (with
					# $opta), then reload it. Make %B from %org by keelhauling
					# the hash (with $optb).

					if ($oo) {
						# Object-oriented interface.
						$obj = new Data::Rlist(-data => \%org, -options => $opta);
						if ($to_string) {
							$obj->set(-input => $obj->write);
						} else {
							$obj->set(-input => $tempfile, -output => $tempfile);
							$obj->write;
						}
						%A = %{$obj->read};
						%B = %{$obj->keelhaul($optb)};
					} else {
						# Functional interface.
						if ($to_string) {
							%A = %{Data::Rlist::read_string(Data::Rlist::write_string(\%org, $opta))};
						} else {
							Data::Rlist::write(\%org, $tempfile, $opta);
							%A = %{Data::Rlist::read($tempfile)};
						}
						%B = %{KeelhaulData(\%org, $optb)};
					}

					# Compare if %A and %B are equal (they should).

					okdata(\%A, \%B);
					okcmps(qw/db_instance/);
					okcmps(qw/messages/);
					okcmpn(qw/runtime_in_seconds/);
					okcmpn(qw/numerical_precisions expected_loss_diff/);
					okcmpn(qw/numerical_precisions standard_deviation/);
				}
			}
		}
	}
}

print "runtime: ", timestr(timediff(new Benchmark,$t0)), "\n\n"
if $constant::declared{'main::standalone'};

unlink $tempfile;

### Local Variables:
### buffer-file-coding-system: iso-latin-1
### End:
