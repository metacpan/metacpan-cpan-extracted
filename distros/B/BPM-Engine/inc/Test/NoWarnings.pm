#line 1
package Test::NoWarnings;

use 5.006;
use strict;
use warnings;
use Carp                      ();
use Exporter                  ();
use Test::Builder             ();
use Test::NoWarnings::Warning ();

use vars qw( $VERSION @EXPORT_OK @ISA $do_end_test );
BEGIN {
	$VERSION   = '1.04';
	@ISA       = 'Exporter';
	@EXPORT_OK = qw(
		clear_warnings
		had_no_warnings
		warnings
	);

	# Do we add the warning test at the end?
	$do_end_test = 0;
}

my $TEST     = Test::Builder->new;
my $PID      = $$;
my @WARNINGS = ();
my $EARLY    = 0;

$SIG{__WARN__} = make_catcher(\@WARNINGS);

sub import {
	$do_end_test = 1;
	if ( grep { $_ eq ':early' } @_ ) {
		@_ = grep { $_ ne ':early' } @_;
		$EARLY = 1;
	}
	goto &Exporter::import;
}

# the END block must be after the "use Test::Builder" to make sure it runs
# before Test::Builder's end block
# only run the test if there have been other tests
END {
	had_no_warnings() if $do_end_test;
}

sub make_warning {
	local $SIG{__WARN__};

	my $msg     = shift;
	my $warning = Test::NoWarnings::Warning->new;

	$warning->setMessage($msg);
	$warning->fillTest($TEST);
	$warning->fillTrace(__PACKAGE__);

	$Carp::Internal{__PACKAGE__.""}++;
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	$warning->fillCarp($msg);
	$Carp::Internal{__PACKAGE__.""}--;

	return $warning;
}

# this make a subroutine which can be used in $SIG{__WARN__}
# it takes one argument, a ref to an array
# it will push the details of the warning onto the end of the array.
sub make_catcher {
	my $array = shift;

	return sub {
		my $msg = shift;

		# Generate the warning
		$Carp::Internal{__PACKAGE__.""}++;
		push(@$array, make_warning($msg));
		$Carp::Internal{__PACKAGE__.""}--;

		# Show the diag early rather than at the end
		if ( $EARLY ) {
			$TEST->diag( $array->[-1]->toString );
		}

		return $msg;
	};
}

sub had_no_warnings {
	return 0 if $$ != $PID;

	local $SIG{__WARN__};
	my $name = shift || "no warnings";

	my $ok;
	my $diag;
	if ( @WARNINGS == 0 ) {
		$ok = 1;
	} else {
		$ok = 0;
		$diag = "There were " . scalar(@WARNINGS) . " warning(s)\n";
		unless ( $EARLY ) {
			$diag .= join "----------\n", map { $_->toString } @WARNINGS;
		}
	}

	$TEST->ok($ok, $name) || $TEST->diag($diag);

	return $ok;
}

sub clear_warnings {
	local $SIG{__WARN__};
	@WARNINGS = ();
}

sub warnings {
	local $SIG{__WARN__};
	return @WARNINGS;
}

sub builder {
	local $SIG{__WARN__};
	if ( @_ ) {
		$TEST = shift;
	}
	return $TEST;
}

1;

__END__

#line 336
