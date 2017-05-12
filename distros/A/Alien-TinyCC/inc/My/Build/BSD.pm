########################################################################
                    package My::Build::BSD;
########################################################################

use strict;
use warnings;
use parent 'My::Build::Linux';

sub make_command { 'gmake' }

### MidnightBSD detection patch ###

my $is_midnight_handled = 0;

# Apply patch for MidnightBSD
My::Build::apply_patches('src/configure' =>
	# Note if we have already taken care of midnight bsd or not
	qr/MidnightBSD\) noldl=yes;;/ => sub {
		$is_midnight_handled = 1;
		return 0;
	},
	qr/DragonFly\) noldl=yes;;/ => sub {
		my ($in_fh, $out_fh, $line) = @_;
		print $out_fh "  MidnightBSD) noldl=yes;;\n"
			unless $is_midnight_handled;
		return 0;
	}
	
);

1;
