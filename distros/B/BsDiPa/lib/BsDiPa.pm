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

	my $pz, $px, $pr, $iseq;
	die if BsDiPa::core_diff_zlib($b, $a, \$pz, undef, \$iseq) ne BsDiPa::OK;
	die unless(!$iseq);
	if(BsDiPa::HAVE_XZ){
		die if BsDiPa::core_diff_xz($b, $a, \$px, undef, \$iseq) ne BsDiPa::OK;
		die unless(!$iseq)
	}
	die if BsDiPa::core_diff_raw($b, $a, \$pr) ne BsDiPa::OK;

		my $x = uncompress($pz);
		die unless(($pr cmp $x) == 0);

	my $rz, $rx, $rr;
	die if BsDiPa::core_patch_zlib($a, $pz, \$rz) ne BsDiPa::OK;
	if(BsDiPa::HAVE_XZ){
		die if BsDiPa::core_patch_xz($a, $px, \$rx) ne BsDiPa::OK
	}
	die if BsDiPa::core_patch_raw($a, $pr, \$rr) ne BsDiPa::OK;
	die unless(($rr cmp $b) == 0);
	die unless(($rz cmp $rr) == 0);
	die unless(!BsDiPa::HAVE_XZ || ($rx cmp $rr) == 0);

=head1 DESCRIPTION

Colin Percival's BSDiff, imported from FreeBSD and transformed into
a library; please see header comment of lib/s-bsdipa-lib.h for more:
create or apply binary difference patch.
The perl package only uses C<s_BSDIPA_32> mode (31-bit size limits).

=head1 INTERFACE

=over

=item C<VERSION> (string, eg, '0.8.0')

A version string.

=item C<CONTACT> (string)

Bug/Contact information.
Could be multiline, but has no trailing newline.

=item C<COPYRIGHT> (string)

A multiline string containing a copyright license summary.

=item C<HAVE_XZ> (number / boolean)

Returns 1 if support for liblzma (XZ) is available, 0 otherwise.
This is a compile time detection feature.

=item C<OK> (number)

Result is usable.

=item C<FBIG> (number)

Data or resulting control block length too large.

=item C<NOMEM> (number)

Allocation failure.

=item C<INVAL> (number)

Any other error, like invalid argument.

=item C<core_diff_zlib($before_sv, $after_sv, $patch_sv, $magic_window=0, $is_equal_data=0, $io_cookie=0)>

Create a compressed binary diff
from the memory backing C<$before_sv>
to the memory backing C<$after_sv>,
and place the result in the (de-)reference(d) C<$patch_sv>.
On error C<undef> is stored if at least C<$patch_sv> is accessible.
The optional C<$magic_window> specifies lookaround bytes,
if <=0 the built-in default is used (16 at the time of this writing);
the already unreasonable value 4096 is the maximum supported.
The optional reference C<$is_equal_data> will be set to 1
if C<$before_sv> and C<$after_sv> represent identical data,
to 0 otherwise; it is only defined on success.
See below for C<$io_cookie>.

=item C<core_diff_xz($before_sv, $after_sv, $patch_sv, $magic_window=0, $is_equal_data=0, $io_cookie=0)>

Exactly like C<core_diff_zlib()>, but with XZ (lzma) compression scheme.
Only available if C<HAVE_XZ> is true.

=item C<core_diff_raw($before_sv, $after_sv, $patch_sv, $magic_window=0, $is_equal_data=0, $io_cookie=0)>

Exactly like C<core_diff_zlib()>, but without compression.
As compression is absolutely necessary, only meant for testing,
or as a foundation for other compression methods.

=item C<core_patch_zlib($after_sv, $patch_sv, $before_sv, $max_allowed_restored_len=0, $io_cookie=0)>

Apply a compressed binary diff C<$patch_sv>
to the memory backing C<$after_sv>
in order to restore original content in the (de-)reference(d) C<$before_sv>.
C<$max_allowed_restored_len> specifies the maximum allowed size of the restored
data in bytes,
if 0 the effective limit is 31-bit.
On error C<undef> is stored if at least C<$before_sv> is accessible.
See below for C<$io_cookie>.

=item C<core_patch_xz($after_sv, $patch_sv, $before_sv, $max_allowed_restored_len=0, $io_cookie=0)>

Exactly like C<core_patch_zlib()>, but expects a XZ (lzma) compressed patch.
Only available if C<HAVE_XZ> is true.

=item C<core_patch_raw($after_sv, $patch_sv, $before_sv, $max_allowed_restored_len=0, $io_cookie=0)>

Exactly like C<core_patch_zlib()>, but expects an uncompressed raw patch.

=item C<core_io_cookie_gut($io_cookie)>

Delete an I/O cookie that was created via one of the C<core_io_cookie_new*()> functions below.
An I/O cookie can be used for diffing and patching in any order,
and can (massively) reduce memory and other creation/release costs, where supported.

=item C<core_io_cookie_new_xz($level=0)>

Create an I/O cookie for the XZ compression scheme.
C<$level> will be used for the compression level (no value check) if set.
Only available if C<HAVE_XZ> is true.

=back

=head1 AUTHOR

Steffen Nurpmeso E<lt>steffen@sdaoden.euE<gt>.

=head1 LICENSE

All included parts use Open Source licenses.
Please dump the module constant C<COPYRIGHT> for more.

=cut
# }}}

# s-itt-mode
