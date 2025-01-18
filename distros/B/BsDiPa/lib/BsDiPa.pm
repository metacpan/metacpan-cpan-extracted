#@ (S-)bsdipa - create or apply binary difference patch.
package BsDiPa;

use diagnostics -verbose;
use warnings;
use strict;

require XSLoader;
XSLoader::load();

1;
__END__
# POD {{{

=head1 NAME

S-bsdipa -- create or apply binary difference patch

=head1 SYNOPSIS

	use BsDiPa;

	print BsDiPa::VERSION, "\n";
	print BsDiPa::CONTACT;
	print BsDiPa::COPYRIGHT;

	# BsDiPa::{OK,FBIG,NOMEM,INVAL}: status codes

	my ($b, $a) = ("\012\013\00\01\02\03\04\05\06\07" x 3,
			"\010\011\012\013\014" x 4);
	my $pz;
	die 'sick' if BsDiPa::core_diff_zlib($b, $a, \$pz) ne BsDiPa::OK;
	my $pr;
	die 'sick2' if BsDiPa::core_diff_raw($b, $a, \$pr) ne BsDiPa::OK;

		my $x = uncompress($pz);
		die 'sick3' unless(($pr cmp $x) == 0);

	my $rz;
	die 'sick4' if BsDiPa::core_patch_zlib($a, $pz, \$rz) ne BsDiPa::OK;
	my $rr;
	die 'sick5' if BsDiPa::core_patch_raw($a, $pr, \$rr) ne BsDiPa::OK;

	die 'sick6' unless(($rz cmp $rr) == 0);

=head1 DESCRIPTION

Colin Percival's BSDiff, imported from FreeBSD and transformed into
a library; please see header comment of lib/s-bsdipa-lib.h for more:
create or apply binary difference patch.
The perl package only uses C<s_BSDIPA_32> mode (31-bit size limits).

=head1 INTERFACE

=over

=item C<VERSION> (string, eg, '0.5.3')

A version string.

=item C<CONTACT> (string)

Bug/Contact information.
Could be multiline, but has no trailing newline.

=item C<COPYRIGHT> (string)

A multiline string containing a copyright license summary.

=item C<OK> (number)

Result is usable.

=item C<FBIG> (number)

Data or resulting control block length too large.

=item C<NOMEM> (number)

Allocation failure.

=item C<INVAL> (number)

Any other error.

=item C<core_diff_zlib($before_sv, $after_sv, $patch_sv, $magic_window=0)>

Create a compressed binary diff
from the memory backing C<$before_sv>
to the memory backing C<$after_sv>,
and place the result in the (de-)reference(d) C<$patch_sv>.
On error C<undef> is stored if only C<$patch_sv> is accessible.
C<$magic_window> specifies lookaround bytes,
if 0 the built-in default is used (16 at the time of this writing);
the already unreasonable value 4096 is the maximum supported.

=item C<core_diff_raw($before_sv, $after_sv, $patch_sv, $magic_window=0)>

Exactly like C<core_diff_zlib()>, but without compression.
As compression is absolutely necessary, only meant for testing,
or as a foundation for other compression methods.

=item C<core_patch_zlib($after_sv, $patch_sv, $before_sv)>

Apply a compressed binary diff C<$patch_sv>
to the memory backing C<$after_sv>
in order to restore original content in the (de-)reference(d) C<$before_sv>.
On error C<undef> is stored if only C<$before_sv> is accessible.

=item C<core_patch_raw($after_sv, $patch_sv, $before_sv)>

Exactly like C<core_patch_zlib()>, but expects raw uncompressed patch.

=back

=head1 AUTHOR

Steffen Nurpmeso E<lt>steffen@sdaoden.euE<gt>.

=head1 LICENSE

All included parts use Open Source licenses.
Please dump the module constant C<COPYRIGHT> for more.

=cut
# }}}

# s-itt-mode
