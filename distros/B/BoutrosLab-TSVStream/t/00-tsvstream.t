### 00-tsvstream.t #############################################################################
# Basic tests for tsvstream objects

### Includes ######################################################################################

# Safe Perl
use warnings;
use strict;

use Carp;
use File::Temp;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More tests => 10;
use Test::Exception;

### Tests #################################################################################

package TestFooBar;

use Moose;
use namespace::autoclean;
use MooseX::ClassAttribute;

class_has '_fields' => (is => 'ro', isa => 'ArrayRef', default => sub { [ qw(foo bar) ] } );

with 'BoutrosLab::TSVStream::IO::Role::Fixed';

has 'foo'    => ( is => 'rw', isa => 'Str' );
has 'bar'    => ( is => 'rw', isa => 'Str' );

__PACKAGE__->meta->make_immutable;

package main;

sub _open_reader {
	my $testname = shift;
	my $args     = shift;
	my $reader;
	subtest "$testname - create reader" => sub {
		plan tests => 2;
		lives_ok { $reader = TestFooBar->reader(@$args) } "can create a stream reader ($testname - create reader)";
		isa_ok( $reader, 'BoutrosLab::TSVStream::IO::Reader::Fixed', "... it is a reader object ($testname - create reader)" );
		};
	return $reader;
	}

sub _open_writer {
	my $testname = shift;
	my $args     = shift;
	my $writer;
	subtest "$testname - create writer" => sub {
		plan tests => 2;
		lives_ok { $writer = TestFooBar->writer(@$args) } "can create a stream writer ($testname - create writer)";
		isa_ok( $writer, 'BoutrosLab::TSVStream::IO::Writer::Fixed', "... it is a writer object ($testname - create writer)" );
		};
	return $writer;
	}

sub _scan_stream {
	my $testname = shift;
	my $reader   = shift;
	my $writer   = shift;
	subtest "$testname - scan data" => sub {
		plan tests => $writer ? 17 : 12;
		my $count = 1;
		my $foobar;
		while ( lives_ok { $foobar = $reader->read } "read record($count) ($testname - scan data" ) {
			last unless defined $foobar;
			isa_ok( $foobar, 'TestFooBar', "... it is a TestFooBar ($testname - scan data" );
			for my $field (qw(foo bar)) {
				is( $foobar->$field, "$field$count",
					" ...     with the correct $field field value ($testname - scan data" );
				}
			lives_ok { $writer->write_comments( $reader->read_comments ) } "...    and its comments can be written ($testname - scan data" if $writer;
			lives_ok { $writer->write( $foobar ) } "...    and its fields can be written ($testname - scan data" if $writer;
			}
		continue { ++$count }

		is( $foobar, undef, "... got undef for EOF ($testname - scan data" );
		is( $count,  3,     "... ... at expected time ($testname - scan data" );
		lives_ok { $writer->write_comments( $reader->read_comments ) } "... trailing comments can be written ($testname - scan data" if $writer;
		lives_ok { undef $reader } "delete reader ($testname - scan data";
		};
	}

sub _read_stream {
	my $testname   = shift;
	my $args       = shift;
	my $write_args = shift;
	subtest $testname => sub {
		plan tests => $write_args ? 3: 2;
		my $reader = _open_reader( $testname, $args );
		my $writer;
		use Data::Dumper;
		# print "Using reader->pre_headers for writer: ", Dumper($reader->pre_headers);
		if ($write_args) {
		    my ($msge, $wargs ) = @$write_args;
			$writer = _open_writer( $msge, [@$wargs, pre_headers => $reader->pre_headers] );
			}
		_scan_stream( $testname, $reader, $writer );
		}
	}

sub _from_here {
	my $text = shift;
	$text =~ s/^\s*://gxms;
	$text;
	}

my @data = (
	[ 'strict', 'data with strict format', _from_here( <<'		:HERE' ) ],
		:foo	bar
		:foo1	bar1
		:foo2	bar2
		:HERE
	[ 'ALLCAPS', 'data with ALL CAPS HEADERS', _from_here( <<'		:HERE' ) ],
		:FOO	BAR
		:foo1	bar1
		:foo2	bar2
		:HERE
	[ 'spaced', 'data with surround spaces', _from_here( <<'		:HERE' ) ],
		: foo	bar 
		:  foo1	bar1  
		:   foo2	bar2   
		:HERE
	[
		'spaced, InitCaps',
		'data with surround spaces and Initial Caps Headers',
		_from_here( <<'		:HERE' ) ],
		: FOO	BAR 
		:  foo1	bar1  
		:   foo2	bar2   
		:HERE
		);

for my $testpair (@data) {
	my ( $name, $longname, $text ) = @$testpair;
	my $temphandle = File::Temp->new;
	my $filename   = $temphandle->filename;
	my $start      = $temphandle->getpos;
	print $temphandle $text;
	$temphandle->flush;
	subtest $longname => sub {
		plan tests => 3;
		$temphandle->setpos($start);
		_read_stream( "$name: handle only", [ handle => $temphandle ] );
		$temphandle->setpos($start);
		_read_stream( "$name: both handle and filename",
			[ handle => $temphandle, file => $filename ] );
		_read_stream( "$name: filename only", [ file => $filename ] );
		}
	}

my $head = <<END;
foo	bar
END

my $body = <<END;
foo1	bar1
foo2	bar2
END

my $foo1 = TestFooBar->new( foo => 'foo1', bar => 'bar1' );
my $foo2 = TestFooBar->new( foo => 'foo2', bar => 'bar2' );

{
	my $temphandle = File::Temp->new;
	my $filename   = $temphandle->filename;
	my $writer = _open_writer( 'write a TSV file', [file => $filename] );
	$writer->write($foo1);
	$writer->write($foo2);
	undef($writer);
	is( `cat $filename`, $head.$body, '... it gets expected contents' );
	$writer = _open_writer( 'append to a TSV file', [file => $filename, append => 1, header => 'skip'] );
	$writer->write($foo1);
	$writer->write($foo2);
	undef($writer);
	is( `cat $filename`, $head.$body.$body, '... it gets expected contents' );
	}

my @data2 = (
	[   'data with embedded comments',
		'embedded comments',
		[ ],
		[ ],
		_from_here( <<'			:HERE')
			:# A file that has comments
			:foo	bar
			:      # a comment with leading spaces
			:foo1	bar1
			:		# a comment with leading tabs
			:foo2	bar2
			:# a trailing comment
			:HERE
		],
	[   'data with pre_header and embedded comments',
		'pre_header and comments',
		[
		    comment_pattern => qr/^\s*#:#/,
			pre_header => 1,
			pre_header_pattern => qr/^\s*\%\%/ ],
		[ pre_header => 1 ],
		_from_here( <<'			:HERE')
			:%% A file with a pre_header
			:foo	bar
			:      #:# a comment with leading spaces
			:foo1	bar1
			:		#:# a comment with leading tabs
			:foo2	bar2
			:#:# a trailing comment
			:HERE
		],
#	[
#		]
	);

for my $test (@data2) {
	my( $longname, $shortname, $extra_read_args, $extra_write_args, $text ) = @$test;
	my $temphandle = File::Temp->new;
	my $filename   = $temphandle->filename;
	my $start      = $temphandle->getpos;
	my $outhandle  = File::Temp->new;
	my $outname    = $outhandle->filename;
	print $temphandle $text;
	$temphandle->flush;
	subtest $longname => sub {
		plan tests => 3;
		$temphandle->setpos($start);
		dies_ok { TestFooBar->reader( handle => $temphandle, header => 'check' ) }
			"$shortname - reader open should fail with a leading comment/header and comment handling not requested";
		$temphandle->setpos($start);
		_read_stream(
			"$shortname - comment handling enabled",
			[ handle => $temphandle, comment => 1, @$extra_read_args ],
			[ "comment output file", [ handle => $outhandle, comment => 1, pre_header => 1, @$extra_write_args ] ]
		);
		# system( "echo ==== file;cat $filename;echo ==== out;cat $outname;echo ==== DONE" );
		is( system( "cmp -s $filename $outname" ), 0,
			"$shortname - The copied file should be identical (including comments)." );
		};
	}


done_testing();

1;
