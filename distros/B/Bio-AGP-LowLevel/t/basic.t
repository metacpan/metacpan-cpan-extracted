#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use File::Basename;
use File::Spec;
use File::Temp qw/tempfile/;

my $testfiles_path = File::Spec->catdir($FindBin::RealBin,'data');
my @agptests = (
                { file => 'chr04.v3.agp',
                  lines => 163,
                  specs =>
                  {
                   5 => {qw(
                            objname S.lycopersicum-chr4
                            ostart  357124
                            oend  407123
                            partnum 5
                            type N
                            typedesc known_gap
                            is_gap 1
                            length 50000
                            gap_type clone
                            linkage yes
                            linenum 5
                           )},
		       28 => {qw(
				 objname S.lycopersicum-chr4
				 ostart 1877407
				 oend 1989558
				 partnum 27
				 linenum 28
				 type F
				 typedesc finished
				 is_gap 0
				 ident C04HBa0036C23.1
				 cstart 2001
				 cend 114152
				 length 112152
				 orient +
				)},
		       49 => {qw(
				 objname S.lycopersicum-chr4
				 ostart 3472176
				 oend 3590122
				 partnum 48
				 linenum 49
				 type F
				 typedesc finished
				 is_gap 0
				 ident C04HBa0147F16.1
				 cstart 1
				 cend 117947
				 orient -
				 length 117947
				)},
		      },
		      contigs => {
				  7 => [
					{
					 'objname' => 'S.lycopersicum-chr4',
					 'ostart' => 1737070,
					 'cend' => 28696,
					 'oend' => 1765765,
					 is_gap => 0,
					 'ident' => 'C04HBa0114G11.1',
					 'length' => 28696,
					 'typedesc' => 'finished',
					 'orient' => '+',
					 'linenum' => '26',
					 'type' => 'F',
					 'cstart' => 1,
					 'partnum' => 25
					},
					{
					 'objname' => 'S.lycopersicum-chr4',
					 'ostart' => 1765766,
					 'cend' => 113641,
					 'oend' => 1877406,
					 is_gap => 0,
					 'ident' => 'C04HBa0050I18.1',
					 'length' => 111641,
					 'typedesc' => 'finished',
					 'orient' => '+',
					 'linenum' => '27',
					 'type' => 'F',
					 'cstart' => 2001,
					 'partnum' => 26
					},
					{
					 'objname' => 'S.lycopersicum-chr4',
					 'ostart' => 1877407,
					 'cend' => 114152,
					 'oend' => 1989558,
					 is_gap => 0,
					 'ident' => 'C04HBa0036C23.1',
					 'length' => 112152,
					 'typedesc' => 'finished',
					 'orient' => '+',
					 'linenum' => '28',
					 'type' => 'F',
					 'cstart' => 2001,
					 'partnum' => 27
					},
					{
					 'objname' => 'S.lycopersicum-chr4',
					 'ostart' => 1989559,
					 'cend' => 81572,
					 'oend' => 2069130,
					 is_gap => 0,
					 'ident' => 'C04HBa0008H22.1',
					 'length' => 79572,
					 'typedesc' => 'finished',
					 'orient' => '+',
					 'linenum' => '29',
					 'type' => 'F',
					 'cstart' => 2001,
					 'partnum' => 28
					}
				       ],
				 },
		    },
		    { file => 'chr09.v1.agp',
		      lines => 155,
		    },
                    { file => 'test_seq_assembly.agp',
                      lines => 5,
                    },

		  );
$_->{file} = File::Spec->catfile($testfiles_path,$_->{file}) foreach @agptests;

use Test::More;
use File::Temp qw/tempfile/;

use_ok(  'Bio::AGP::LowLevel' , qw/ agp_parse agp_write agp_contigs / )
    or BAIL_OUT('could not include the module being tested');


foreach my $test (@agptests) {
  #diag "testing with $test->{file}\n";
  my $lines = agp_parse($test->{file},validate_syntax => 1)
    or die 'parse failed';
  is(scalar(@$lines),$test->{lines},'correct line count');
  while(my ($line,$spec) = each %{$test->{specs}}) {
    is_deeply($lines->[$line-1],
	      $spec,
	      'check spec',
	     );
  }

  my ($tfh,$tf) = tempfile(UNLINK => 1);
  agp_write($lines,$tfh);
  close $tfh;

  #now do a parse of the new written file
  my $morelines = agp_parse($tf,validate_syntax => 1);
  is_deeply($lines,$morelines,'read-write-read round-trip is lossless');

  #extract the contigs and check them
  my @contigs = agp_contigs($morelines);
  while( my ($idx,$ctg) = each %{$test->{contigs}}) {
    is_deeply($contigs[$idx],$ctg,'contig '.($idx+1).' extracted OK');
  }

}

done_testing;
exit;

