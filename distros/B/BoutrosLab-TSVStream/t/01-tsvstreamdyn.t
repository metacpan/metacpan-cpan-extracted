### 00-tsvstream.t #############################################################
# Basic tests for tsvstream objects

### Includes ###################################################################

# Safe Perl
use warnings;
use strict;

use Carp;
use File::Temp;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More tests => 122;
use Test::Exception;

### Tests ######################################################################

package TestFooBar;

use Moose;
use namespace::autoclean;
use MooseX::ClassAttribute;

class_has '_fields' => (is => 'ro', isa => 'ArrayRef', default => sub { [ qw(foo bar) ] } );

with 'BoutrosLab::TSVStream::IO::Role::Dyn';

has 'foo'    => ( is => 'rw', isa => 'Str' );
has 'bar'    => ( is => 'rw', isa => 'Str' );

around BUILDARGS => sub {
	my $orig  = shift;
	my $class = shift;
	my $arg   = ref($_[0]) ? $_[0] : { @_ };
	$class->$orig( $arg );
	};

# __PACKAGE__->meta->make_immutable;

package TestOnlyDyn;

use Moose;

with 'BoutrosLab::TSVStream::IO::Role::Dyn';

{
my $_fields = [ ];
sub _fields { return $_fields }
}

around BUILDARGS => sub {
	my $orig  = shift;
	my $class = shift;
	my $arg   = ref($_[0]) ? $_[0] : { @_ };
	$class->$orig( $arg );
	};

# __PACKAGE__->meta->make_immutable;

package main;

sub _from_here {
	my $text = shift;
	$text =~ s/^\s*://gxms;
	$text;
	}

sub _strip_2_cols {
	my $t = shift;
	$t =~ s/^[^\t\n]+\t[^\t\n]+\t?//gxms;
	return $t;
	}

sub _strip_header {
	my $t = shift;
	$t =~ s/^[^\n]*\n//xms;
	return $t;
	}

sub _strip_body {
	my $t = shift;
	$t =~ m/(^[^\n]*\n)/xms;
	return $1;
	}

my @tests = (
	[ 'Empty Dyn List' => ( [], <<'		:EOF' )],
		:foo	bar
		:foo1	bar1
		:foo2	bar2
		:EOF
	[ '1 col Dyn List' => ( [qw(baz)], <<'		:EOF' )],
		:foo	bar	baz
		:foo1	bar1	baz1
		:foo2	bar2	baz2
		:EOF
	[ '3 col Dyn List' => ( [qw(baz bez biz)], <<'		:EOF' )],
		:foo	bar	baz	bez	biz
		:foo1	bar1	baz1	bez1	biz1
		:foo2	bar2	baz2	bez2	biz2
		:EOF
	);

is_deeply( TestFooBar->_fields, [qw(foo bar)], 'TestFooBar -> _fields' );
is_deeply( TestOnlyDyn->_fields, [], 'TestOnlyDyn -> _fields' );

for my $t (@tests) {
	my( $name, $extra_fields, $text ) = @$t;
	$text      = _from_here($text);
	_test( $name, $extra_fields, $text );
	}

sub _test {
	my( $name, $ext, $text ) = @_;
	my $textnh    = _strip_header($text);
	my $textnfb   = _strip_2_cols($text);
	my $textnfbnh = _strip_header($textnfb);
	_test_header( 'TestFooBar',  $name, $ext, $text,    $textnh );
	_test_header( 'TestOnlyDyn', $name, $ext, $textnfb, $textnfbnh );
	}

sub _test_header {
	my( $pkg, $name, $ext, $text, $textnh ) = @_;

	my $headeronly = _strip_body($text);
	my $empty = '';
	my @exp_dyn_names_none = map { "extra$_" } 1 .. @$ext;

	for my $t (
		[ default   => [                                            ], 0, ],
		[ auto      => [ header => 'auto'                           ], 0, ],
		[ check     => [ header => 'check'                          ], 2, ],
		[ none      => [ header => 'none'                           ], 0, ],
		[ none_list => [ header => 'none', fields => $pkg->_fields  ], 3, ],
	) {
		my ($hinf, $hargs, $opfail) = @$t;
		for my $tx (
			[ HdrText => $text, 1, 2 ],
			[ NoHdrText => $textnh, 2, 2 ],
			[ HdrNoText => $headeronly, 1, 0 ],
			[ NoHdrNoText => $empty, 1, 0 ],
		) {
			my ($txtinf, $txtbody, $pass, $lines) = @$tx;
			my $title = sprintf "--- %s --- pkg( %11s ) header (%9s %9s)",
				$name, $pkg, $hinf, $txtinf;
			# TODO: Add tests for handling empty body, and empty file
			subtest $title => sub {
				my $ext_use
					= $txtinf eq 'NoHdrText'	?	\@exp_dyn_names_none
					: $txtinf eq 'NoHdrNoText'	?	[]
					: $hinf =~ /^none/			?	\@exp_dyn_names_none
				    :								$ext;
				if ($pkg eq 'TestOnlyDyn' && $hinf !~ /^none/ && $txtinf eq 'NoHdrText') {
					plan tests => 1;
					pass("with no fixed fields, auto/check cannot work");
					}
				elsif ($opfail & $pass) {	# boolean &, not logical!
					plan tests => 2;
					my $fh;
					lives_ok { open $fh, '<', \$txtbody } "    open";
					my $reader;
					dies_ok { $reader = $pkg->reader( handle => $fh, @$hargs ) } "    create reader cannot autofind headers";
					}
				else {
					plan tests => 7;
					my $fh;
					lives_ok { open $fh, '<', \$txtbody } "    open";
					my $reader;
					lives_ok { $reader = $pkg->reader( handle => $fh, @$hargs ) } "    create reader can deal with headers";
					is_deeply( $reader->dyn_fields, $ext_use, "    found dyn field names" )
						|| note explain "Received:", $reader->dyn_fields, "Expecterd:", $ext_use,
						"exp_dyn_names_none", \@exp_dyn_names_none, $txtinf;
					my @rec_fixed;
					my @rec_dyn;
					my $hdr_as_data = $hinf eq 'none' && $txtinf =~ /^Hdr/;
					my @exp_fixed;
					my @exp_dyn;
					for my $i (1..$lines) {
						push @exp_fixed, map { "$_$i" } @{ $pkg->_fields };
						push @exp_dyn,   map { "$_$i" } @$ext;
						}
					my @exp_fixed_none = ( @{ $pkg->_fields }, @exp_fixed );
					my @exp_dyn_none = ( @$ext, @exp_dyn );
					for my $i (1 .. ($hdr_as_data ? $lines+1 : $lines)) {
						my $rec = $reader->read;
						push @rec_fixed,  map { $rec->$_ } @{ $pkg->_fields };
						push @rec_dyn,    @{ $rec->dyn_values };
						}
					if ($hdr_as_data) {
						is_deeply( \@rec_fixed, \@exp_fixed_none, "    - fixed field values with header as data" );
						is_deeply(   \@rec_dyn,   \@exp_dyn_none, "    - dyn field values with header as data" )
							|| note explain "Received:", \@rec_dyn, "Expecterd:", \@exp_dyn_none;
						}
					else {
						is_deeply( \@rec_fixed, \@exp_fixed,      "    - fixed field values" );
						is_deeply(   \@rec_dyn,   \@exp_dyn,      "    - dyn field values" )
							|| note explain "Received:", \@rec_dyn, "Expecterd:", \@exp_dyn;
						}
					is($reader->read, undef, "    read at EOF");
					ok($reader->_at_eof, "    status at EOF")
					};
				};
			};
		};
	}

done_testing();

1;
