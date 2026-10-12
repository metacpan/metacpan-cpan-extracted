package Clay::UI::_error;
our $VERSION = '0.06';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Exporter 'import';

our @EXPORT_OK = qw(croak_ui);

# Dies with $message and the location of the first caller outside
# Clay::UI (like Carp's croak, but across every Clay::UI package): the
# error points at the line of the program that misused the library, not
# at the library.
sub croak_ui ($message) {
	my $depth = 0;
	while (my ($package, $file, $line) = caller($depth++)) {
		next if $package =~ /\AClay::UI(?:::|\z)/;
		die "$message at $file line $line.\n";
	}
	die "$message\n";
}

1;

__END__

=head1 NAME

Clay::UI::_error - how Clay::UI reports misuse (internal)

=head1 DESCRIPTION

Internal to Clay::UI. C<croak_ui($message)> dies with C<$message> plus
C< at FILE line N.>, where FILE and N name the first caller outside the
C<Clay::UI> namespace. Every error Clay::UI raises for bad input goes
through it, so the message points at the program's line, never into the
library.

=cut
