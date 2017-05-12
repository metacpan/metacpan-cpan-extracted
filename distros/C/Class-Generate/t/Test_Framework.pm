package Test_Framework;

use warnings;
use strict;
use Exporter;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(&Test &Test_Failure &Report_Results &Arrays_Equal);
my $test_no = 1;
my @results;

sub Test(&) {
    my $code = $_[0];
    push @results, test_succeeds($code);
    if ( ! $results[$#results] ) {
	print STDERR $@, "\n" if $@;
    }
}

sub Test_Failure(&) {
    my $code = $_[0];
    push @results, ! test_succeeds($code);
}

sub Report_Results() {
    print '1..', ($#results+1), "\n";
    for ( my $i = 0; $i <= $#results; $i++ ) {
	print $results[$i] ? 'ok' : 'not ok', ' ', $i+1, "\n";
    }
}

sub test_succeeds {
    my $code = $_[0];
    my $result;
    eval { $result = &$code };
    return $result && ! $@;
}

sub Arrays_Equal($$) {
    my ($a1, $a2) = @_;
    return 0 if $#$a1 != $#$a2;
    for ( my $i = 0; $i <= $#$a1; $i++ ) {
	return 0 if $$a1[$i] ne $$a2[$i];
    }
    return 1;
}

1;
