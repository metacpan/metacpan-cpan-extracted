use Data::Dumper;
use Test::More;
use Test::Builder;
use Set::CrossProduct;

$Data::Dumper::Indent = undef;

use constant STANDARD_DIM => ([    1,    1],
                              [    1,    2],
                              [    2,    1],
                              [    2,    2],
                              [    1, 1_000],
                              [1_000,     1],
                              [   25,    50]);
                              
my $Tester = Test::Builder->new();

sub qt($) {
    $_ = shift();
    s/\t/\\t\t/g;
    s/\n/\\n\n/g;
    return $_;
}

sub _named_rows($) {
    my $size = shift;
    return map "Row $_", (0 .. $size-1);
}

sub _named_cols($) {
    my $size = shift;
    return map "Col $_", (0 .. $size-1);
}

sub round($) {
    sprintf "%.3f", shift();
}

sub all_ok(&$$) {
	my ($sub, $params, $test_name) = @_;
    if (ref($params->[0]) eq 'ARRAY') {
        my $iterator = Set::CrossProduct->new( $params );
	    my $tuple = undef;
    	while ($tuple = $iterator->get()) {
	    	last unless &$sub( @$tuple );
    	}
	    ok( ! defined $tuple, $test_name ) or 
		    diag( 'Parameter: ' . Dumper($tuple));
    } else {
        my $ok = 1;
        my $param = undef;
        foreach $param (@$params) {
            $sub->($param) or $ok = 0,last;
        }
        ok ( $ok, $test_name ) or diag( 'Parameter: ' . Dumper($param) );
    }
}

sub all_dies_ok(&$$) {
    all_throws_ok($_[0], qr/./, $_[1], $_[2]);
}

sub _throws {
	my ( $sub, $class ) = @_;
	eval {&$sub()};
	my $exception = $@;
	my $ok;
	unless (defined($exception) && $exception eq '') {
		my $regex;
		if ($regex = $Tester->maybe_regex($class)) {
			$ok = ($exception =~ m/$regex/);
		} elsif (ref($exception)) {
			$class = ref($class) if ref($class);
			$ok = UNIVERSAL::isa($exception, $class);
		};
	};
	my @diag = ();
	unless ($ok) {
		if (defined($exception)) {
			$exception = 'normal exit' if $exception eq '';
		} else {
			$exception = 'undef';
		};
		$class = 'undef' unless defined($class);
		$class .= " exception" unless ref($class);
		push @diag, ("expecting: $class");
		push @diag, ("found: $exception");
	};
	$@ = $exception;
	return($ok, \@diag);
}

sub all_throws_ok (&$$$) {
	my ($sub, $class, $params, $message) = @_;
	my $diag = undef;
	all_ok (
		sub { 
			my @params = @_; 
			my $ok; ($ok, $diag) = _throws( sub { &$sub(@params) }, $class ); 
			$ok 
		},
		$params,
		$message
	);
	if ($diag) { 
		diag($_) foreach (@$diag);
	}
}

1;                              
