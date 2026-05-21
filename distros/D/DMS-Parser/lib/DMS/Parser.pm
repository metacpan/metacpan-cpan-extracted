package DMS::Parser;
# DMS parser — Perl port of the Rust reference.
# Public (SPEC v0.14): DMS::Parser::decode($src) -> hashref/arrayref/scalar/blessed-DT.
# The legacy spelling DMS::Parser::parse($src) is retained as a deprecated
# alias and emits a one-time Carp::carp warning per process. SPEC §Decode/Encode.

use strict;
use warnings;
use utf8;
use Carp ();
# Tie::IxHash is loaded lazily (only when non-lite mode actually
# constructs a tied table) — saves ~30ms of startup and avoids the
# import entirely on the lite/encoder hot path.
# Several historical imports (POSIX qw(floor), Math::BigInt, Encode)
# have been removed: floor is unused; integer parsing now hand-rolls
# i64 on native IVs (no BigInt); UTF-8 work goes through utf8::is_utf8
# / utf8::decode core builtins (no Encode). Importing those modules
# only at need keeps DMS::Parser load time low — material on small
# CLI invocations like the conformance encoder.
# Unicode::Normalize is loaded lazily — pure-ASCII source short-circuits
# the NFC pass, so most CLI invocations never need the module at all.
sub _NFC { require Unicode::Normalize; *_NFC = \&Unicode::Normalize::NFC; goto &_NFC }

our $VERSION = '0.5.3';

# Capability flag — this port ships lite-mode decode + lite-mode encode_lite.
# See SPEC §Parsing modes — full and lite.
our $SUPPORTS_LITE_MODE = 1;

# Capability flag — this port ships unordered-table parse mode.
# See SPEC §Unordered tables.
our $SUPPORTS_IGNORE_ORDER = 1;

# Datetime sentinel classes -----------------------------------------------
# All typed-scalar sentinels are blessed *scalar refs* rather than blessed
# hashrefs. That's one allocation instead of three (HV + hv_entry + RV)
# per value — noticeable on wide-flat documents where every leaf is a
# typed scalar. Public accessor API (->value, ->bstr, ->is_neg) unchanged.
package DMS::Parser::LocalDate;       sub new { my $v = "$_[1]"; bless \$v, $_[0] } sub value { ${ $_[0] } }
package DMS::Parser::LocalTime;       sub new { my $v = "$_[1]"; bless \$v, $_[0] } sub value { ${ $_[0] } }
package DMS::Parser::LocalDateTime;   sub new { my $v = "$_[1]"; bless \$v, $_[0] } sub value { ${ $_[0] } }
package DMS::Parser::OffsetDateTime;  sub new { my $v = "$_[1]"; bless \$v, $_[0] } sub value { ${ $_[0] } }
package DMS::Parser::Float;           sub new { my $v = 0 + $_[1]; bless \$v, $_[0] } sub value { ${ $_[0] } }
# DMS::Parser::Integer holds the canonical decimal representation. On 64-bit Perl
# it's stored as a native IV so the parser doesn't pay a string-format
# cost just to build it. `value()` returns the object itself so callers
# can chain `->bstr` / `->is_neg` — the public API matches what was
# previously a Math::BigInt instance (`$int->value->bstr` still works).
package DMS::Parser::Integer;
sub new    { my $v = 0 + $_[1]; bless \$v, $_[0] }
sub value  { $_[0] }
sub bstr   { "${ $_[0] }" }   # force stringification of the IV
sub is_neg { ${ $_[0] } < 0 }
package DMS::Parser::Bool;             sub new { my $v = $_[1]?1:0; bless \$v, $_[0] } sub value { ${ $_[0] } }

# Path-segment marker class used inside attached-comment paths to
# distinguish list-index segments (DMS::Parser::Index) from string-keyed table
# segments (plain Perl scalars). Mirrors Rust's BreadcrumbSegment::Index.
package DMS::Parser::Index;
sub new   { my $v = 0 + $_[1]; bless \$v, $_[0] }
sub value { ${ $_[0] } }

# SPEC §"Unordered tables". Marker class for body tables produced by the
# *_unordered parser entry points. Underlying storage is a plain Perl
# hashref (no Tie::IxHash, no `\0_keys` sidecar) — iteration order is
# arbitrary per Perl's hash randomization. Mirrors Rust's
# Value::UnorderedTable. `to_dms` (full mode) refuses to round-trip a
# Document containing this variant; `to_dms_lite` accepts it.
package DMS::Parser::UnorderedTable;
# Construct from a plain hashref. Caller hands ownership of the hash.
sub new {
    my ($class, $h) = @_;
    $h = {} unless defined $h;
    return bless $h, $class;
}

package DMS::Parser;

# UAX #31 §2 default identifier syntax frozen at Unicode 15.1.
# Sorted, non-overlapping ranges: XID_Continue \ Default_Ignorable_Code_Point
# (per SPEC: every parser must use this same frozen snapshot — relying on
# Perl's `\p{XID_Continue}` would track the host's Unicode data and accept
# newly-assigned codepoints DMS does not know about). 772 ranges total.
our @XID_CONTINUE_RANGES = (
    [0x00AA, 0x00AA],
    [0x00B5, 0x00B5],
    [0x00B7, 0x00B7],
    [0x00BA, 0x00BA],
    [0x00C0, 0x00D6],
    [0x00D8, 0x00F6],
    [0x00F8, 0x02C1],
    [0x02C6, 0x02D1],
    [0x02E0, 0x02E4],
    [0x02EC, 0x02EC],
    [0x02EE, 0x02EE],
    [0x0300, 0x034E],
    [0x0350, 0x0374],
    [0x0376, 0x0377],
    [0x037B, 0x037D],
    [0x037F, 0x037F],
    [0x0386, 0x038A],
    [0x038C, 0x038C],
    [0x038E, 0x03A1],
    [0x03A3, 0x03F5],
    [0x03F7, 0x0481],
    [0x0483, 0x0487],
    [0x048A, 0x052F],
    [0x0531, 0x0556],
    [0x0559, 0x0559],
    [0x0560, 0x0588],
    [0x0591, 0x05BD],
    [0x05BF, 0x05BF],
    [0x05C1, 0x05C2],
    [0x05C4, 0x05C5],
    [0x05C7, 0x05C7],
    [0x05D0, 0x05EA],
    [0x05EF, 0x05F2],
    [0x0610, 0x061A],
    [0x0620, 0x0669],
    [0x066E, 0x06D3],
    [0x06D5, 0x06DC],
    [0x06DF, 0x06E8],
    [0x06EA, 0x06FC],
    [0x06FF, 0x06FF],
    [0x0710, 0x074A],
    [0x074D, 0x07B1],
    [0x07C0, 0x07F5],
    [0x07FA, 0x07FA],
    [0x07FD, 0x07FD],
    [0x0800, 0x082D],
    [0x0840, 0x085B],
    [0x0860, 0x086A],
    [0x0870, 0x0887],
    [0x0889, 0x088E],
    [0x0898, 0x08E1],
    [0x08E3, 0x0963],
    [0x0966, 0x096F],
    [0x0971, 0x0983],
    [0x0985, 0x098C],
    [0x098F, 0x0990],
    [0x0993, 0x09A8],
    [0x09AA, 0x09B0],
    [0x09B2, 0x09B2],
    [0x09B6, 0x09B9],
    [0x09BC, 0x09C4],
    [0x09C7, 0x09C8],
    [0x09CB, 0x09CE],
    [0x09D7, 0x09D7],
    [0x09DC, 0x09DD],
    [0x09DF, 0x09E3],
    [0x09E6, 0x09F1],
    [0x09FC, 0x09FC],
    [0x09FE, 0x09FE],
    [0x0A01, 0x0A03],
    [0x0A05, 0x0A0A],
    [0x0A0F, 0x0A10],
    [0x0A13, 0x0A28],
    [0x0A2A, 0x0A30],
    [0x0A32, 0x0A33],
    [0x0A35, 0x0A36],
    [0x0A38, 0x0A39],
    [0x0A3C, 0x0A3C],
    [0x0A3E, 0x0A42],
    [0x0A47, 0x0A48],
    [0x0A4B, 0x0A4D],
    [0x0A51, 0x0A51],
    [0x0A59, 0x0A5C],
    [0x0A5E, 0x0A5E],
    [0x0A66, 0x0A75],
    [0x0A81, 0x0A83],
    [0x0A85, 0x0A8D],
    [0x0A8F, 0x0A91],
    [0x0A93, 0x0AA8],
    [0x0AAA, 0x0AB0],
    [0x0AB2, 0x0AB3],
    [0x0AB5, 0x0AB9],
    [0x0ABC, 0x0AC5],
    [0x0AC7, 0x0AC9],
    [0x0ACB, 0x0ACD],
    [0x0AD0, 0x0AD0],
    [0x0AE0, 0x0AE3],
    [0x0AE6, 0x0AEF],
    [0x0AF9, 0x0AFF],
    [0x0B01, 0x0B03],
    [0x0B05, 0x0B0C],
    [0x0B0F, 0x0B10],
    [0x0B13, 0x0B28],
    [0x0B2A, 0x0B30],
    [0x0B32, 0x0B33],
    [0x0B35, 0x0B39],
    [0x0B3C, 0x0B44],
    [0x0B47, 0x0B48],
    [0x0B4B, 0x0B4D],
    [0x0B55, 0x0B57],
    [0x0B5C, 0x0B5D],
    [0x0B5F, 0x0B63],
    [0x0B66, 0x0B6F],
    [0x0B71, 0x0B71],
    [0x0B82, 0x0B83],
    [0x0B85, 0x0B8A],
    [0x0B8E, 0x0B90],
    [0x0B92, 0x0B95],
    [0x0B99, 0x0B9A],
    [0x0B9C, 0x0B9C],
    [0x0B9E, 0x0B9F],
    [0x0BA3, 0x0BA4],
    [0x0BA8, 0x0BAA],
    [0x0BAE, 0x0BB9],
    [0x0BBE, 0x0BC2],
    [0x0BC6, 0x0BC8],
    [0x0BCA, 0x0BCD],
    [0x0BD0, 0x0BD0],
    [0x0BD7, 0x0BD7],
    [0x0BE6, 0x0BEF],
    [0x0C00, 0x0C0C],
    [0x0C0E, 0x0C10],
    [0x0C12, 0x0C28],
    [0x0C2A, 0x0C39],
    [0x0C3C, 0x0C44],
    [0x0C46, 0x0C48],
    [0x0C4A, 0x0C4D],
    [0x0C55, 0x0C56],
    [0x0C58, 0x0C5A],
    [0x0C5D, 0x0C5D],
    [0x0C60, 0x0C63],
    [0x0C66, 0x0C6F],
    [0x0C80, 0x0C83],
    [0x0C85, 0x0C8C],
    [0x0C8E, 0x0C90],
    [0x0C92, 0x0CA8],
    [0x0CAA, 0x0CB3],
    [0x0CB5, 0x0CB9],
    [0x0CBC, 0x0CC4],
    [0x0CC6, 0x0CC8],
    [0x0CCA, 0x0CCD],
    [0x0CD5, 0x0CD6],
    [0x0CDD, 0x0CDE],
    [0x0CE0, 0x0CE3],
    [0x0CE6, 0x0CEF],
    [0x0CF1, 0x0CF3],
    [0x0D00, 0x0D0C],
    [0x0D0E, 0x0D10],
    [0x0D12, 0x0D44],
    [0x0D46, 0x0D48],
    [0x0D4A, 0x0D4E],
    [0x0D54, 0x0D57],
    [0x0D5F, 0x0D63],
    [0x0D66, 0x0D6F],
    [0x0D7A, 0x0D7F],
    [0x0D81, 0x0D83],
    [0x0D85, 0x0D96],
    [0x0D9A, 0x0DB1],
    [0x0DB3, 0x0DBB],
    [0x0DBD, 0x0DBD],
    [0x0DC0, 0x0DC6],
    [0x0DCA, 0x0DCA],
    [0x0DCF, 0x0DD4],
    [0x0DD6, 0x0DD6],
    [0x0DD8, 0x0DDF],
    [0x0DE6, 0x0DEF],
    [0x0DF2, 0x0DF3],
    [0x0E01, 0x0E3A],
    [0x0E40, 0x0E4E],
    [0x0E50, 0x0E59],
    [0x0E81, 0x0E82],
    [0x0E84, 0x0E84],
    [0x0E86, 0x0E8A],
    [0x0E8C, 0x0EA3],
    [0x0EA5, 0x0EA5],
    [0x0EA7, 0x0EBD],
    [0x0EC0, 0x0EC4],
    [0x0EC6, 0x0EC6],
    [0x0EC8, 0x0ECE],
    [0x0ED0, 0x0ED9],
    [0x0EDC, 0x0EDF],
    [0x0F00, 0x0F00],
    [0x0F18, 0x0F19],
    [0x0F20, 0x0F29],
    [0x0F35, 0x0F35],
    [0x0F37, 0x0F37],
    [0x0F39, 0x0F39],
    [0x0F3E, 0x0F47],
    [0x0F49, 0x0F6C],
    [0x0F71, 0x0F84],
    [0x0F86, 0x0F97],
    [0x0F99, 0x0FBC],
    [0x0FC6, 0x0FC6],
    [0x1000, 0x1049],
    [0x1050, 0x109D],
    [0x10A0, 0x10C5],
    [0x10C7, 0x10C7],
    [0x10CD, 0x10CD],
    [0x10D0, 0x10FA],
    [0x10FC, 0x115E],
    [0x1161, 0x1248],
    [0x124A, 0x124D],
    [0x1250, 0x1256],
    [0x1258, 0x1258],
    [0x125A, 0x125D],
    [0x1260, 0x1288],
    [0x128A, 0x128D],
    [0x1290, 0x12B0],
    [0x12B2, 0x12B5],
    [0x12B8, 0x12BE],
    [0x12C0, 0x12C0],
    [0x12C2, 0x12C5],
    [0x12C8, 0x12D6],
    [0x12D8, 0x1310],
    [0x1312, 0x1315],
    [0x1318, 0x135A],
    [0x135D, 0x135F],
    [0x1369, 0x1371],
    [0x1380, 0x138F],
    [0x13A0, 0x13F5],
    [0x13F8, 0x13FD],
    [0x1401, 0x166C],
    [0x166F, 0x167F],
    [0x1681, 0x169A],
    [0x16A0, 0x16EA],
    [0x16EE, 0x16F8],
    [0x1700, 0x1715],
    [0x171F, 0x1734],
    [0x1740, 0x1753],
    [0x1760, 0x176C],
    [0x176E, 0x1770],
    [0x1772, 0x1773],
    [0x1780, 0x17B3],
    [0x17B6, 0x17D3],
    [0x17D7, 0x17D7],
    [0x17DC, 0x17DD],
    [0x17E0, 0x17E9],
    [0x1810, 0x1819],
    [0x1820, 0x1878],
    [0x1880, 0x18AA],
    [0x18B0, 0x18F5],
    [0x1900, 0x191E],
    [0x1920, 0x192B],
    [0x1930, 0x193B],
    [0x1946, 0x196D],
    [0x1970, 0x1974],
    [0x1980, 0x19AB],
    [0x19B0, 0x19C9],
    [0x19D0, 0x19DA],
    [0x1A00, 0x1A1B],
    [0x1A20, 0x1A5E],
    [0x1A60, 0x1A7C],
    [0x1A7F, 0x1A89],
    [0x1A90, 0x1A99],
    [0x1AA7, 0x1AA7],
    [0x1AB0, 0x1ABD],
    [0x1ABF, 0x1ACE],
    [0x1B00, 0x1B4C],
    [0x1B50, 0x1B59],
    [0x1B6B, 0x1B73],
    [0x1B80, 0x1BF3],
    [0x1C00, 0x1C37],
    [0x1C40, 0x1C49],
    [0x1C4D, 0x1C7D],
    [0x1C80, 0x1C88],
    [0x1C90, 0x1CBA],
    [0x1CBD, 0x1CBF],
    [0x1CD0, 0x1CD2],
    [0x1CD4, 0x1CFA],
    [0x1D00, 0x1F15],
    [0x1F18, 0x1F1D],
    [0x1F20, 0x1F45],
    [0x1F48, 0x1F4D],
    [0x1F50, 0x1F57],
    [0x1F59, 0x1F59],
    [0x1F5B, 0x1F5B],
    [0x1F5D, 0x1F5D],
    [0x1F5F, 0x1F7D],
    [0x1F80, 0x1FB4],
    [0x1FB6, 0x1FBC],
    [0x1FBE, 0x1FBE],
    [0x1FC2, 0x1FC4],
    [0x1FC6, 0x1FCC],
    [0x1FD0, 0x1FD3],
    [0x1FD6, 0x1FDB],
    [0x1FE0, 0x1FEC],
    [0x1FF2, 0x1FF4],
    [0x1FF6, 0x1FFC],
    [0x203F, 0x2040],
    [0x2054, 0x2054],
    [0x2071, 0x2071],
    [0x207F, 0x207F],
    [0x2090, 0x209C],
    [0x20D0, 0x20DC],
    [0x20E1, 0x20E1],
    [0x20E5, 0x20F0],
    [0x2102, 0x2102],
    [0x2107, 0x2107],
    [0x210A, 0x2113],
    [0x2115, 0x2115],
    [0x2118, 0x211D],
    [0x2124, 0x2124],
    [0x2126, 0x2126],
    [0x2128, 0x2128],
    [0x212A, 0x2139],
    [0x213C, 0x213F],
    [0x2145, 0x2149],
    [0x214E, 0x214E],
    [0x2160, 0x2188],
    [0x2C00, 0x2CE4],
    [0x2CEB, 0x2CF3],
    [0x2D00, 0x2D25],
    [0x2D27, 0x2D27],
    [0x2D2D, 0x2D2D],
    [0x2D30, 0x2D67],
    [0x2D6F, 0x2D6F],
    [0x2D7F, 0x2D96],
    [0x2DA0, 0x2DA6],
    [0x2DA8, 0x2DAE],
    [0x2DB0, 0x2DB6],
    [0x2DB8, 0x2DBE],
    [0x2DC0, 0x2DC6],
    [0x2DC8, 0x2DCE],
    [0x2DD0, 0x2DD6],
    [0x2DD8, 0x2DDE],
    [0x2DE0, 0x2DFF],
    [0x3005, 0x3007],
    [0x3021, 0x302F],
    [0x3031, 0x3035],
    [0x3038, 0x303C],
    [0x3041, 0x3096],
    [0x3099, 0x309A],
    [0x309D, 0x309F],
    [0x30A1, 0x30FF],
    [0x3105, 0x312F],
    [0x3131, 0x3163],
    [0x3165, 0x318E],
    [0x31A0, 0x31BF],
    [0x31F0, 0x31FF],
    [0x3400, 0x4DBF],
    [0x4E00, 0xA48C],
    [0xA4D0, 0xA4FD],
    [0xA500, 0xA60C],
    [0xA610, 0xA62B],
    [0xA640, 0xA66F],
    [0xA674, 0xA67D],
    [0xA67F, 0xA6F1],
    [0xA717, 0xA71F],
    [0xA722, 0xA788],
    [0xA78B, 0xA7CA],
    [0xA7D0, 0xA7D1],
    [0xA7D3, 0xA7D3],
    [0xA7D5, 0xA7D9],
    [0xA7F2, 0xA827],
    [0xA82C, 0xA82C],
    [0xA840, 0xA873],
    [0xA880, 0xA8C5],
    [0xA8D0, 0xA8D9],
    [0xA8E0, 0xA8F7],
    [0xA8FB, 0xA8FB],
    [0xA8FD, 0xA92D],
    [0xA930, 0xA953],
    [0xA960, 0xA97C],
    [0xA980, 0xA9C0],
    [0xA9CF, 0xA9D9],
    [0xA9E0, 0xA9FE],
    [0xAA00, 0xAA36],
    [0xAA40, 0xAA4D],
    [0xAA50, 0xAA59],
    [0xAA60, 0xAA76],
    [0xAA7A, 0xAAC2],
    [0xAADB, 0xAADD],
    [0xAAE0, 0xAAEF],
    [0xAAF2, 0xAAF6],
    [0xAB01, 0xAB06],
    [0xAB09, 0xAB0E],
    [0xAB11, 0xAB16],
    [0xAB20, 0xAB26],
    [0xAB28, 0xAB2E],
    [0xAB30, 0xAB5A],
    [0xAB5C, 0xAB69],
    [0xAB70, 0xABEA],
    [0xABEC, 0xABED],
    [0xABF0, 0xABF9],
    [0xAC00, 0xD7A3],
    [0xD7B0, 0xD7C6],
    [0xD7CB, 0xD7FB],
    [0xF900, 0xFA6D],
    [0xFA70, 0xFAD9],
    [0xFB00, 0xFB06],
    [0xFB13, 0xFB17],
    [0xFB1D, 0xFB28],
    [0xFB2A, 0xFB36],
    [0xFB38, 0xFB3C],
    [0xFB3E, 0xFB3E],
    [0xFB40, 0xFB41],
    [0xFB43, 0xFB44],
    [0xFB46, 0xFBB1],
    [0xFBD3, 0xFC5D],
    [0xFC64, 0xFD3D],
    [0xFD50, 0xFD8F],
    [0xFD92, 0xFDC7],
    [0xFDF0, 0xFDF9],
    [0xFE20, 0xFE2F],
    [0xFE33, 0xFE34],
    [0xFE4D, 0xFE4F],
    [0xFE71, 0xFE71],
    [0xFE73, 0xFE73],
    [0xFE77, 0xFE77],
    [0xFE79, 0xFE79],
    [0xFE7B, 0xFE7B],
    [0xFE7D, 0xFE7D],
    [0xFE7F, 0xFEFC],
    [0xFF10, 0xFF19],
    [0xFF21, 0xFF3A],
    [0xFF3F, 0xFF3F],
    [0xFF41, 0xFF5A],
    [0xFF65, 0xFF9F],
    [0xFFA1, 0xFFBE],
    [0xFFC2, 0xFFC7],
    [0xFFCA, 0xFFCF],
    [0xFFD2, 0xFFD7],
    [0xFFDA, 0xFFDC],
    [0x10000, 0x1000B],
    [0x1000D, 0x10026],
    [0x10028, 0x1003A],
    [0x1003C, 0x1003D],
    [0x1003F, 0x1004D],
    [0x10050, 0x1005D],
    [0x10080, 0x100FA],
    [0x10140, 0x10174],
    [0x101FD, 0x101FD],
    [0x10280, 0x1029C],
    [0x102A0, 0x102D0],
    [0x102E0, 0x102E0],
    [0x10300, 0x1031F],
    [0x1032D, 0x1034A],
    [0x10350, 0x1037A],
    [0x10380, 0x1039D],
    [0x103A0, 0x103C3],
    [0x103C8, 0x103CF],
    [0x103D1, 0x103D5],
    [0x10400, 0x1049D],
    [0x104A0, 0x104A9],
    [0x104B0, 0x104D3],
    [0x104D8, 0x104FB],
    [0x10500, 0x10527],
    [0x10530, 0x10563],
    [0x10570, 0x1057A],
    [0x1057C, 0x1058A],
    [0x1058C, 0x10592],
    [0x10594, 0x10595],
    [0x10597, 0x105A1],
    [0x105A3, 0x105B1],
    [0x105B3, 0x105B9],
    [0x105BB, 0x105BC],
    [0x10600, 0x10736],
    [0x10740, 0x10755],
    [0x10760, 0x10767],
    [0x10780, 0x10785],
    [0x10787, 0x107B0],
    [0x107B2, 0x107BA],
    [0x10800, 0x10805],
    [0x10808, 0x10808],
    [0x1080A, 0x10835],
    [0x10837, 0x10838],
    [0x1083C, 0x1083C],
    [0x1083F, 0x10855],
    [0x10860, 0x10876],
    [0x10880, 0x1089E],
    [0x108E0, 0x108F2],
    [0x108F4, 0x108F5],
    [0x10900, 0x10915],
    [0x10920, 0x10939],
    [0x10980, 0x109B7],
    [0x109BE, 0x109BF],
    [0x10A00, 0x10A03],
    [0x10A05, 0x10A06],
    [0x10A0C, 0x10A13],
    [0x10A15, 0x10A17],
    [0x10A19, 0x10A35],
    [0x10A38, 0x10A3A],
    [0x10A3F, 0x10A3F],
    [0x10A60, 0x10A7C],
    [0x10A80, 0x10A9C],
    [0x10AC0, 0x10AC7],
    [0x10AC9, 0x10AE6],
    [0x10B00, 0x10B35],
    [0x10B40, 0x10B55],
    [0x10B60, 0x10B72],
    [0x10B80, 0x10B91],
    [0x10C00, 0x10C48],
    [0x10C80, 0x10CB2],
    [0x10CC0, 0x10CF2],
    [0x10D00, 0x10D27],
    [0x10D30, 0x10D39],
    [0x10E80, 0x10EA9],
    [0x10EAB, 0x10EAC],
    [0x10EB0, 0x10EB1],
    [0x10EFD, 0x10F1C],
    [0x10F27, 0x10F27],
    [0x10F30, 0x10F50],
    [0x10F70, 0x10F85],
    [0x10FB0, 0x10FC4],
    [0x10FE0, 0x10FF6],
    [0x11000, 0x11046],
    [0x11066, 0x11075],
    [0x1107F, 0x110BA],
    [0x110C2, 0x110C2],
    [0x110D0, 0x110E8],
    [0x110F0, 0x110F9],
    [0x11100, 0x11134],
    [0x11136, 0x1113F],
    [0x11144, 0x11147],
    [0x11150, 0x11173],
    [0x11176, 0x11176],
    [0x11180, 0x111C4],
    [0x111C9, 0x111CC],
    [0x111CE, 0x111DA],
    [0x111DC, 0x111DC],
    [0x11200, 0x11211],
    [0x11213, 0x11237],
    [0x1123E, 0x11241],
    [0x11280, 0x11286],
    [0x11288, 0x11288],
    [0x1128A, 0x1128D],
    [0x1128F, 0x1129D],
    [0x1129F, 0x112A8],
    [0x112B0, 0x112EA],
    [0x112F0, 0x112F9],
    [0x11300, 0x11303],
    [0x11305, 0x1130C],
    [0x1130F, 0x11310],
    [0x11313, 0x11328],
    [0x1132A, 0x11330],
    [0x11332, 0x11333],
    [0x11335, 0x11339],
    [0x1133B, 0x11344],
    [0x11347, 0x11348],
    [0x1134B, 0x1134D],
    [0x11350, 0x11350],
    [0x11357, 0x11357],
    [0x1135D, 0x11363],
    [0x11366, 0x1136C],
    [0x11370, 0x11374],
    [0x11400, 0x1144A],
    [0x11450, 0x11459],
    [0x1145E, 0x11461],
    [0x11480, 0x114C5],
    [0x114C7, 0x114C7],
    [0x114D0, 0x114D9],
    [0x11580, 0x115B5],
    [0x115B8, 0x115C0],
    [0x115D8, 0x115DD],
    [0x11600, 0x11640],
    [0x11644, 0x11644],
    [0x11650, 0x11659],
    [0x11680, 0x116B8],
    [0x116C0, 0x116C9],
    [0x11700, 0x1171A],
    [0x1171D, 0x1172B],
    [0x11730, 0x11739],
    [0x11740, 0x11746],
    [0x11800, 0x1183A],
    [0x118A0, 0x118E9],
    [0x118FF, 0x11906],
    [0x11909, 0x11909],
    [0x1190C, 0x11913],
    [0x11915, 0x11916],
    [0x11918, 0x11935],
    [0x11937, 0x11938],
    [0x1193B, 0x11943],
    [0x11950, 0x11959],
    [0x119A0, 0x119A7],
    [0x119AA, 0x119D7],
    [0x119DA, 0x119E1],
    [0x119E3, 0x119E4],
    [0x11A00, 0x11A3E],
    [0x11A47, 0x11A47],
    [0x11A50, 0x11A99],
    [0x11A9D, 0x11A9D],
    [0x11AB0, 0x11AF8],
    [0x11C00, 0x11C08],
    [0x11C0A, 0x11C36],
    [0x11C38, 0x11C40],
    [0x11C50, 0x11C59],
    [0x11C72, 0x11C8F],
    [0x11C92, 0x11CA7],
    [0x11CA9, 0x11CB6],
    [0x11D00, 0x11D06],
    [0x11D08, 0x11D09],
    [0x11D0B, 0x11D36],
    [0x11D3A, 0x11D3A],
    [0x11D3C, 0x11D3D],
    [0x11D3F, 0x11D47],
    [0x11D50, 0x11D59],
    [0x11D60, 0x11D65],
    [0x11D67, 0x11D68],
    [0x11D6A, 0x11D8E],
    [0x11D90, 0x11D91],
    [0x11D93, 0x11D98],
    [0x11DA0, 0x11DA9],
    [0x11EE0, 0x11EF6],
    [0x11F00, 0x11F10],
    [0x11F12, 0x11F3A],
    [0x11F3E, 0x11F42],
    [0x11F50, 0x11F59],
    [0x11FB0, 0x11FB0],
    [0x12000, 0x12399],
    [0x12400, 0x1246E],
    [0x12480, 0x12543],
    [0x12F90, 0x12FF0],
    [0x13000, 0x1342F],
    [0x13440, 0x13455],
    [0x14400, 0x14646],
    [0x16800, 0x16A38],
    [0x16A40, 0x16A5E],
    [0x16A60, 0x16A69],
    [0x16A70, 0x16ABE],
    [0x16AC0, 0x16AC9],
    [0x16AD0, 0x16AED],
    [0x16AF0, 0x16AF4],
    [0x16B00, 0x16B36],
    [0x16B40, 0x16B43],
    [0x16B50, 0x16B59],
    [0x16B63, 0x16B77],
    [0x16B7D, 0x16B8F],
    [0x16E40, 0x16E7F],
    [0x16F00, 0x16F4A],
    [0x16F4F, 0x16F87],
    [0x16F8F, 0x16F9F],
    [0x16FE0, 0x16FE1],
    [0x16FE3, 0x16FE4],
    [0x16FF0, 0x16FF1],
    [0x17000, 0x187F7],
    [0x18800, 0x18CD5],
    [0x18D00, 0x18D08],
    [0x1AFF0, 0x1AFF3],
    [0x1AFF5, 0x1AFFB],
    [0x1AFFD, 0x1AFFE],
    [0x1B000, 0x1B122],
    [0x1B132, 0x1B132],
    [0x1B150, 0x1B152],
    [0x1B155, 0x1B155],
    [0x1B164, 0x1B167],
    [0x1B170, 0x1B2FB],
    [0x1BC00, 0x1BC6A],
    [0x1BC70, 0x1BC7C],
    [0x1BC80, 0x1BC88],
    [0x1BC90, 0x1BC99],
    [0x1BC9D, 0x1BC9E],
    [0x1CF00, 0x1CF2D],
    [0x1CF30, 0x1CF46],
    [0x1D165, 0x1D169],
    [0x1D16D, 0x1D172],
    [0x1D17B, 0x1D182],
    [0x1D185, 0x1D18B],
    [0x1D1AA, 0x1D1AD],
    [0x1D242, 0x1D244],
    [0x1D400, 0x1D454],
    [0x1D456, 0x1D49C],
    [0x1D49E, 0x1D49F],
    [0x1D4A2, 0x1D4A2],
    [0x1D4A5, 0x1D4A6],
    [0x1D4A9, 0x1D4AC],
    [0x1D4AE, 0x1D4B9],
    [0x1D4BB, 0x1D4BB],
    [0x1D4BD, 0x1D4C3],
    [0x1D4C5, 0x1D505],
    [0x1D507, 0x1D50A],
    [0x1D50D, 0x1D514],
    [0x1D516, 0x1D51C],
    [0x1D51E, 0x1D539],
    [0x1D53B, 0x1D53E],
    [0x1D540, 0x1D544],
    [0x1D546, 0x1D546],
    [0x1D54A, 0x1D550],
    [0x1D552, 0x1D6A5],
    [0x1D6A8, 0x1D6C0],
    [0x1D6C2, 0x1D6DA],
    [0x1D6DC, 0x1D6FA],
    [0x1D6FC, 0x1D714],
    [0x1D716, 0x1D734],
    [0x1D736, 0x1D74E],
    [0x1D750, 0x1D76E],
    [0x1D770, 0x1D788],
    [0x1D78A, 0x1D7A8],
    [0x1D7AA, 0x1D7C2],
    [0x1D7C4, 0x1D7CB],
    [0x1D7CE, 0x1D7FF],
    [0x1DA00, 0x1DA36],
    [0x1DA3B, 0x1DA6C],
    [0x1DA75, 0x1DA75],
    [0x1DA84, 0x1DA84],
    [0x1DA9B, 0x1DA9F],
    [0x1DAA1, 0x1DAAF],
    [0x1DF00, 0x1DF1E],
    [0x1DF25, 0x1DF2A],
    [0x1E000, 0x1E006],
    [0x1E008, 0x1E018],
    [0x1E01B, 0x1E021],
    [0x1E023, 0x1E024],
    [0x1E026, 0x1E02A],
    [0x1E030, 0x1E06D],
    [0x1E08F, 0x1E08F],
    [0x1E100, 0x1E12C],
    [0x1E130, 0x1E13D],
    [0x1E140, 0x1E149],
    [0x1E14E, 0x1E14E],
    [0x1E290, 0x1E2AE],
    [0x1E2C0, 0x1E2F9],
    [0x1E4D0, 0x1E4F9],
    [0x1E7E0, 0x1E7E6],
    [0x1E7E8, 0x1E7EB],
    [0x1E7ED, 0x1E7EE],
    [0x1E7F0, 0x1E7FE],
    [0x1E800, 0x1E8C4],
    [0x1E8D0, 0x1E8D6],
    [0x1E900, 0x1E94B],
    [0x1E950, 0x1E959],
    [0x1EE00, 0x1EE03],
    [0x1EE05, 0x1EE1F],
    [0x1EE21, 0x1EE22],
    [0x1EE24, 0x1EE24],
    [0x1EE27, 0x1EE27],
    [0x1EE29, 0x1EE32],
    [0x1EE34, 0x1EE37],
    [0x1EE39, 0x1EE39],
    [0x1EE3B, 0x1EE3B],
    [0x1EE42, 0x1EE42],
    [0x1EE47, 0x1EE47],
    [0x1EE49, 0x1EE49],
    [0x1EE4B, 0x1EE4B],
    [0x1EE4D, 0x1EE4F],
    [0x1EE51, 0x1EE52],
    [0x1EE54, 0x1EE54],
    [0x1EE57, 0x1EE57],
    [0x1EE59, 0x1EE59],
    [0x1EE5B, 0x1EE5B],
    [0x1EE5D, 0x1EE5D],
    [0x1EE5F, 0x1EE5F],
    [0x1EE61, 0x1EE62],
    [0x1EE64, 0x1EE64],
    [0x1EE67, 0x1EE6A],
    [0x1EE6C, 0x1EE72],
    [0x1EE74, 0x1EE77],
    [0x1EE79, 0x1EE7C],
    [0x1EE7E, 0x1EE7E],
    [0x1EE80, 0x1EE89],
    [0x1EE8B, 0x1EE9B],
    [0x1EEA1, 0x1EEA3],
    [0x1EEA5, 0x1EEA9],
    [0x1EEAB, 0x1EEBB],
    [0x1FBF0, 0x1FBF9],
    [0x20000, 0x2A6DF],
    [0x2A700, 0x2B739],
    [0x2B740, 0x2B81D],
    [0x2B820, 0x2CEA1],
    [0x2CEB0, 0x2EBE0],
    [0x2EBF0, 0x2EE5D],
    [0x2F800, 0x2FA1D],
    [0x30000, 0x3134A],
    [0x31350, 0x323AF],);

# Binary-search the frozen XID_Continue range table.
# Caller is responsible for the ASCII fast path; this is the slow path
# for non-ASCII codepoints in identifier-character checks.
sub _is_xid_continue {
    my ($cp) = @_;
    my $lo = 0;
    my $hi = $#XID_CONTINUE_RANGES;
    while ($lo <= $hi) {
        my $mid = ($lo + $hi) >> 1;
        my $r = $XID_CONTINUE_RANGES[$mid];
        if ($cp < $r->[0])    { $hi = $mid - 1 }
        elsif ($cp > $r->[1]) { $lo = $mid + 1 }
        else                    { return 1 }
    }
    return 0;
}

sub new_table {
    require Tie::IxHash;
    tie my %h, 'Tie::IxHash';
    return \%h;
}

# SPEC §"Unordered tables". Plain hashref blessed into DMS::Parser::UnorderedTable.
# Used by parse_table_block / parse_flow_table / parse_list_item_value when
# the parser was constructed with ignore_order=true. Iteration order over
# the resulting table is arbitrary (Perl hash randomization).
sub new_unordered_table {
    my %h;
    return bless \%h, 'DMS::Parser::UnorderedTable';
}

# Like new_table, but returns a plain (non-tied) hashref plus an
# external "insertion-order keys" arrayref. Used in the lite/encoder
# fast path where we don't need the round-trip Document tree — just
# enough structure for JSON emission. The encoder special-cases this
# shape (HASH refs accompanied by an "$order" arrayref).
#
# We tag the plain hashref with a hidden key holding the keys arrayref
# so it round-trips through `$t->{$k} = $v` access patterns: the
# encoder extracts the order list from `$t->{"\0_keys"}` if present and
# falls back to `keys %$t` otherwise.
our $ORDER_KEY = "\0_keys";
sub new_ordered_table {
    return { $ORDER_KEY => [] };
}

# Per-indent compiled bulk regex cache for parse_table_block's fast
# path. Common indent levels (0, 2, 4, 6, ...) compile once globally;
# subsequent encounters reuse the qr// from this cache instead of
# recompiling per parse_table_block call.
our %BULK_RE_CACHE;

sub _err {
    my ($self, $msg) = @_;
    return "$self->{line}:" . ($self->{pos} - $self->{line_start} + 1) . ": $msg\n";
}

sub _err_at {
    my ($self, $line, $line_start, $pos, $msg) = @_;
    my $col = $pos - $line_start + 1;
    return "$line:$col: $msg\n";
}

sub _die_at {
    my ($self, $line, $line_start, $pos, $msg) = @_;
    die "$line:" . ($pos - $line_start + 1) . ": $msg\n";
}

sub _die {
    my ($self, $msg) = @_;
    die _err($self, $msg);
}

# SPEC §Decode/Encode (v0.14): canonical entry point. Returns the body
# only — meta and comments are dropped. Use decode_document() to keep
# them.
sub decode {
    my ($src) = @_;
    my $doc = decode_document($src);
    return $doc->{body};
}

# Deprecated alias for decode(). Removed in the next release.
# SPEC §Decode/Encode — Migration from the parse/to_dms era.
{ my $warned;
  sub parse {
      unless ($warned++) {
          Carp::carp(
              'DMS::Parser::parse() is deprecated; use decode() instead. '
            . 'SPEC v0.14 renamed parse() to decode().');
      }
      goto &decode;
  }
}

# SPEC §Parsing modes — full and lite. Lite-mode equivalents return
# a Document with empty comments + original_forms.
sub decode_lite {
    my ($src) = @_;
    return decode_lite_document($src)->{body};
}

# Deprecated alias for decode_lite(). Removed in the next release.
{ my $warned;
  sub parse_lite {
      unless ($warned++) {
          Carp::carp(
              'DMS::Parser::parse_lite() is deprecated; use decode_lite() instead. '
            . 'SPEC v0.14 renamed parse_lite() to decode_lite().');
      }
      goto &decode_lite;
  }
}

sub decode_lite_document {
    my ($src) = @_;
    # Fast path: try the iterative mega-regex tokenizer for the simple
    # subset (bareword keys, simple scalar values, nested-table headers,
    # blank lines, single-line `#` / `//` comments, ASCII-only). Returns
    # undef on anything it can't handle; we fall back to the full
    # recursive-descent parser below. The fast path avoids the
    # parse_table_block recursion and the parse_kvpair / _skip_trivia
    # method-dispatch frames — pure-Perl method calls are the main
    # cost on flat configs (kube values.yaml-shaped).
    my $fast = _parse_lite_document_fast(\$src);
    return $fast if defined $fast;
    return _parse_document_with_mode($src, 1);
}

# Iterative mega-regex tokenizer + manual stack assembly for the lite
# subset. Returns a Document hashref { meta, body, comments,
# original_forms } on success, or undef on any pattern the fast path
# can't handle (front matter, heredocs, list items, escaped strings,
# block comments, complex-key flow forms, non-ASCII strings).
# Caller's $src isn't modified; we do a pos() scan via a scalar ref.
sub _parse_lite_document_fast {
    my ($src_ref) = @_;
    my $len = length($$src_ref);

    # Pre-flight rejection: a single regex over the whole src checks
    # for any opener of a construct the fast path doesn't handle. If
    # any are present, return undef immediately so the slow parser
    # gets the (correct) full-spec implementation. This costs one
    # linear scan but it's bounded by the C regex engine and faster
    # than discovering mid-parse that we can't handle something. The
    # negative lookaheads for `(?!##)` exclude `### LABEL` block
    # comment openers. We deliberately allow `\u`/`\U` Unicode escapes
    # but reject other backslash escapes (would need decoding).
    return undef if $$src_ref =~ /"""|'''/;                      # heredocs
    return undef if $$src_ref =~ /^[ \t]*\+/m;                   # list items / front matter
    return undef if $$src_ref =~ /^[ \t]*###/m;                  # block comment opener
    # Note: we don't pre-reject `/*` because real configs sometimes
    # have it inside string literals (e.g., `path: "/etc/foo/*.tmpl"`).
    # The mega-regex handles strings as a unit so `/*` is consumed
    # inside the string capture; the inner loop will only fail on a
    # `/*` that appears at line-start as an actual block comment, in
    # which case it correctly bails to the slow parser.
    # Backslash escapes ARE handled in the string regex below — the
    # decode pass after match handles \", \\, \n, \r, \t, \b, \f, \uXXXX,
    # \UXXXXXXXX. Anything else with `\` is still rejected.
    # Quoted keys, inline tables/lists with content, dates, hex/oct/bin
    # numbers — all opt out by being matched as "didn't match the
    # mega-regex" inside the loop; the loop returns undef on the
    # first non-match.

    # Manual stack of containers, with the indent at which their
    # children live. The root has child_indent 0. When a header
    # (`key:\n`) arrives, we push the new child table with
    # child_indent=undef ("TBD — set by first child"). The pop rule
    # is "while top's child_indent > current indent, pop"; this
    # closes nested blocks as the indent decreases.
    my $root = { $ORDER_KEY => [] };
    my @stack = ({ c => $root, ci => 0 });

    pos($$src_ref) = 0;
    LINE: while (pos($$src_ref) < $len) {
        # Blank line — most common after kvpairs.
        if ($$src_ref =~ /\G[ \t]*\r?\n/gc) { next LINE; }
        # Single-line `#` or `//` comment (block forms `###` / `/*`
        # already pre-rejected).
        if ($$src_ref =~ /\G[ \t]*(?:#|\/\/)[^\n\r]*\r?\n/gc) { next LINE; }

        # Mega-match: kvpair with simple value OR nested-block header.
        # Group layout (capturing only — non-capturing alternations
        # don't shift indices):
        #   $1 = indent (spaces)
        #   $2 = bareword key
        #   $3 = positive integer
        #   $4 = negative integer
        #   $5 = bool ('true'/'false')
        #   $6 = basic-string content (escapes allowed; decoded after)
        #   $7 = empty list / empty table literal ('[]' or '{}')
        #   $8 = decimal float (no exponent)
        #   $9 = flow-list-of-simple-values content (between [ and ],
        #        no nested brackets, no embedded newlines)
        #   $10 = flow-table-of-simple-kvpairs content
        #   $11 = trailing '\r?\n' for the no-value (header) form
        if ($$src_ref =~ /\G([ ]*)([A-Za-z_][A-Za-z0-9_-]*):(?:[ ](?:(0|[1-9][0-9]{0,17})|(-[1-9][0-9]{0,17})|(true|false)|"((?:[\x20\x21\x23-\x5b\x5d-\x7e]|\\(?:["\\nrtbf]|u[0-9A-Fa-f]{4}|U[0-9A-Fa-f]{8}))*)"|(\[\]|\{\})|(-?(?:0|[1-9][0-9]*)\.[0-9]+)|\[([^\[\]\n\r]+)\]|\{([^\{\}\n\r]+)\})\r?\n|(\r?\n))/gc) {
            my $ind = length($1);
            my $key = $2;
            # Pop closed levels (top's children no longer reachable).
            while (@stack > 1 && defined($stack[-1]{ci}) && $stack[-1]{ci} > $ind) {
                pop @stack;
            }
            # First child of a header? Its indent fixes the parent's
            # child_indent.
            if (!defined $stack[-1]{ci}) {
                # The new indent must be strictly greater than the
                # header's parent's child_indent (i.e., we descended).
                if (@stack >= 2 && $stack[-2]{ci} >= $ind) { return undef; }
                $stack[-1]{ci} = $ind;
            }
            # Indent must match the current container's expected level.
            return undef if $stack[-1]{ci} != $ind;
            my $container = $stack[-1]{c};
            return undef if exists $container->{$key};  # duplicate key

            if (defined $11) {
                # Nested-block header: child is a table (the fast path
                # doesn't handle child-as-list; pre-flight rejects any
                # `+` so this is safe).
                my $child = { $ORDER_KEY => [] };
                push @{$container->{$ORDER_KEY}}, $key;
                $container->{$key} = $child;
                push @stack, { c => $child, ci => undef };
            } else {
                my $val;
                if    (defined $3) { my $iv = 0+$3; $val = bless \$iv, 'DMS::Parser::Integer'; }
                elsif (defined $4) { my $iv = 0+$4; $val = bless \$iv, 'DMS::Parser::Integer'; }
                elsif (defined $5) { my $bv = $5 eq 'true' ? 1 : 0; $val = bless \$bv, 'DMS::Parser::Bool'; }
                elsif (defined $6) {
                    $val = $6;
                    # Decode escapes only if any backslash present (the
                    # common case is clean ASCII strings — skip the
                    # substitution then).
                    if (index($val, '\\') >= 0) {
                        $val =~ s{\\(["\\nrtbf])}{
                            $1 eq 'n' ? "\n"
                          : $1 eq 't' ? "\t"
                          : $1 eq 'r' ? "\r"
                          : $1 eq 'b' ? "\b"
                          : $1 eq 'f' ? "\f"
                          : $1
                        }ge;
                        $val =~ s{\\u([0-9A-Fa-f]{4})}{chr(hex($1))}ge;
                        $val =~ s{\\U([0-9A-Fa-f]{8})}{chr(hex($1))}ge;
                    }
                }
                elsif (defined $7) { $val = $7 eq '[]' ? [] : { $ORDER_KEY => [] }; }
                elsif (defined $8) { my $fv = 0+$8; $val = bless \$fv, 'DMS::Parser::Float'; }
                elsif (defined $9) {
                    # Flow-list with content (no nested brackets / newlines).
                    # Try to parse inner content as a comma-separated
                    # list of simple values. Bail to slow path if any
                    # value isn't a clean leaf.
                    my $inner = $9;
                    my @items;
                    # Split by ',' but allow whitespace.
                    for my $raw (split /\s*,\s*/, $inner) {
                        next if $raw eq '';  # trailing comma → empty trailing field
                        if ($raw =~ /^(0|[1-9][0-9]{0,17})$/) {
                            my $iv = 0+$raw; push @items, bless \$iv, 'DMS::Parser::Integer';
                        } elsif ($raw =~ /^-[1-9][0-9]{0,17}$/) {
                            my $iv = 0+$raw; push @items, bless \$iv, 'DMS::Parser::Integer';
                        } elsif ($raw eq 'true') {
                            my $bv = 1; push @items, bless \$bv, 'DMS::Parser::Bool';
                        } elsif ($raw eq 'false') {
                            my $bv = 0; push @items, bless \$bv, 'DMS::Parser::Bool';
                        } elsif ($raw =~ /^"([\x20\x21\x23-\x5b\x5d-\x7e]*)"$/) {
                            push @items, $1;  # ASCII-clean string, no escapes
                        } else {
                            return undef;  # complex flow content — fall back
                        }
                    }
                    $val = \@items;
                }
                else {
                    # $10: flow-table — fall back for now (rare; would
                    # need split on `,` and inner `key: value` parsing).
                    return undef;
                }
                push @{$container->{$ORDER_KEY}}, $key;
                $container->{$key} = $val;
            }
            next LINE;
        }

        # Anything else: bail out, slow parser owns it.
        return undef;
    }

    # Successful walk — return Document shape. comments/original_forms
    # are empty by definition (we rejected anything that could carry
    # them).
    return {
        meta => undef,
        body => $root,
        comments => [],
        original_forms => [],
    };
}

# SPEC §"Unordered tables" — opt-in. Body tables are produced as
# DMS::Parser::UnorderedTable (plain Perl hashes, no insertion-order tracking).
# Front matter remains ordered (per spec — meta is small and used by
# tooling that benefits from stable order). Documents from these entry
# points cannot round-trip via `encode` (full mode); use `encode_lite`
# instead. `decode_document_unordered` is full-mode (comments AST +
# original_forms still recorded); `decode_lite_document_unordered` is
# the (unordered, lite) combo — fastest read-only path.
sub decode_document_unordered {
    my ($src) = @_;
    return _parse_document_with_mode($src, 0, 1);
}
sub decode_lite_document_unordered {
    my ($src) = @_;
    return _parse_document_with_mode($src, 1, 1);
}

# Deprecated aliases. Removed in the next release.
{ my $warned;
  sub parse_document_unordered {
      unless ($warned++) {
          Carp::carp(
              'DMS::Parser::parse_document_unordered() is deprecated; '
            . 'use decode_document_unordered() instead. '
            . 'SPEC v0.14 renamed parse_*() to decode_*().');
      }
      goto &decode_document_unordered;
  }
}
{ my $warned;
  sub parse_lite_document_unordered {
      unless ($warned++) {
          Carp::carp(
              'DMS::Parser::parse_lite_document_unordered() is deprecated; '
            . 'use decode_lite_document_unordered() instead. '
            . 'SPEC v0.14 renamed parse_*() to decode_*().');
      }
      goto &decode_lite_document_unordered;
  }
}

# Re-emit a parsed Document as DMS source. See SPEC §encode.
sub encode {
    my ($doc) = @_;
    require DMS::Parser::Emitter;
    return DMS::Parser::Emitter::encode($doc);
}

# Lite-mode emit: canonical DMS source — no comments, decimal integers,
# basic-quoted strings — ignoring any comments / original_forms in $doc.
# `decode(encode_lite($doc))` is data-equivalent to $doc; round-trip of
# comment + literal-form is *not* preserved. SPEC §encode.
sub encode_lite {
    my ($doc) = @_;
    require DMS::Parser::Emitter;
    return DMS::Parser::Emitter::encode_lite($doc);
}

# Deprecated aliases for encode/encode_lite. Removed in the next release.
{ my $warned;
  sub to_dms {
      unless ($warned++) {
          Carp::carp(
              'DMS::Parser::to_dms() is deprecated; use encode() instead. '
            . 'SPEC v0.14 renamed to_dms() to encode().');
      }
      goto &encode;
  }
}
{ my $warned;
  sub to_dms_lite {
      unless ($warned++) {
          Carp::carp(
              'DMS::Parser::to_dms_lite() is deprecated; use encode_lite() instead. '
            . 'SPEC v0.14 renamed to_dms_lite() to encode_lite().');
      }
      goto &encode_lite;
  }
}

sub decode_document {
    my ($src) = @_;
    return _parse_document_with_mode($src, 0, 0);
}

# Deprecated alias for decode_document(). Removed in the next release.
{ my $warned;
  sub parse_document {
      unless ($warned++) {
          Carp::carp(
              'DMS::Parser::parse_document() is deprecated; use decode_document() instead. '
            . 'SPEC v0.14 renamed parse_document() to decode_document().');
      }
      goto &decode_document;
  }
}

# SPEC §"UTF-8 only": reject any non-strict UTF-8 byte sequence —
# overlongs, lone continuation bytes, 5/6-byte forms, codepoints above
# U+10FFFF, and surrogates encoded as 3-byte UTF-8. Perl's built-in
# `utf8::decode` is too lax (it accepts the legacy "extended UTF-8"
# encoding for code points up to 2^31), so we walk the bytes ourselves
# before any decoding.
sub _validate_strict_utf8 {
    my ($s) = @_;
    # Fast path: pure-ASCII source has no UTF-8 work to do. A single
    # regex hit returns immediately on flat-ASCII data — saves ~150ms.
    return if $s !~ /[\x80-\xFF]/;
    my $n = length($s);
    my $i = 0;
    while ($i < $n) {
        my $b0 = ord(substr($s, $i, 1));
        if ($b0 < 0x80) { $i++; next; }
        my ($expect, $cp_lo, $cp_hi);
        if (($b0 & 0xE0) == 0xC0) {
            return _utf8_die($s, $i) if $b0 < 0xC2;   # overlong
            $expect = 2; $cp_lo = 0x80; $cp_hi = 0x7FF;
        } elsif (($b0 & 0xF0) == 0xE0) {
            $expect = 3; $cp_lo = 0x800; $cp_hi = 0xFFFF;
        } elsif (($b0 & 0xF8) == 0xF0) {
            return _utf8_die($s, $i) if $b0 > 0xF4;   # > U+10FFFF
            $expect = 4; $cp_lo = 0x10000; $cp_hi = 0x10FFFF;
        } else {
            return _utf8_die($s, $i);                 # bare cont / 5-6 byte
        }
        return _utf8_die($s, $i) if $i + $expect > $n;
        my $cp = ($b0 & ((1 << (7 - $expect)) - 1));
        for (my $k = 1; $k < $expect; $k++) {
            my $bk = ord(substr($s, $i + $k, 1));
            return _utf8_die($s, $i) if ($bk & 0xC0) != 0x80;
            $cp = ($cp << 6) | ($bk & 0x3F);
        }
        return _utf8_die($s, $i) if $cp < $cp_lo || $cp > $cp_hi;
        return _utf8_die($s, $i) if $cp >= 0xD800 && $cp <= 0xDFFF;
        $i += $expect;
    }
}

sub _utf8_die {
    my ($s, $i) = @_;
    my $prefix = substr($s, 0, $i);
    my $line = 1 + ($prefix =~ tr/\n//);
    my $last_nl = rindex($prefix, "\n");
    my $col = $i - ($last_nl + 1) + 1;
    die "$line:$col: input is not valid UTF-8\n";
}

# Shared input-normalization for every public decode entry point.
# SPEC §"UTF-8 only, NFC-normalized": reject BOM at offset 0, reject
# malformed UTF-8 bytes (5/6-byte forms, > U+10FFFF, lone continuation
# bytes, overlongs, surrogates), reject U+0000 anywhere, then NFC the
# source. Returns the (possibly NFC'd) Perl-internal-encoded string.
sub _normalize_source {
    my ($src) = @_;
    # SPEC §"UTF-8 only, NFC-normalized": DMS source is plain UTF-8 with
    # no byte-order mark. A leading U+FEFF is not silently consumed —
    # reject it explicitly so encoding mistakes surface loudly. (BOMs
    # *inside* string/heredoc bodies are fine; this only fires at offset 0.)
    # We check for the raw UTF-8 BOM bytes (EF BB BF) before any decoding,
    # so the rejection is independent of how the caller passed `$src`.
    if (!utf8::is_utf8($src) && length($src) >= 3
        && substr($src, 0, 3) eq "\xEF\xBB\xBF") {
        die "1:1: BOM (U+FEFF) at file start is not allowed; DMS source is plain UTF-8\n";
    }
    # SPEC §"UTF-8 only": reject malformed UTF-8 bytes (codepoints
    # > U+10FFFF, lone continuation bytes, overlongs, surrogates encoded
    # as bytes). Perl's `utf8::decode` is permissive about 5/6-byte
    # forms and codepoints above U+10FFFF, so we additionally walk the
    # raw bytes to confirm strict UTF-8 conformance.
    if (!utf8::is_utf8($src)) {
        _validate_strict_utf8($src);
        my $copy = $src;
        if (!utf8::decode($copy)) {
            die "1:1: input is not valid UTF-8\n";
        }
        $src = $copy;
    }
    if (length($src) >= 1 && substr($src, 0, 1) eq "\x{FEFF}") {
        die "1:1: BOM (U+FEFF) at file start is not allowed; DMS source is plain UTF-8\n";
    }
    # U+0000 is not allowed anywhere in DMS source (see SPEC §Strings).
    if ((my $nul = index($src, "\0")) >= 0) {
        my $prefix = substr($src, 0, $nul);
        my $line = 1 + ($prefix =~ tr/\n//);
        my $last_nl = rindex($prefix, "\n");
        my $col = $nul - ($last_nl + 1) + 1;
        die "$line:$col: U+0000 (NUL) is not allowed in DMS source\n";
    }
    # SPEC §Unicode normalization: NFC the source before tokenization.
    # Fast path: pure-ASCII source is already in NFC; skip the (linear,
    # codepoint-walking) NFC pass entirely. The check itself is a single
    # regex that finds the first non-ASCII byte if any.
    $src = _NFC($src) if $src =~ /[^\x00-\x7F]/;
    return $src;
}

# SPEC §Front-matter-only decode. Decodes the leading `+++ ... +++`
# block (if any) and returns it as a hashref, then stops without
# tokenizing the body. Returns undef when the document has no front
# matter at all (no opening `+++` after trivia). An empty front matter
# (`+++\n+++\n`) returns a defined-but-empty hashref, distinguishable
# from undef.
#
# Operates in lite mode (no comment AST, no original_forms recorded
# inside the FM). Diagnostics inside the `+++ ... +++` block are
# byte-identical to a full decode.
sub decode_front_matter {
    my ($src) = @_;
    $src = _normalize_source($src);
    my $self = bless {
        src => $src,
        len => length($src),
        pos => 0,
        line => 1,
        line_start => 0,
        pending_leading => [],
        path => [],
        comments => [],
        original_forms => [],
        record_forms => 1,
        # SPEC §Front-matter-only decode: "Mode: front-matter-only
        # decode runs in lite mode."
        lite => 1,
        # FM is always ordered (SPEC §"Unordered tables"); ignore_order
        # only affects body tables, which we never reach.
        ignore_order => 0,
    }, __PACKAGE__;
    return $self->parse_front_matter;
}

sub _parse_document_with_mode {
    my ($src, $lite, $ignore_order) = @_;
    $ignore_order = 0 unless $ignore_order;
    $src = _normalize_source($src);
    my $self = bless {
        src => $src,
        len => length($src),
        pos => 0,
        line => 1,
        line_start => 0,
        # Comment-AST state. `pending_leading` accumulates full-line
        # comments seen by `_skip_trivia`; on the next sibling-entry
        # they're flushed as Leading on its breadcrumb, on a blank line
        # gap or end-of-block they're flushed as Floating on the current
        # path. `path` is the breadcrumb stack for the value currently
        # being parsed (strings for table keys; DMS::Parser::Index for list
        # indices). `comments` is the accumulator returned to the caller.
        pending_leading => [],
        path => [],
        comments => [],
        # Original-literal records for to_dms round-trip. Sparse: only
        # nodes whose surface form differs from the emitter's default
        # (decimal-no-underscores for ints, basic-quoted for strings)
        # get an entry. See SPEC §to_dms.
        original_forms => [],
        # When false, integer/string lexeme recording is suppressed.
        # Used inside key parses and inside heredoc modifier args.
        record_forms => 1,
        # Lite mode: skip comment-AST + original_forms bookkeeping.
        # Same grammar, same errors.
        lite => $lite,
        # Unordered mode: when true, body tables are produced as
        # DMS::Parser::UnorderedTable (plain Perl hashes) instead of Tie::IxHash
        # tied tables. Front-matter parsing ignores this flag — meta
        # stays ordered. See SPEC §"Unordered tables".
        ignore_order => $ignore_order,
    }, __PACKAGE__;
    my $meta = $self->parse_front_matter;
    my $body = $self->parse_body;
    return {
        meta => $meta,
        body => $body,
        comments => $self->{comments},
        original_forms => $self->{original_forms},
    };
}

# Append an OriginalLiteral record at the current path. Skipped when
# record_forms is false or when in lite mode.
sub _record_form {
    my ($self, $lit) = @_;
    return if $self->{lite} || !$self->{record_forms};
    push @{$self->{original_forms}}, [ [@{$self->{path}}], $lit ];
}

sub _peek {
    my $self = shift;
    return undef if $self->{pos} >= $self->{len};
    return substr($self->{src}, $self->{pos}, 1);
}

sub _peek_at {
    my ($self, $off) = @_;
    my $p = $self->{pos} + $off;
    return undef if $p >= $self->{len};
    return substr($self->{src}, $p, 1);
}

sub _starts_with {
    my ($self, $s) = @_;
    return substr($self->{src}, $self->{pos}, length($s)) eq $s;
}

sub _bump {
    my $self = shift;
    return undef if $self->{pos} >= $self->{len};
    my $c = substr($self->{src}, $self->{pos}, 1);
    $self->{pos}++;
    return $c;
}

sub _eof { return $_[0]{pos} >= $_[0]{len} }

sub _advance_line {
    my $self = shift;
    $self->{line}++;
    $self->{line_start} = $self->{pos};
}

sub _is_bare_key_char {
    my ($c) = @_;
    return 1 if $c eq '-';
    my $o = ord($c);
    if ($o < 128) {
        return $c =~ /[A-Za-z0-9_]/;
    }
    # Frozen Unicode 15.1 XID_Continue snapshot - see @XID_CONTINUE_RANGES.
    return _is_xid_continue($o);
}

sub _is_label_start {
    my ($c) = @_;
    return defined($c) && ($c eq '_' || $c =~ /[A-Za-z]/);
}

sub _is_label_cont {
    my ($c) = @_;
    return defined($c) && ($c eq '_' || $c =~ /[A-Za-z0-9]/);
}

sub _looks_like_date_prefix {
    my ($s) = @_;
    return 0 if length($s) < 10;
    return $s =~ /^\d\d\d\d-\d\d-\d\d/;
}

sub _looks_like_time_prefix {
    my ($s) = @_;
    return 0 if length($s) < 8;
    return $s =~ /^\d\d:\d\d:\d\d/;
}

my %TERMINATORS = map { $_ => 1 } (' ', "\t", "\n", "\r", '#', '/', ',', ']', '}');
sub _is_value_terminator {
    my ($c) = @_;
    return 1 if !defined($c);
    return exists $TERMINATORS{$c};
}

# SPEC §Lexical "Reserved decorator sigils": the seventeen characters
# below are reserved as decorator sigils at line-start position. A body
# line whose first non-whitespace character is one of these is a tier-0
# parse error. Underscore is *not* in this set — it has its own role
# for core / built-in decorators (e.g. heredoc modifiers `_trim`).
# The reservation only applies to structural body positions; sigils
# appearing inside strings, comments, or heredoc bodies are ordinary
# content and remain valid.
my %RESERVED_DECORATOR_SIGIL = map { $_ => 1 }
    ('!', '@', '$', '%', '^', '&', '*', '|', '~', '`',
     '.', ',', '>', '<', '?', ';', '=');

sub _check_reserved_sigil {
    my $self = shift;
    my $p = $self->{pos};
    return if $p >= $self->{len};
    my $c = substr($self->{src}, $p, 1);
    return unless exists $RESERVED_DECORATOR_SIGIL{$c};
    $self->_die(
        "'$c' is a reserved decorator sigil at line-start (tier 0)"
    );
}

sub _skip_inline_ws {
    my $self = shift;
    pos($self->{src}) = $self->{pos};
    if ($self->{src} =~ /\G[ \t]+/gc) {
        $self->{pos} = pos($self->{src});
    }
}

sub _consume_eol {
    my $self = shift;
    my $c = $self->_peek;
    if (defined($c) && $c eq "\n") {
        $self->{pos}++;
        $self->_advance_line;
        return 1;
    }
    if ($self->_starts_with("\r\n")) {
        $self->{pos} += 2;
        $self->_advance_line;
        return 1;
    }
    return 0;
}

sub _skip_trivia {
    my $self = shift;
    # Hot path: the next byte is something other than ws/EOL/comment.
    # Skip the whole loop. parse_table_block hits this between every
    # 50k keys.
    my $p = $self->{pos};
    if ($p < $self->{len}) {
        my $c0 = substr($self->{src}, $p, 1);
        return if $c0 ne ' ' && $c0 ne "\t" && $c0 ne "\n" && $c0 ne "\r"
              && $c0 ne '#' && $c0 ne '/';
    } else {
        return;
    }
    while (1) {
        my $start = $self->{pos};
        # Inline _skip_inline_ws + _peek in one regex hit.
        pos($self->{src}) = $start;
        if ($self->{src} =~ /\G[ \t]+/gc) { $self->{pos} = pos($self->{src}); }
        $p = $self->{pos};
        my $c = $p >= $self->{len} ? undef : substr($self->{src}, $p, 1);
        if (defined($c) && ($c eq "\n" || $c eq "\r")) {
            if ($c eq "\r" && !$self->_starts_with("\r\n")) {
                $self->_die("bare CR is not a valid line terminator");
            }
            # Blank line: any pending leading comments are now separated
            # from a future sibling, so flush them as Floating on the
            # current path.
            $self->_flush_pending_as_floating;
            $self->_consume_eol;
        } elsif (defined($c) && $c eq '#') {
            if ($self->_starts_with("###")) {
                my $raw = $self->_read_hash_block_comment;
                push @{$self->{pending_leading}},
                    { content => $raw, kind => 'block' } unless $self->{lite};
            } else {
                my $raw = $self->_read_line_comment_to_eol;
                $self->_consume_eol;
                push @{$self->{pending_leading}},
                    { content => $raw, kind => 'line' } unless $self->{lite};
            }
        } elsif (defined($c) && $c eq '/' && $self->_starts_with("//")) {
            my $raw = $self->_read_line_comment_to_eol;
            $self->_consume_eol;
            push @{$self->{pending_leading}},
                { content => $raw, kind => 'line' } unless $self->{lite};
        } elsif (defined($c) && $c eq '/' && $self->_starts_with("/*")) {
            my $raw = $self->_read_c_block_comment;
            push @{$self->{pending_leading}},
                { content => $raw, kind => 'block' } unless $self->{lite};
        } else {
            $self->{pos} = $start;
            return;
        }
        return if $self->_eof;
    }
}

# Drain pending_leading and attach each as a Floating comment on the
# current path. Called on blank-line gaps and at end-of-block.
sub _flush_pending_as_floating {
    my $self = shift;
    return if !@{$self->{pending_leading}};
    my @drained = @{$self->{pending_leading}};
    $self->{pending_leading} = [];
    for my $c (@drained) {
        push @{$self->{comments}}, {
            comment => $c,
            position => 'floating',
            path => [@{$self->{path}}],
        };
    }
}

# Drain pending_leading and attach each as a Leading comment on the
# current path. Called by sibling-entry sites (parse_kvpair,
# parse_list_block) right after pushing the new sibling's breadcrumb.
sub _flush_pending_as_leading_on_current {
    my $self = shift;
    return if !@{$self->{pending_leading}};
    my @drained = @{$self->{pending_leading}};
    $self->{pending_leading} = [];
    for my $c (@drained) {
        push @{$self->{comments}}, {
            comment => $c,
            position => 'leading',
            path => [@{$self->{path}}],
        };
    }
}

# Read a `# ...` or `// ...` line comment (without consuming the EOL)
# and return the raw delimiter+body text.
sub _read_line_comment_to_eol {
    my $self = shift;
    # Bulk scan to next \n or \r in one regex op rather than char-by-char
    # _peek loop. The bench fixture is 56% comments so this fires often.
    pos($self->{src}) = $self->{pos};
    $self->{src} =~ /\G[^\n\r]*/gc;
    my $end = pos($self->{src});
    my $start = $self->{pos};
    $self->{pos} = $end;
    # Lite mode discards comments — skip building the substr entirely.
    return '' if $self->{lite};
    return substr($self->{src}, $start, $end - $start);
}

# Read `/* ... */` (nested), returning the raw text including delimiters.
sub _read_c_block_comment {
    my $self = shift;
    my ($sl, $sls, $sp) = ($self->{line}, $self->{line_start}, $self->{pos});
    my $start = $self->{pos};
    $self->{pos} += 2;
    my $depth = 1;
    while ($depth > 0) {
        if ($self->_eof) {
            die $self->_err_at($sl, $sls, $sp, "unterminated /* block comment");
        }
        my $c = $self->_peek;
        if ($c eq '/' && $self->_starts_with("/*")) { $self->{pos} += 2; $depth++; }
        elsif ($c eq '*' && $self->_starts_with("*/")) { $self->{pos} += 2; $depth--; }
        elsif ($c eq "\n") { $self->{pos}++; $self->_advance_line; }
        elsif ($c eq "\r" && $self->_starts_with("\r\n")) { $self->{pos} += 2; $self->_advance_line; }
        else { $self->{pos}++; }
    }
    return substr($self->{src}, $start, $self->{pos} - $start);
}

# Read `### ... ###` or `###LABEL ... LABEL`. The terminator's EOL is
# consumed but is NOT part of the returned text.
sub _read_hash_block_comment {
    my $self = shift;
    my ($sl, $sls, $sp) = ($self->{line}, $self->{line_start}, $self->{pos});
    my $start = $self->{pos};
    $self->{pos} += 3;
    my $ls = $self->{pos};
    while (1) {
        my $c = $self->_peek;
        last if !defined($c) || !($c eq '_' || $c =~ /[A-Za-z0-9]/);
        $self->{pos}++;
    }
    my $label = substr($self->{src}, $ls, $self->{pos} - $ls);
    if (length($label) > 0) {
        my $c0 = substr($label, 0, 1);
        if ($c0 ne '_' && $c0 !~ /[A-Za-z]/) {
            die $self->_err_at($sl, $sls, $sp, "block comment label must start with a letter or underscore");
        }
    }
    my $terminator = length($label) ? $label : "###";
    $self->_skip_inline_ws;
    if (!($self->_consume_eol || $self->_eof)) {
        $self->_die("block comment opener must be on its own line");
    }
    while (1) {
        if ($self->_eof) {
            die $self->_err_at($sl, $sls, $sp, "unterminated ### block comment");
        }
        my $lb = $self->{pos};
        while (1) {
            my $c = $self->_peek;
            last if !defined($c) || $c eq "\n" || $c eq "\r";
            $self->{pos}++;
        }
        my $line_text = substr($self->{src}, $lb, $self->{pos} - $lb);
        my $line_end = $self->{pos};
        $self->_consume_eol;
        my $trimmed = $line_text;
        $trimmed =~ s/^\s+|\s+$//g;
        if ($trimmed eq $terminator) {
            return substr($self->{src}, $start, $line_end - $start);
        }
    }
}

sub parse_front_matter {
    my $self = shift;
    my $save_pos = $self->{pos};
    my $save_line = $self->{line};
    my $save_ls = $self->{line_start};
    my $save_pending = scalar @{$self->{pending_leading}};
    my $save_comments = scalar @{$self->{comments}};
    $self->_skip_trivia;
    my $rest = substr($self->{src}, $self->{pos});
    if (substr($rest, 0, 3) ne '+++') {
        $self->{pos} = $save_pos; $self->{line} = $save_line; $self->{line_start} = $save_ls;
        # Speculative skip_trivia may have captured comments — undo so
        # the body parser re-captures them with the right path.
        splice @{$self->{pending_leading}}, $save_pending;
        splice @{$self->{comments}}, $save_comments;
        return undef;
    }
    # Any trailing content on the opener line is a parse error
    # (SPEC §Front matter: "each `+++` must appear on its own line,
    # with no trailing content"). Advance past `+++` and let the
    # strict EOL check below diagnose.
    my ($ol, $ols, $op) = ($self->{line}, $self->{line_start}, $self->{pos});
    $self->{pos} += 3;
    $self->_skip_inline_ws;
    if (!($self->_consume_eol || $self->_eof)) {
        $self->_die("front matter opener must be on its own line");
    }
    my @inner;
    while (1) {
        if ($self->_eof) {
            die $self->_err_at($ol, $ols, $op, "unterminated front matter: missing closing '+++'");
        }
        my $lb = $self->{pos};
        while (1) {
            my $c = $self->_peek;
            last if !defined($c) || $c eq "\n" || $c eq "\r";
            $self->{pos}++;
        }
        my $lt = substr($self->{src}, $lb, $self->{pos} - $lb);
        my $trimmed = $lt; $trimmed =~ s/^\s+|\s+$//g;
        if ($trimmed eq '+++') { $self->_consume_eol; last; }
        push @inner, $lt;
        push @inner, "\n" if $self->_consume_eol;
    }
    my $inner_src = join('', @inner);
    my $sub = bless {
        src => $inner_src,
        len => length($inner_src),
        pos => 0,
        line => 1,
        line_start => 0,
        pending_leading => [],
        path => [],
        comments => [],
        original_forms => [],
        record_forms => 1,
        lite => $self->{lite},
        # Front-matter is always ordered, regardless of body's ignore_order.
        # See SPEC §"Unordered tables".
        ignore_order => 0,
    }, __PACKAGE__;
    my $table = $sub->parse_body_as_table;
    my $lite = $self->{lite};
    my ($meta, $meta_order);
    if ($lite) {
        $meta_order = [];
        $meta = { $ORDER_KEY => $meta_order };
    } else {
        $meta = new_table();
    }
    my $fm_err = sub { die $self->_err_at($ol, $ols, $op, $_[0]); };
    # Iterate $table in insertion order: lite-mode tables carry their
    # order list at $ORDER_KEY, tied tables yield insertion order via
    # `keys`.
    my @table_keys;
    if ($lite && exists $table->{$ORDER_KEY}) {
        @table_keys = @{ $table->{$ORDER_KEY} };
    } else {
        @table_keys = grep { $_ ne $ORDER_KEY } keys %$table;
    }
    for my $k (@table_keys) {
        my $v = $table->{$k};
        if ($k =~ /^_/) {
            if ($k eq '_dms_tier') {
                unless (ref($v) eq 'DMS::Parser::Integer') {
                    $fm_err->("_dms_tier must be a non-negative integer");
                }
                my $n = int($$v);
                if ($n < 0) {
                    $fm_err->("_dms_tier must be non-negative");
                }
                if ($n >= 1) {
                    $fm_err->("_dms_tier: $n is not supported (no tier >= 1 is defined in this version of DMS)");
                }
            } else {
                $fm_err->("unknown reserved key: $k");
            }
        } else {
            push @$meta_order, $k if $lite;
            $meta->{$k} = $v;
        }
    }
    # Hoist sub-parser comments into ours, prefixing each path with the
    # sentinel string "__fm__" so callers can distinguish front-matter
    # comments from body comments. Comments attached to reserved
    # (consumed) `_dms_*` keys are dropped.
    for my $ac (@{$sub->{comments}}) {
        my $first = $ac->{path}[0];
        my $attached_to_reserved = (defined($first) && !ref($first) && substr($first, 0, 1) eq '_');
        if ($attached_to_reserved) {
            # Reserved key was consumed — re-attach as floating on FM.
            push @{$self->{comments}}, {
                comment  => $ac->{comment},
                position => 'floating',
                path     => ['__fm__'],
            };
            next;
        }
        my @new_path = ('__fm__', @{$ac->{path}});
        push @{$self->{comments}}, {
            comment  => $ac->{comment},
            position => $ac->{position},
            path     => \@new_path,
        };
    }
    # Same hoist for original_forms: `__fm__` prefix, drop entries for
    # consumed `_dms_*` keys.
    for my $pair (@{$sub->{original_forms}}) {
        my ($spath, $lit) = @$pair;
        my $first = $spath->[0];
        if (defined($first) && !ref($first) && substr($first, 0, 1) eq '_') {
            next;
        }
        my @new_path = ('__fm__', @$spath);
        push @{$self->{original_forms}}, [ \@new_path, $lit ];
    }
    return $meta;
}

sub parse_body_as_table {
    my $self = shift;
    $self->_skip_trivia;
    if ($self->_eof) {
        # FM body is empty or comments-only — flush pending as floating.
        $self->_flush_pending_as_floating;
        return $self->{lite} ? { $ORDER_KEY => [] } : new_table();
    }
    my $c = $self->_peek;
    if ($c eq ' ' || $c eq "\t") { $self->_die("unexpected indentation inside front matter"); }
    # SPEC §Lexical "Reserved decorator sigils": rejected before the
    # generic "front matter block must be a table" diagnostic so the
    # error message identifies the actual cause.
    $self->_check_reserved_sigil;
    if ($c eq '+' && $self->_peek_after_plus_is_space_or_eol) { $self->_die("front matter block cannot have a list root"); }
    if (!$self->_line_starts_kvpair) { $self->_die("front matter block must be a table"); }
    my $t = $self->parse_table_block(0);
    $self->_skip_trivia;
    $self->_die("trailing content inside front matter") unless $self->_eof;
    return $t;
}

sub parse_body {
    my $self = shift;
    $self->_skip_trivia;
    if ($self->_eof) {
        # Empty / comment-only body: pending comments float on root.
        $self->_flush_pending_as_floating;
        if ($self->{ignore_order}) {
            return new_unordered_table();
        }
        return $self->{lite} ? { $ORDER_KEY => [] } : new_table();
    }
    my $c = $self->_peek;
    if ($c eq ' ' || $c eq "\t") {
        $self->_die("unexpected indentation at document root");
    }
    my $result;
    if ($c eq '+' && $self->_peek_after_plus_is_space_or_eol) {
        $result = $self->parse_list_block(0);
        $self->_skip_trivia;
        $self->_die("trailing content after list root") unless $self->_eof;
    } elsif ($self->_line_starts_kvpair) {
        $result = $self->parse_table_block(0);
        $self->_skip_trivia;
        $self->_die("trailing content after table root") unless $self->_eof;
    } else {
        $result = $self->parse_inline_value_or_heredoc;
        $self->_consume_after_value(1);
        $self->_skip_trivia;
        $self->_die("scalar root cannot be followed by more content") unless $self->_eof;
    }
    # Any trivia comments seen after the body float on root.
    $self->_flush_pending_as_floating;
    return $result;
}

sub _peek_after_plus_is_space_or_eol {
    my $self = shift;
    my $nxt = $self->_peek_at(1);
    return 1 if !defined($nxt);
    return $nxt eq ' ' || $nxt eq "\t" || $nxt eq "\n" || $nxt eq "\r";
}

sub _line_starts_kvpair {
    my $self = shift;
    my $p = $self->{pos};
    my $s = $self->{src};
    my $n = $self->{len};
    if ($p < $n && substr($s, $p, 1) eq '"') {
        $p++;
        while ($p < $n) {
            my $ch = substr($s, $p, 1);
            if ($ch eq '\\') { $p += 2; }
            elsif ($ch eq '"') { $p++; last; }
            elsif ($ch eq "\n" || $ch eq "\r") { return 0; }
            else { $p++; }
        }
    } elsif ($p < $n && substr($s, $p, 1) eq "'") {
        $p++;
        while ($p < $n) {
            my $ch = substr($s, $p, 1);
            if ($ch eq "'") { $p++; last; }
            elsif ($ch eq "\n" || $ch eq "\r") { return 0; }
            else { $p++; }
        }
    } else {
        my $any = 0;
        while ($p < $n) {
            my $ch = substr($s, $p, 1);
            last if !_is_bare_key_char($ch);
            $p++; $any = 1;
        }
        return 0 if !$any;
    }
    return 0 if $p >= $n || substr($s, $p, 1) ne ':';
    return 1 if $p + 1 >= $n;
    my $nxt = substr($s, $p+1, 1);
    return $nxt eq ' ' || $nxt eq "\t" || $nxt eq "\n" || $nxt eq "\r";
}

sub _measure_line_indent {
    my $self = shift;
    # Single regex hit instead of a per-char loop. Operate directly on
    # $self->{src} (no copy of the 700KB+ source) — pos() set/read is
    # safe on a hash element.
    pos($self->{src}) = $self->{line_start};
    return $self->{src} =~ /\G( +)/g ? length($1) : 0;
}

sub parse_table_block {
    my ($self, $indent) = @_;
    my $lite = $self->{lite};
    my $ignore_order = $self->{ignore_order};
    # Lite path uses a plain (non-tied) hash with a sidecar order list
    # under "\0_keys" — Tie::IxHash STORE/FETCH/EXISTS dispatch overhead
    # is the single biggest fixed cost on flat-table parses. Non-lite
    # path keeps the tied hash for full Document-tree compatibility.
    # ignore_order path: blessed DMS::Parser::UnorderedTable plain hashref, no
    # order list, no tying. SPEC §"Unordered tables".
    my $t;
    my $order;
    if ($ignore_order) {
        $t = new_unordered_table();
    } elsif ($lite) {
        $order = [];
        $t = { $ORDER_KEY => $order };
    } else {
        $t = new_table();
    }
    # Hot bulk loop (lite mode, indent == 0 only). On flat-table
    # benchmarks, every line matches `bareword: int\n` — we can batch
    # them with one tight regex and avoid 50 k method-call frames per
    # parse. The regex anchors at the current `pos`, captures up to N
    # consecutive simple-line kvpairs, and stops on the first non-match
    # so the slow path can handle anything else (strings, floats, dates,
    # nested values, comments, indented blocks). Re-entered after each
    # slow-path iteration so a one-off slow line doesn't disable the
    # batch path for the rest of the file.
    # Bulk path: lite + (ordered with sidecar) OR lite + ignore_order
    # (no sidecar). Both paths use a plain hash; the only difference is
    # whether `$order` is updated.
    my $bulk = $lite ? 1 : 0;
    # File-scoped cache below (%BULK_RE_CACHE) maps indent -> compiled
    # regex. Persists across calls so common levels (0, 2, 4, 6) compile
    # once globally even across recursive parse_table_block invocations.
    my $bulk_re = $BULK_RE_CACHE{$indent} //= do {
        my $sp = $indent == 0 ? '' : "[ ]{$indent}";
        # Groups:
        #   $2: positive integer
        #   $3: negative integer
        #   $4: bool
        #   $5: ASCII-only basic-string content (no escapes)
        #   $6: empty list / empty table literal
        #   $7: decimal float (matches `-?[0-9]+\.[0-9]+`, no exponent)
        qr/\G$sp([A-Za-z_][A-Za-z0-9_-]*):[ ](?:(0|[1-9][0-9]{0,17})|(-[1-9][0-9]{0,17})|(true|false)|"([\x20-\x21\x23-\x5b\x5d-\x7e]*)"|(\[\]|\{\})|(-?(?:0|[1-9][0-9]*)\.[0-9]+))\r?\n/;
    };
    while (1) {
        if ($bulk && $self->{pos} == $self->{line_start}) {
            my $src_ref = \$self->{src};
            pos($$src_ref) = $self->{pos};
            my $line = $self->{line};
            # One regex matches multiple value forms:
            #   group $2: positive integer (0 or [1-9][0-9]{0,17}, 18 digits max → safe i64)
            #   group $3: negative integer (-[1-9][0-9]{0,17})
            #   group $4: 'true' or 'false'
            #   group $5: simple ASCII basic-string content (no \, ", \n, \r,
            #            and ASCII-only so we skip the NFC pass) — empty
            #            string is common in real configs (kube values.yaml
            #            has hundreds of `key: ""` lines).
            #   group $6: '[]' or '{}' (empty list / empty table)
            # Excludes leading-zero forms (which DMS rejects) and overflow.
            # Accepts both LF and CRLF line endings. Anything else (escaped
            # strings, floats, dates, multi-line blocks, comments) falls to
            # the slow path on the next iteration.
            # Inner bulk loop: consumes any pattern we can match purely
            # by regex (kvpair, blank line, single-line `#` or `//`
            # comment) without method dispatch. Falls back to the
            # outer slow path the moment something complex appears
            # (heredoc, escaped string, list item, block comment).
            INNER: while (1) {
                if ($$src_ref =~ /$bulk_re/gc) {
                    my $k = $1;
                    if (exists $t->{$k}) {
                        # Roll back to start of the current line for accurate error pos.
                        my $cur = pos($$src_ref);
                        while ($cur > 0 && substr($$src_ref, $cur - 1, 1) ne "\n") { $cur--; }
                        $self->{pos} = $cur;
                        $self->{line} = $line;
                        $self->{line_start} = $cur;
                        $self->_die("duplicate key: $k");
                    }
                    my $val;
                    if (defined $2) {
                        my $iv = 0 + $2;
                        $val = bless \$iv, 'DMS::Parser::Integer';
                    } elsif (defined $3) {
                        my $iv = 0 + $3;
                        $val = bless \$iv, 'DMS::Parser::Integer';
                    } elsif (defined $4) {
                        my $bv = $4 eq 'true' ? 1 : 0;
                        $val = bless \$bv, 'DMS::Parser::Bool';
                    } elsif (defined $5) {
                        # ASCII-only basic string, no escapes / no NFC.
                        $val = $5;
                    } elsif (defined $6) {
                        # '[]' or '{}'.
                        $val = $6 eq '[]' ? [] : { $ORDER_KEY => [] };
                    } else {
                        # $7: decimal float.
                        my $fv = 0 + $7;
                        $val = bless \$fv, 'DMS::Parser::Float';
                    }
                    push @$order, $k if $order;
                    $t->{$k} = $val;
                    $line++;
                    next INNER;
                }
                # Blank line at any leading whitespace.
                if ($$src_ref =~ /\G[ \t]*\r?\n/gc) {
                    $line++;
                    next INNER;
                }
                # Single-line `#` comment (NOT `###` labeled block) or `//`.
                # Excludes `/*` (C-style block) which spans multiple lines.
                # bench_realistic is 56% comments — taking these in the
                # bulk loop avoids hundreds of _skip_trivia method calls.
                if ($$src_ref =~ /\G[ \t]*(?:#(?!##)|\/\/(?!\*))[^\n\r]*\r?\n/gc) {
                    $line++;
                    next INNER;
                }
                last INNER;
            }
            $self->{pos} = pos($$src_ref) // $self->{pos};
            $self->{line} = $line;
            $self->{line_start} = $self->{pos};
        }
        $self->_skip_trivia;
        last if $self->{pos} >= $self->{len};
        # Inline _measure_line_indent: hot enough that the call cost
        # matters across 50k iterations. For indent==0 (most flat
        # tables) we can skip the regex when pos is already at
        # line_start with no leading space — by far the common case.
        my $li;
        if ($indent == 0 && $self->{pos} == $self->{line_start}
            && substr($self->{src}, $self->{pos}, 1) ne ' ') {
            $li = 0;
        } else {
            pos($self->{src}) = $self->{line_start};
            $li = $self->{src} =~ /\G( +)/g ? length($1) : 0;
        }
        last if $li < $indent;
        if ($li != $indent) {
            die $self->_err_at($self->{line}, $self->{line_start}, $self->{line_start}+$indent,
                "inconsistent indent: expected $indent spaces, got $li");
        }
        $self->{pos} = $self->{line_start} + $indent;
        # SPEC §Lexical "Reserved decorator sigils": reject ! @ $ % ^ & *
        # | ~ ` . , > < ? ; = as the first non-whitespace character of a
        # body line. We sit at exactly that position now (line_start +
        # structural indent), so a single-char check is sufficient.
        $self->_check_reserved_sigil;
        my ($k, $v);
        if ($lite) {
            # Inlined fast-path of parse_kvpair: skip the eval frame and
            # the path push/pop that parse_kvpair adds for non-lite modes.
            $k = $self->parse_key;
            $self->_die("expected ':' after key")
                if substr($self->{src}, $self->{pos}, 1) ne ':';
            $v = $self->_parse_kvpair_after_key($indent);
            $self->_die("duplicate key: $k") if exists $t->{$k};
            push @$order, $k if $order;
            $t->{$k} = $v;
        } else {
            ($k, $v) = $self->parse_kvpair($indent);
            $self->_die("duplicate key: $k") if exists $t->{$k};
            $t->{$k} = $v;
        }
    }
    # Block close: leftover pending comments float on the enclosing
    # container (this table itself).
    $self->_flush_pending_as_floating unless $lite;
    return $t;
}

sub parse_list_block {
    my ($self, $indent) = @_;
    my @items;
    while (1) {
        $self->_skip_trivia;
        last if $self->_eof;
        my $li = $self->_measure_line_indent;
        last if $li < $indent;
        if ($li != $indent) {
            die $self->_err_at($self->{line}, $self->{line_start}, $self->{line_start}+$indent,
                "inconsistent indent: expected $indent spaces, got $li");
        }
        $self->{pos} = $self->{line_start} + $indent;
        if ($self->_peek ne '+') { last; }
        # Commit to a new list item: push its index, attach pending
        # leading comments to it, then parse the value.
        my $idx = scalar @items;
        push @{$self->{path}}, DMS::Parser::Index->new($idx);
        $self->_flush_pending_as_leading_on_current;
        $self->{pos}++;
        my $c = $self->_peek;
        my $item;
        my $ok = eval {
            if (defined($c) && ($c eq ' ' || $c eq "\t")) {
                $self->{pos}++;
                $self->_skip_inline_ws;
                $self->_capture_inner_block_comments;
                my $c2 = $self->_peek;
                if (!defined($c2) || $c2 eq "\n" || $c2 eq "\r") {
                    # "+ INNER[EOL]" — empty item with inner comments.
                    $self->_consume_eol;
                    $self->_skip_trivia;
                    $self->_die("expected indented block after empty '+' marker") if $self->_eof;
                    my $inner = $self->_measure_line_indent;
                    $self->_die("expected indented block after empty '+' marker") if $inner <= $indent;
                    $item = $self->parse_block_value($inner);
                } else {
                    $item = $self->parse_list_item_value($indent);
                }
            } elsif (!defined($c) || $c eq "\n" || $c eq "\r") {
                $self->_consume_eol;
                $self->_skip_trivia;
                $self->_die("expected indented block after empty '+' marker") if $self->_eof;
                my $inner = $self->_measure_line_indent;
                $self->_die("expected indented block after empty '+' marker") if $inner <= $indent;
                $item = $self->parse_block_value($inner);
            } else {
                $self->_die("expected space after '+'");
            }
            1;
        };
        my $err = $@;
        pop @{$self->{path}};
        if (!$ok) { die $err; }
        push @items, $item;
    }
    # Block close: leftover pending comments float on the list itself.
    $self->_flush_pending_as_floating;
    return \@items;
}

sub parse_block_value {
    my ($self, $indent) = @_;
    $self->{pos} = $self->{line_start} + $indent;
    if ($self->_peek eq '+' && $self->_peek_after_plus_is_space_or_eol) {
        return $self->parse_list_block($indent);
    }
    return $self->parse_table_block($indent);
}

sub parse_list_item_value {
    my ($self, $list_indent) = @_;
    if ($self->_line_starts_kvpair) {
        my $key_col = $self->{pos} - $self->{line_start};
        my $lite = $self->{lite};
        my $ignore_order = $self->{ignore_order};
        my ($k, $v) = $self->parse_kvpair($key_col);
        my ($t, $order);
        if ($ignore_order) {
            $t = new_unordered_table();
            $t->{$k} = $v;
        } elsif ($lite) {
            $order = [$k];
            $t = { $ORDER_KEY => $order, $k => $v };
        } else {
            $t = new_table();
            $t->{$k} = $v;
        }
        while (1) {
            $self->_skip_trivia;
            last if $self->_eof;
            my $li = $self->_measure_line_indent;
            last if $li < $key_col;
            if ($li != $key_col) {
                die $self->_err_at($self->{line}, $self->{line_start}, $self->{line_start}+$key_col,
                    "list-item table sibling key must align with first key");
            }
            $self->{pos} = $self->{line_start} + $key_col;
            $self->_die("'+' marker at sibling-key column is ambiguous") if $self->_peek eq '+';
            last if !$self->_line_starts_kvpair;
            my ($k2, $v2) = $self->parse_kvpair($key_col);
            $self->_die("duplicate key: $k2") if exists $t->{$k2};
            push @$order, $k2 if $order;
            $t->{$k2} = $v2;
        }
        # End of inline-table-in-list-item: any pending leading comments
        # belong to the enclosing list item itself (Floating).
        $self->_flush_pending_as_floating;
        return $t;
    }
    my $v = $self->parse_inline_value_or_heredoc;
    $self->_consume_after_value(0);
    return $v;
}

sub parse_kvpair {
    my ($self, $parent_indent) = @_;
    my $key = $self->parse_key;
    $self->_die("expected ':' after key") if substr($self->{src}, $self->{pos}, 1) ne ':';
    # Lite mode: no comment-AST, no original_form recording, no path
    # bookkeeping needed. Skip the breadcrumb push/pop + eval frame.
    if ($self->{lite}) {
        my $v = $self->_parse_kvpair_after_key($parent_indent);
        return ($key, $v);
    }
    # We've now committed: this is a kvpair. Push the breadcrumb so
    # pending leading comments attach here and so trailing comments
    # captured by _consume_after_value get the right path.
    push @{$self->{path}}, $key;
    $self->_flush_pending_as_leading_on_current;
    my $v;
    my $ok = eval { $v = $self->_parse_kvpair_after_key($parent_indent); 1 };
    my $err = $@;
    pop @{$self->{path}};
    if (!$ok) { die $err; }
    return ($key, $v);
}

sub _parse_kvpair_after_key {
    my ($self, $parent_indent) = @_;
    $self->{pos}++;  # consume ':'
    # Inline _peek: per-key dispatch overhead is significant on flat-50k.
    my $p = $self->{pos};
    my $c = $p >= $self->{len} ? undef : substr($self->{src}, $p, 1);
    if (defined($c) && ($c eq ' ' || $c eq "\t")) {
        $self->{pos}++;
        $p = $self->{pos};
        # Inline _skip_inline_ws fast path — only run the regex if the
        # next byte is itself ws (single-space `key: v` is the common case).
        my $c2 = $p >= $self->{len} ? undef : substr($self->{src}, $p, 1);
        if (defined($c2) && ($c2 eq ' ' || $c2 eq "\t")) {
            pos($self->{src}) = $p;
            $self->{src} =~ /\G[ \t]+/gc;
            $self->{pos} = pos($self->{src});
            $p = $self->{pos};
            $c2 = $p >= $self->{len} ? undef : substr($self->{src}, $p, 1);
        }
        # Inline _capture_inner_block_comments fast path: only call out
        # if the next byte is '/'.
        if (defined($c2) && $c2 eq '/') {
            $self->_capture_inner_block_comments;
            $p = $self->{pos};
            $c2 = $p >= $self->{len} ? undef : substr($self->{src}, $p, 1);
        }
        if (!defined($c2) || $c2 eq "\n" || $c2 eq "\r") {
            # "key: INNER[EOL]" — child block with inner comments.
            $self->_consume_eol;
            $self->_skip_trivia;
            $self->_die("expected indented child block") if $self->_eof;
            my $child = $self->_measure_line_indent;
            $self->_die("expected indented child block") if $child <= $parent_indent;
            return $self->parse_block_value($child);
        }
        my $v = $self->parse_inline_value_or_heredoc;
        $self->_consume_after_value(0);
        return $v;
    }
    if (!defined($c) || $c eq "\n" || $c eq "\r") {
        $self->_consume_eol;
        $self->_skip_trivia;
        $self->_die("expected indented child block") if $self->_eof;
        my $child = $self->_measure_line_indent;
        $self->_die("expected indented child block") if $child <= $parent_indent;
        return $self->parse_block_value($child);
    }
    $self->_die("expected whitespace after ':'");
}

sub parse_key {
    my $self = shift;
    my $p = $self->{pos};
    my $c = $p >= $self->{len} ? undef : substr($self->{src}, $p, 1);
    if (defined($c) && $c eq '"') {
        $self->_die("triple-quoted strings are not allowed as keys") if $self->_starts_with('"""');
        # Suppress original-form recording: keys are not values and must
        # not generate OriginalLiteral entries on the parent path.
        my $saved = $self->{record_forms};
        $self->{record_forms} = 0;
        my $r = eval { $self->parse_basic_string_value };
        my $e = $@;
        $self->{record_forms} = $saved;
        die $e if $e;
        return $r;
    }
    if (defined($c) && $c eq "'") {
        $self->_die("triple-quoted strings are not allowed as keys") if $self->_starts_with("'''");
        my $saved = $self->{record_forms};
        $self->{record_forms} = 0;
        my $r = eval { $self->parse_literal_string_value };
        my $e = $@;
        $self->{record_forms} = $saved;
        die $e if $e;
        return $r;
    }
    $self->_die("expected key") if !defined($c);
    return $self->parse_bare_key;
}

sub parse_bare_key {
    my $self = shift;
    my $start = $self->{pos};
    # Fast path: ASCII-only bare key. One regex bite handles the entire
    # token — no per-byte loop, no Unicode codepoint test.
    pos($self->{src}) = $start;
    if ($self->{src} =~ /\G[A-Za-z0-9_-]+/gc) {
        $self->{pos} = pos($self->{src});
    }
    # Slow path: extend across non-ASCII XID_Continue codepoints if any.
    while ($self->{pos} < $self->{len}) {
        my $c = substr($self->{src}, $self->{pos}, 1);
        last if ord($c) < 128;
        last unless _is_bare_key_char($c);
        $self->{pos}++;
        pos($self->{src}) = $self->{pos};
        if ($self->{src} =~ /\G[A-Za-z0-9_-]+/gc) {
            $self->{pos} = pos($self->{src});
        }
    }
    $self->_die("expected key") if $self->{pos} == $start;
    return substr($self->{src}, $start, $self->{pos} - $start);
}

sub _capture_inner_block_comments {
    my $self = shift;
    # Hot-path early-out: if the next byte isn't '/', there's nothing to do.
    # Per-key cost is one substr instead of two method calls.
    my $p = $self->{pos};
    return if $p >= $self->{len} || substr($self->{src}, $p, 1) ne '/'
           || substr($self->{src}, $p, 2) ne '/*';
    while (1) {
        $p = $self->{pos};
        last if $p >= $self->{len} || substr($self->{src}, $p, 2) ne '/*';
        my $raw = $self->_read_c_block_comment;
        push @{$self->{comments}}, {
            comment  => { content => $raw, kind => 'block' },
            position => 'inner',
            path     => [@{$self->{path}}],
        } unless $self->{lite};
        $self->_skip_inline_ws;
    }
}

sub parse_inline_value_or_heredoc {
    my $self = shift;
    # Inner /* ... */ comments are captured by the caller via
    # _capture_inner_block_comments before this function runs.
    my $p = $self->{pos};
    my $c = $p >= $self->{len} ? undef : substr($self->{src}, $p, 1);
    # SPEC §Lexical "Reserved decorator sigils": a value position that
    # leads with one of `! @ $ % ^ & * | ~ \` . , > < ? ; =` is rejected
    # at tier 0. Covers `key: !tag`, `+ !tag`, scalar-root `!tag`, and
    # the same forms inside flow containers (which dispatch per item).
    if (defined($c) && exists $RESERVED_DECORATOR_SIGIL{$c}) {
        $self->_die(
            "'$c' is a reserved decorator sigil at line-start (tier 0)"
        );
    }
    if (defined($c)) {
        # Hot path: ASCII digit (the most common leaf). Dispatch
        # straight to parse_number_or_datetime without hitting the
        # other typed-leaf branches.
        if ($c ge '0' && $c le '9') {
            return $self->parse_number_or_datetime;
        }
        if ($c eq '"') {
            return $self->parse_heredoc_basic if $self->_starts_with('"""');
            # Basic is the emitter's default for strings — no record.
            return $self->parse_basic_string_value;
        }
        if ($c eq "'") {
            return $self->parse_heredoc_literal if $self->_starts_with("'''");
            my $r = $self->parse_literal_string_value;
            $self->_record_form({ string_form => { kind => 'literal' } });
            return $r;
        }
        return $self->parse_flow_array if $c eq '[';
        return $self->parse_flow_table if $c eq '{';
        return $self->parse_bool_value if $c eq 't' || $c eq 'f';
        return $self->parse_inf_value if $c eq 'i';
        return $self->parse_nan_value if $c eq 'n';
        return $self->parse_number_or_datetime if $c eq '+' || $c eq '-';
    }
    $self->_die("expected value") if !defined($c);
    $self->_die("unexpected character '$c' in value");
}

sub parse_bool_value {
    my $self = shift;
    if ($self->_starts_with("true") && _is_value_terminator($self->_peek_at(4))) {
        $self->{pos} += 4;
        return DMS::Parser::Bool->new(1);
    }
    if ($self->_starts_with("false") && _is_value_terminator($self->_peek_at(5))) {
        $self->{pos} += 5;
        return DMS::Parser::Bool->new(0);
    }
    $self->_die("expected value");
}

sub parse_inf_value {
    my $self = shift;
    if ($self->_starts_with("inf") && _is_value_terminator($self->_peek_at(3))) {
        $self->{pos} += 3;
        return DMS::Parser::Float->new(9**9**9);
    }
    $self->_die("expected 'inf'");
}

sub parse_nan_value {
    my $self = shift;
    if ($self->_starts_with("nan") && _is_value_terminator($self->_peek_at(3))) {
        $self->{pos} += 3;
        return DMS::Parser::Float->new(-(9**9**9) + (9**9**9));
    }
    $self->_die("expected 'nan'");
}

sub parse_number_or_datetime {
    my $self = shift;
    my $base = $self->{pos};
    my $len_src = $self->{len};
    # Combined hot-path: a plain decimal integer that doesn't look like
    # a date or time. One regex bite scans the token; a structural
    # check rejects anything _parse_integer would die on. This single
    # branch is taken by every leaf in flat-data benchmarks.
    pos($self->{src}) = $base;
    if ($self->{src} =~ /\G(0|[1-9][0-9]{0,17})(?![\d_.eExob:-])/g) {
        my $tok = $1;
        $self->{pos} = $base + length($tok);
        my $iv = 0 + $tok;
        return bless \$iv, 'DMS::Parser::Integer';
    }
    # Inline first-char peek: avoid the function-call + substr in _peek.
    my $first = substr($self->{src}, $base, 1);
    my $starts_sign = ($first eq '+' || $first eq '-');
    if (!$starts_sign) {
        # Combined date/time-prefix sniff, regex-only. Skips _looks_like_*
        # which themselves do another substr+regex.
        pos($self->{src}) = $base;
        if ($len_src - $base >= 10 && $self->{src} =~ /\G\d\d\d\d-\d\d-\d\d/) {
            return $self->parse_datetime_value;
        }
        if ($len_src - $base >= 8 && $self->{src} =~ /\G\d\d:\d\d:\d\d/) {
            return $self->parse_local_time_value;
        }
    }
    if ($starts_sign && substr($self->{src}, $base + 1, 3) eq 'inf') {
        my $p4 = $base + 4;
        my $next = $p4 >= $len_src ? undef : substr($self->{src}, $p4, 1);
        if (_is_value_terminator($next)) {
            my $neg = $first eq '-';
            $self->{pos} += 4;
            return DMS::Parser::Float->new($neg ? -(9**9**9) : 9**9**9);
        }
    }
    my ($len, $is_float) = $self->_scan_number_token;
    my $s = substr($self->{src}, $base, $len);
    if ($is_float) {
        my $f;
        eval { $f = _parse_float_val($s); };
        $self->_die("invalid float: $s ($@)") if $@;
        $self->{pos} += $len;
        return DMS::Parser::Float->new($f);
    }
    # Fast path: plain decimal (no sign, no leading-0, fits in 18 digits)
    # never dies — skip the eval frame entirely. The validating regex
    # rejects anything _parse_integer would error on. Bless inline to
    # avoid a method call per leaf.
    if ($s =~ /\A(?:0|[1-9][0-9]{0,17})\z/) {
        $self->{pos} += $len;
        my $iv = 0 + $s;
        return bless \$iv, 'DMS::Parser::Integer';
    }
    my $n;
    eval { $n = _parse_integer($s); };
    if ($@) { my $msg = $@; $msg =~ s/\n.*//s; $self->_die($msg); }
    $self->{pos} += $len;
    # Record original lexeme when it differs from the canonical
    # "decimal, no underscores, no '+' sign" form the default emitter
    # would produce. Hex/oct/bin, underscores, explicit '+' → recorded.
    # Skipped entirely in lite mode (record_forms gate inside _record_form).
    if (!$self->{lite} && $s ne $n) {
        $self->_record_form({ integer_lit => $s });
    }
    return DMS::Parser::Integer->new($n);
}

sub _scan_number_token {
    my $self = shift;
    my $base = $self->{pos};
    pos($self->{src}) = $base;
    # Fast path: plain decimal integer (no sign, no '.' / 'e' / 'x' /
    # 'o' / 'b' prefix continuation). Most leaves in flat data are like
    # this — skip the heavy alternation and avoid the post-scan token
    # re-classification. The negative lookahead must reject anything
    # that would extend the token under the slow grammar (digits, '_',
    # '.', 'e'/'E', and the 0x/0o/0b prefix indicators).
    if ($self->{src} =~ /\G(\d+)(?![\d_.eExob])/g) {
        return (length($1), 0);
    }
    # One regex covers both prefixed (0x/0o/0b) and decimal forms. Behavior
    # mirrors the per-char loop: the prefix branch accepts hex digits +
    # underscores with at most one '.' and one 'p[+-]?' exponent; the
    # decimal branch accepts digits + underscores with at most one '.' and
    # one 'e[+-]?' exponent.
    pos($self->{src}) = $base;
    $self->{src} =~ m{
        \G [+-]?
        (?:
              0[xob] [0-9a-fA-F_]* (?: \. [0-9a-fA-F_]* )? (?: p [+-]? \d* )?
            | [\d_]*               (?: \. [\d_]*           )? (?: [eE] [+-]? \d* )?
        )
    }gxc;
    my $end = pos($self->{src});
    $end = $base unless defined $end;
    my $len = $end - $base;
    return (0, 0) if $len == 0;
    my $tok = substr($self->{src}, $base, $len);
    # In prefixed (0x/0o/0b) tokens 'e' is a hex digit, not an exponent —
    # only '.' or 'p' make the token a float there.
    if ($tok =~ /^[+-]?0[xob]/) {
        return ($len, $tok =~ /[.p]/ ? 1 : 0);
    }
    return ($len, $tok =~ /[.eE]/ ? 1 : 0);
}

sub _valid_underscores {
    my ($s) = @_;
    return 1 if length($s) == 0;
    return 0 if substr($s,0,1) eq '_' || substr($s,-1,1) eq '_';
    my $prev = 0;
    for my $c (split //, $s) {
        if ($c eq '_') { return 0 if $prev; $prev = 1; }
        else { $prev = 0; }
    }
    return 1;
}

# Returns the canonical decimal string for an DMS integer literal. The hot
# path (decimal, no underscores, fits in i64) avoids Math::BigInt entirely
# because BigInt construction/arithmetic dominates the parser otherwise.
# Errors mirror the old Math::BigInt-based implementation byte-for-byte.
sub _parse_integer {
    my ($s) = @_;
    # Hot path: a plain decimal token (no sign, no leading zero, no
    # underscore, fits in 18 chars i.e. always within i64). Covers the
    # vast majority of real-world keys/leaves and skips ~10 substr +
    # length checks below.
    if ($s =~ /\A(?:0|[1-9][0-9]{0,17})\z/) {
        return $s;
    }
    my $sign_str = '';
    my $is_neg = 0;
    my $rest = $s;
    my $first = substr($rest, 0, 1);
    if ($first eq '-') { $sign_str = '-'; $is_neg = 1; $rest = substr($rest, 1); }
    elsif ($first eq '+') { $rest = substr($rest, 1); }
    die "hex prefix must be lowercase '0x'\n" if substr($rest, 0, 2) eq '0X';
    my $radix = 10;
    my $body = $rest;
    if (length($rest) >= 2) {
        my $p2 = substr($rest, 0, 2);
        if    ($p2 eq '0x') { $radix = 16; $body = substr($rest, 2); }
        elsif ($p2 eq '0o') { $radix = 8;  $body = substr($rest, 2); }
        elsif ($p2 eq '0b') { $radix = 2;  $body = substr($rest, 2); }
    }
    die "empty number\n" if length($body) == 0;
    die "underscore must be between digits\n"
        if substr($body, 0, 1) eq '_' || substr($body, -1, 1) eq '_';
    if ($radix == 10 && length($rest) > 1 && substr($rest, 0, 1) eq '0') {
        die "leading zeros are not allowed on decimal integers\n";
    }
    die "underscore must be between digits\n" if index($body, '__') >= 0;
    my $clean = $body;
    $clean =~ tr/_//d if index($clean, '_') >= 0;
    if ($radix == 10) {
        die "invalid digit for base 10\n" if $clean =~ /\D/;
    } elsif ($radix == 16) {
        die "invalid digit for base 16\n" if $clean =~ /[^0-9a-fA-F]/;
    } elsif ($radix == 8) {
        die "invalid digit for base 8\n" if $clean =~ /[^0-7]/;
    } else {
        die "invalid digit for base 2\n" if $clean =~ /[^01]/;
    }

    if ($radix == 10) {
        # Strip leading zeros (keep at least one digit).
        $clean =~ s/^0+(?=\d)//;
        my $bound = $is_neg ? '9223372036854775808' : '9223372036854775807';
        die "integer out of i64 range\n"
            if length($clean) > length($bound)
            || (length($clean) == length($bound) && $clean gt $bound);
        return '0' if $clean eq '0';
        return "${sign_str}${clean}";
    }

    # Non-decimal: cap by max digit count for i64 magnitude.
    if    ($radix == 16 && length($clean) > 16) { die "integer out of i64 range\n"; }
    elsif ($radix == 8  && length($clean) > 22) { die "integer out of i64 range\n"; }
    elsif ($radix == 2  && length($clean) > 64) { die "integer out of i64 range\n"; }

    my $val_lc = lc $clean;
    # Detect magnitudes in the high half (>= 2^63) that don't fit a signed
    # 64-bit positive value. Allowed only as the exact i64 minimum: -2^63.
    my $high_half = 0;
    if    ($radix == 16) { $high_half = length($val_lc) == 16 && substr($val_lc, 0, 1) ge '8'; }
    elsif ($radix == 8)  { $high_half = length($val_lc) == 22 && substr($val_lc, 0, 1) gt '0'; }
    else                  { $high_half = length($val_lc) == 64 && substr($val_lc, 0, 1) eq '1'; }
    if ($high_half) {
        if ($is_neg) {
            return '-9223372036854775808'
                if ($radix == 16 && $val_lc eq '8000000000000000')
                || ($radix == 8  && $val_lc eq '1000000000000000000000')
                || ($radix == 2  && $val_lc eq '1' . ('0' x 63));
        }
        die "integer out of i64 range\n";
    }

    my $native;
    if    ($radix == 16) { $native = hex($val_lc); }
    elsif ($radix == 8)  { $native = oct("0$val_lc"); }
    else                  { $native = oct("0b$val_lc"); }
    return '0' if $native == 0;
    return "${sign_str}$native";
}

sub _parse_float_val {
    my ($s) = @_;
    my $sign = 1.0;
    my $rest = $s;
    if (substr($rest,0,1) eq '-') { $sign = -1.0; $rest = substr($rest, 1); }
    elsif (substr($rest,0,1) eq '+') { $rest = substr($rest, 1); }
    if (substr($rest,0,2) eq '0x' || substr($rest,0,2) eq '0o' || substr($rest,0,2) eq '0b') {
        return $sign * _parse_nondec_float($rest);
    }
    return $sign * _parse_dec_float($rest);
}

sub _parse_dec_float {
    my ($s) = @_;
    my $e_idx = -1;
    for (my $i = 0; $i < length($s); $i++) {
        my $c = substr($s, $i, 1);
        if ($c eq 'e' || $c eq 'E') { $e_idx = $i; last; }
    }
    my $m = $e_idx == -1 ? $s : substr($s, 0, $e_idx);
    my $e = $e_idx == -1 ? undef : substr($s, $e_idx+1);
    die "decimal float requires '.'\n" if index($m, '.') < 0;
    my @parts = split /\./, $m, 2;
    die "decimal float requires digit on both sides of '.'\n"
        if @parts != 2 || $parts[0] eq '' || $parts[1] eq '';
    die "invalid character in mantissa\n" if $parts[0] =~ /[^\d_]/;
    die "invalid character in mantissa\n" if $parts[1] =~ /[^\d_]/;
    die "bad underscore in mantissa\n"
        unless _valid_underscores($parts[0]) && _valid_underscores($parts[1]);
    my $full = $parts[0]; $full =~ s/_//g; $full .= '.';
    my $frac = $parts[1]; $frac =~ s/_//g; $full .= $frac;
    if (defined $e) {
        my $e_clean = $e; $e_clean =~ s/^[+-]//;
        die "underscore not allowed in exponent\n" if $e_clean =~ /_/;
        die "invalid character in exponent\n" if $e =~ /[^\d+-]/;
        die "empty exponent\n" if $e_clean eq '';
        $full .= 'e' . $e;
    }
    return 0 + $full;
}

sub _parse_nondec_float {
    my ($s) = @_;
    my ($radix, $rest);
    if (substr($s,0,2) eq '0x') { $radix = 16; $rest = substr($s,2); }
    elsif (substr($s,0,2) eq '0o') { $radix = 8; $rest = substr($s,2); }
    elsif (substr($s,0,2) eq '0b') { $radix = 2; $rest = substr($s,2); }
    else { die "non-decimal float prefix required\n"; }
    my $p_idx = index($rest, 'p');
    die "non-decimal float requires 'p' exponent\n" if $p_idx < 0;
    my $mant = substr($rest, 0, $p_idx);
    my $exp_str = substr($rest, $p_idx+1);
    die "empty exponent\n" if $exp_str eq '';
    die "underscore not allowed in exponent\n" if $exp_str =~ /_/;
    die "invalid exponent character\n" if $exp_str =~ /[^\d+-]/;
    my $exp = int($exp_str);
    my ($ip, $fp);
    if (index($mant, '.') >= 0) {
        ($ip, $fp) = split /\./, $mant, 2;
        die "digit required on both sides of '.'\n" if $ip eq '' || $fp eq '';
    } else {
        $ip = $mant; $fp = '';
    }
    die "bad underscore\n" unless _valid_underscores($ip) && _valid_underscores($fp);
    $ip =~ s/_//g; $fp =~ s/_//g;
    my $digit_chars = substr("0123456789abcdef", 0, $radix);
    for my $c (split //, $ip) {
        die "invalid digit for base $radix\n" if index($digit_chars, lc $c) < 0;
    }
    for my $c (split //, $fp) {
        die "invalid digit for base $radix\n" if index($digit_chars, lc $c) < 0;
    }
    my $int_val = $ip eq '' ? 0 : hex_to_int($ip, $radix);
    my $frac_val = 0.0;
    my $div = $radix * 1.0;
    for my $c (split //, $fp) {
        my $d = index("0123456789abcdef", lc $c);
        $frac_val += $d / $div;
        $div *= $radix;
    }
    return ($int_val + $frac_val) * (2 ** $exp);
}

sub hex_to_int {
    my ($s, $radix) = @_;
    my $v = 0;
    for my $c (split //, $s) {
        $v = $v * $radix + index("0123456789abcdef", lc $c);
    }
    return $v;
}

sub _days_in_month {
    my ($y, $m) = @_;
    return 31 if $m == 1 || $m == 3 || $m == 5 || $m == 7 || $m == 8 || $m == 10 || $m == 12;
    return 30 if $m == 4 || $m == 6 || $m == 9 || $m == 11;
    if ($m == 2) {
        return ((($y % 4 == 0) && ($y % 100 != 0)) || ($y % 400 == 0)) ? 29 : 28;
    }
    return 0;
}

sub _validate_date {
    my ($s) = @_;
    die "invalid date format\n"
        if length($s) != 10 || substr($s,4,1) ne '-' || substr($s,7,1) ne '-';
    for my $i (0,1,2,3,5,6,8,9) {
        die "date must be all digits\n" if substr($s,$i,1) !~ /\d/;
    }
    my $y = int(substr($s,0,4));
    my $mo = int(substr($s,5,2));
    my $d = int(substr($s,8,2));
    die "month out of range\n" if $mo < 1 || $mo > 12;
    die "day out of range\n" if $d < 1 || $d > _days_in_month($y, $mo);
}

sub _validate_time {
    my ($s) = @_;
    die "invalid time format\n"
        if length($s) != 8 || substr($s,2,1) ne ':' || substr($s,5,1) ne ':';
    for my $i (0,1,3,4,6,7) {
        die "time must be all digits\n" if substr($s,$i,1) !~ /\d/;
    }
    my $h = int(substr($s,0,2));
    my $m = int(substr($s,3,2));
    my $sec = int(substr($s,6,2));
    die "hour out of range\n" if $h > 23;
    die "minute out of range\n" if $m > 59;
    die "second out of range (leap seconds not supported)\n" if $sec > 59;
}

sub parse_datetime_value {
    my $self = shift;
    my $rest = substr($self->{src}, $self->{pos});
    my $date = substr($rest, 0, 10);
    eval { _validate_date($date); };
    if ($@) { my $msg = $@; chomp $msg; $self->_die($msg); }
    my $rest2 = substr($rest, 10);
    if (substr($rest2,0,1) ne 'T' && substr($rest2,0,1) ne ' ') {
        if (substr($rest2,0,1) eq 't') {
            $self->_die("date and time separator must be uppercase 'T' (lowercase 't' not permitted)");
        }
        my $after = substr($rest2,0,1);
        $after = undef if $after eq '';
        $self->_die("invalid character after date") unless _is_value_terminator($after);
        $self->{pos} += 10;
        return DMS::Parser::LocalDate->new($date);
    }
    if (substr($rest2,0,1) eq ' ') {
        (my $after_ws = $rest2) =~ s/\A[ \t]+//;
        if (length($after_ws) > 0 && substr($after_ws, 0, 1) =~ /\d/) {
            $self->_die("date and time must be separated by 'T' (space not permitted)");
        }
        $self->{pos} += 10;
        return DMS::Parser::LocalDate->new($date);
    }
    my $after_t = substr($rest2, 1);
    $self->_die("expected HH:MM:SS after 'T'") unless _looks_like_time_prefix($after_t);
    my $time_str = substr($after_t, 0, 8);
    eval { _validate_time($time_str); };
    if ($@) { my $msg = $@; chomp $msg; $self->_die($msg); }
    my $consumed = 10 + 1 + 8;
    my $after_time = substr($rest, $consumed);
    my $frac_len = 0;
    if (substr($after_time,0,1) eq '.') {
        my $k = 1;
        while ($k < length($after_time) && substr($after_time,$k,1) =~ /\d/) { $k++; }
        my $digits = $k - 1;
        $self->_die("expected fractional digits after '.'") if $digits == 0;
        $self->_die("fractional seconds limited to 9 digits (nanosecond precision)") if $digits > 9;
        $frac_len = $k;
    }
    $consumed += $frac_len;
    my $after_frac = substr($rest, $consumed);
    if (substr($after_frac,0,1) eq 'Z' || substr($after_frac,0,1) eq 'z') {
        $consumed += 1;
        my $s = substr($rest, 0, $consumed);
        $self->{pos} += $consumed;
        return DMS::Parser::OffsetDateTime->new($s);
    }
    if (substr($after_frac,0,1) eq '+' || substr($after_frac,0,1) eq '-') {
        if (length($after_frac) < 6
            || substr($after_frac,1,1) !~ /\d/ || substr($after_frac,2,1) !~ /\d/
            || substr($after_frac,3,1) ne ':'
            || substr($after_frac,4,1) !~ /\d/ || substr($after_frac,5,1) !~ /\d/) {
            $self->_die("invalid offset; expected ±HH:MM");
        }
        my $oh = int(substr($after_frac,1,2));
        my $om = int(substr($after_frac,4,2));
        $self->_die("offset out of range") if $oh > 23 || $om > 59;
        $consumed += 6;
        my $s = substr($rest, 0, $consumed);
        $self->{pos} += $consumed;
        return DMS::Parser::OffsetDateTime->new($s);
    }
    my $after = substr($after_frac,0,1);
    $after = undef if $after eq '';
    $self->_die("invalid character after datetime") unless _is_value_terminator($after);
    my $s = substr($rest, 0, $consumed);
    $self->{pos} += $consumed;
    return DMS::Parser::LocalDateTime->new($s);
}

sub parse_local_time_value {
    my $self = shift;
    my $rest = substr($self->{src}, $self->{pos});
    my $time_str = substr($rest, 0, 8);
    eval { _validate_time($time_str); };
    if ($@) { my $msg = $@; chomp $msg; $self->_die($msg); }
    my $consumed = 8;
    my $after = substr($rest, $consumed);
    if (substr($after,0,1) eq '.') {
        my $k = 1;
        while ($k < length($after) && substr($after,$k,1) =~ /\d/) { $k++; }
        my $digits = $k - 1;
        $self->_die("expected fractional digits after '.'") if $digits == 0;
        $self->_die("fractional seconds limited to 9 digits") if $digits > 9;
        $consumed += $k;
    }
    my $after2 = substr($rest, $consumed);
    my $nxt = substr($after2,0,1);
    $nxt = undef if $nxt eq '';
    $self->_die("invalid character after time") unless _is_value_terminator($nxt);
    my $s = substr($rest, 0, $consumed);
    $self->{pos} += $consumed;
    return DMS::Parser::LocalTime->new($s);
}

sub parse_basic_string_value {
    my $self = shift;
    my ($sl, $sls, $sp) = ($self->{line}, $self->{line_start}, $self->{pos});
    $self->{pos}++;
    my $out = '';
    my $src = $self->{src};
    my $len = $self->{len};
    pos($src) = $self->{pos};
    while (1) {
        # Bulk-scan a run of safe characters (anything but ", \, or line-end)
        # in one regex op. The previous per-char _peek loop did O(N) Perl-VM
        # round-trips; this reduces typical string parsing to a single regex
        # plus per-escape handling. parse_basic_string_value was the
        # heaviest leaf at 19% of decode time on bench_realistic.
        if ($src =~ /\G([^"\\\n\r]*)/gc) {
            $out .= $1 if length($1);
        }
        my $p = pos($src);
        if ($p >= $len) {
            $self->{pos} = $p;
            die $self->_err_at($sl, $sls, $sp, "unterminated string");
        }
        my $c = substr($src, $p, 1);
        if ($c eq '"') {
            $self->{pos} = $p + 1;
            # SPEC §Unicode normalization: re-NFC after escape decoding.
            return $out !~ /[^\x00-\x7F]/ ? $out : _NFC($out);
        }
        if ($c eq "\n" || $c eq "\r") {
            $self->{pos} = $p;
            $self->_die("strings cannot span lines");
        }
        # $c is '\\' — handle the escape, then resume the bulk scan.
        $p++;  # past the backslash
        if ($p >= $len) {
            $self->{pos} = $p;
            $self->_die("unterminated escape");
        }
        my $esc = substr($src, $p, 1);
        $p++;
        if    ($esc eq '"')  { $out .= '"'; }
        elsif ($esc eq '\\') { $out .= '\\'; }
        elsif ($esc eq 'n')  { $out .= "\n"; }
        elsif ($esc eq 't')  { $out .= "\t"; }
        elsif ($esc eq 'r')  { $out .= "\r"; }
        elsif ($esc eq 'b')  { $out .= "\b"; }
        elsif ($esc eq 'f')  { $out .= "\f"; }
        elsif ($esc eq 'u' || $esc eq 'U') {
            # _read_hex_codepoint reads from $self->{pos}; sync it first.
            $self->{pos} = $p;
            $out .= $self->_read_hex_codepoint($esc eq 'u' ? 4 : 8);
            $p = $self->{pos};
        }
        else {
            $self->{pos} = $p;
            $self->_die("invalid escape '\\$esc'");
        }
        pos($src) = $p;
    }
}

sub parse_literal_string_value {
    my $self = shift;
    my ($sl, $sls, $sp) = ($self->{line}, $self->{line_start}, $self->{pos});
    $self->{pos}++;
    my $out = '';
    while (1) {
        if ($self->_eof) {
            die $self->_err_at($sl, $sls, $sp, "unterminated string");
        }
        my $c = $self->_peek;
        $self->_die("strings cannot span lines") if $c eq "\n" || $c eq "\r";
        if ($c eq "'") { $self->{pos}++; return $out; }
        $self->{pos}++;
        $out .= $c;
    }
}

sub _read_hex_codepoint {
    my ($self, $n) = @_;
    my $rest = substr($self->{src}, $self->{pos});
    $self->_die("expected $n hex digits in unicode escape") if length($rest) < $n;
    my $hex = substr($rest, 0, $n);
    $self->_die("invalid hex in unicode escape: $hex") if $hex !~ /^[0-9a-fA-F]+$/;
    my $v = hex($hex);
    # SPEC: U+0000 is forbidden anywhere in DMS source, including via
    # escape decoding. ` ` / `\U00000000` must not slip through.
    if ($v == 0) {
        $self->_die("\\u0000 escape forbidden");
    }
    if ($v >= 0xD800 && $v <= 0xDFFF) {
        $self->_die(sprintf("surrogate codepoint U+%04X in escape", $v));
    }
    if ($v > 0x10FFFF) {
        $self->_die("unicode escape is not a scalar value");
    }
    $self->{pos} += $n;
    return chr($v);
}

# Heredocs

sub parse_heredoc_basic {
    my $self = shift;
    $self->{pos} += 3;
    my $label = $self->_parse_heredoc_label;
    my $mods = $self->_parse_heredoc_modifiers;
    $self->_skip_inline_ws;
    if (!($self->_consume_eol || $self->_eof)) {
        $self->_die("heredoc opener must be followed by end of line");
    }
    my $terminator = length($label) ? $label : '"""';
    my $body = $self->_collect_heredoc_body($terminator);
    # SPEC §basic-string escapes: surrogate codepoints (U+D800..U+DFFF)
    # and U+0000 are not valid in `\uXXXX` / `\UXXXXXXXX` escapes.
    # Basic-heredoc bodies are kept raw, so we validate the rules by
    # scanning the body for offending escape sequences.
    _validate_heredoc_basic_escapes($body);
    my $stripped = _strip_indent_and_continuations($body, 1);
    my $out;
    eval { $out = _apply_modifiers($stripped, $mods); };
    if ($@) { my $msg = $@; chomp $msg; $self->_die($msg); }
    $self->_record_form({
        string_form => {
            kind => 'heredoc',
            flavor => 'basic_triple',
            label => (length($label) ? $label : undef),
            modifiers => [ map { { name => $_->{name}, args => $_->{args} } } @$mods ],
        },
    });
    # SPEC §Unicode normalization: re-NFC after escape decoding.
    return $out !~ /[^\x00-\x7F]/ ? $out : _NFC($out);
}

# SPEC §basic-string escapes: a `\uXXXX` / `\UXXXXXXXX` escape whose
# decoded value falls in the surrogate range U+D800..U+DFFF is not a
# Unicode scalar and is a parse error. Likewise U+0000 is forbidden.
# Basic-heredoc body lines are collected raw, so we validate the same
# rules by scanning the body for offending escape sequences.
sub _validate_heredoc_basic_escapes {
    my ($body) = @_;
    for my $ln (@{$body->{lines}}) {
        my $text = $ln->{text};
        my $len = length($text);
        my $i = 0;
        while ($i < $len) {
            if (substr($text, $i, 1) eq '\\') {
                # find run of consecutive backslashes
                my $j = $i;
                while ($j < $len && substr($text, $j, 1) eq '\\') { $j++; }
                my $run = $j - $i;
                if ($run % 2 == 1 && $j < $len) {
                    my $intro = substr($text, $j, 1);
                    my $n = ($intro eq 'u') ? 4 : ($intro eq 'U') ? 8 : 0;
                    if ($n > 0 && $j + 1 + $n <= $len) {
                        my $hex = substr($text, $j + 1, $n);
                        if ($hex =~ /^[0-9a-fA-F]+$/) {
                            my $cp = hex($hex);
                            my $esc_off = $j - 1;
                            if ($cp == 0) {
                                die sprintf("%d:%d: \\u0000 escape forbidden\n",
                                    $ln->{line}, $esc_off + 1);
                            }
                            if ($cp >= 0xD800 && $cp <= 0xDFFF) {
                                die sprintf("%d:%d: surrogate codepoint U+%04X in escape\n",
                                    $ln->{line}, $esc_off + 1, $cp);
                            }
                        }
                    }
                }
                $i = $j;
            } else {
                $i++;
            }
        }
    }
}

sub parse_heredoc_literal {
    my $self = shift;
    $self->{pos} += 3;
    my $label = $self->_parse_heredoc_label;
    my $mods = $self->_parse_heredoc_modifiers;
    $self->_skip_inline_ws;
    if (!($self->_consume_eol || $self->_eof)) {
        $self->_die("heredoc opener must be followed by end of line");
    }
    my $terminator = length($label) ? $label : "'''";
    my $body = $self->_collect_heredoc_body($terminator);
    my $stripped = _strip_indent_and_continuations($body, 0);
    my $out;
    eval { $out = _apply_modifiers($stripped, $mods); };
    if ($@) { my $msg = $@; chomp $msg; $self->_die($msg); }
    $self->_record_form({
        string_form => {
            kind => 'heredoc',
            flavor => 'literal_triple',
            label => (length($label) ? $label : undef),
            modifiers => [ map { { name => $_->{name}, args => $_->{args} } } @$mods ],
        },
    });
    return $out;
}

sub _parse_heredoc_label {
    my $self = shift;
    my $c = $self->_peek;
    return '' if !_is_label_start($c);
    my $start = $self->{pos};
    while (1) {
        my $c2 = $self->_peek;
        last if !_is_label_cont($c2);
        $self->{pos}++;
    }
    return substr($self->{src}, $start, $self->{pos} - $start);
}

sub _parse_heredoc_modifiers {
    my $self = shift;
    my @mods;
    while (1) {
        my $ws_start = $self->{pos};
        $self->_skip_inline_ws;
        my $had_ws = $self->{pos} > $ws_start;
        my $c = $self->_peek;
        if (defined($c) && _is_label_start($c)) {
            $self->_die("modifier must be preceded by whitespace") unless $had_ws;
            push @mods, $self->_parse_one_modifier;
        } else {
            $self->{pos} = $ws_start;
            return \@mods;
        }
    }
}

sub _parse_one_modifier {
    my $self = shift;
    my $ns = $self->{pos};
    while (1) {
        my $c = $self->_peek;
        last if !_is_label_cont($c);
        $self->{pos}++;
    }
    my $name = substr($self->{src}, $ns, $self->{pos} - $ns);
    $self->_die("modifiers require parentheses") if $self->_peek ne '(';
    $self->{pos}++;
    # Suppress original-form recording for modifier args: they're
    # parse-time values used as call arguments and must not pollute the
    # host heredoc node's original_forms slot.
    my $saved = $self->{record_forms};
    $self->{record_forms} = 0;
    my @args;
    my $ok = eval {
        while (1) {
            $self->_skip_inline_ws;
            if ($self->_peek eq ')') { $self->{pos}++; last; }
            push @args, $self->parse_inline_value_or_heredoc;
            $self->_skip_inline_ws;
            my $c = $self->_peek;
            if ($c eq ',') { $self->{pos}++; }
            elsif ($c eq ')') { $self->{pos}++; last; }
            else { $self->_die("expected ',' or ')' in modifier args"); }
        }
        1;
    };
    my $err = $@;
    $self->{record_forms} = $saved;
    die $err if !$ok;
    return { name => $name, args => \@args };
}

sub _collect_heredoc_body {
    my ($self, $terminator) = @_;
    my @lines;
    my ($sl, $sls, $sp) = ($self->{line}, $self->{line_start}, $self->{pos});
    while (1) {
        if ($self->_eof) {
            die $self->_err_at($sl, $sls, $sp, "unterminated heredoc");
        }
        my $lb = $self->{pos};
        while (1) {
            my $c = $self->_peek;
            last if !defined($c) || $c eq "\n" || $c eq "\r";
            $self->{pos}++;
        }
        my $raw = substr($self->{src}, $lb, $self->{pos} - $lb);
        my ($this_line, $this_lstart) = ($self->{line}, $self->{line_start});
        my $trimmed = $raw; $trimmed =~ s/^\s+|\s+$//g;
        if ($trimmed eq $terminator) {
            my $strip_depth = 0;
            for my $c (split //, $raw) {
                if ($c eq ' ') { $strip_depth++; } else { last; }
            }
            return { lines => \@lines, strip_depth => $strip_depth };
        }
        $self->_consume_eol;
        push @lines, { text => $raw, line => $this_line, line_start => $this_lstart };
    }
}

sub _strip_indent_and_continuations {
    my ($body, $allow_cont) = @_;
    my @out;
    my $first = 1;
    my $pending = 0;
    my @last = (1, 0);
    for my $ln (@{$body->{lines}}) {
        @last = ($ln->{line}, $ln->{line_start});
        my $is_blank = ($ln->{text} =~ /\A[ \t]*\z/);
        my $stripped;
        if ($is_blank) {
            $stripped = '';
        } else {
            my $leading = 0;
            for my $c (split //, $ln->{text}) {
                if ($c eq ' ') { $leading++; } else { last; }
            }
            if ($leading < $body->{strip_depth}) {
                die sprintf("%d:%d: heredoc body line indented %d spaces, less than strip depth %d\n",
                    $ln->{line}, $leading + 1, $leading, $body->{strip_depth});
            }
            $stripped = substr($ln->{text}, $body->{strip_depth});
        }
        my $piece = $stripped;
        my $splice = 0;
        if ($allow_cont) {
            my $trimmed_end = $piece; $trimmed_end =~ s/[ \t]+$//;
            my $idx = rindex($trimmed_end, '\\');
            if ($idx != -1 && $idx == length($trimmed_end) - 1) {
                my $preceding = 0;
                for (my $k = $idx - 1; $k >= 0 && substr($trimmed_end,$k,1) eq '\\'; $k--) {
                    $preceding++;
                }
                if ($preceding % 2 == 0) {
                    $piece = substr($trimmed_end, 0, $idx);
                    $splice = 1;
                }
            }
        }
        if ($first) {
            push @out, $piece;
            $first = 0;
        } elsif ($pending) {
            my $trimmed_start = $piece; $trimmed_start =~ s/^[ \t]+//;
            push @out, $trimmed_start unless $is_blank;
        } else {
            push @out, "\n", $piece;
        }
        $pending = $splice;
    }
    if ($pending) {
        die sprintf("%d:1: trailing line continuation has nothing to splice to\n", $last[0]);
    }
    return join('', @out);
}

sub _fold_paragraphs {
    my ($s) = @_;
    my @paras = split /\n\n/, $s, -1;
    return join("\n", map {
        join(' ', grep { length($_) } split /\n/, $_, -1);
    } @paras);
}

sub _replace_all_runs {
    my ($s, $charset, $replacement) = @_;
    my $out = '';
    my @chars = split //, $s;
    my $i = 0;
    while ($i < @chars) {
        if ($charset->{$chars[$i]}) {
            while ($i < @chars && $charset->{$chars[$i]}) { $i++; }
            $out .= $replacement;
        } else {
            $out .= $chars[$i];
            $i++;
        }
    }
    return $out;
}

sub _replace_leading_run {
    my ($s, $charset, $replacement) = @_;
    my @chars = split //, $s;
    my $end = 0;
    while ($end < @chars && $charset->{$chars[$end]}) { $end++; }
    return $s if $end == 0;
    return $replacement . join('', @chars[$end..$#chars]);
}

sub _replace_trailing_run {
    my ($s, $charset, $replacement) = @_;
    my @chars = split //, $s;
    my $start = scalar @chars;
    while ($start > 0 && $charset->{$chars[$start-1]}) { $start--; }
    return $s if $start == @chars;
    return join('', @chars[0..$start-1]) . $replacement;
}

sub _per_line_edges {
    my ($s, $charset, $replacement) = @_;
    my @lines = split /\n/, $s, -1;
    for my $line (@lines) {
        $line = _replace_leading_run($line, $charset, $replacement);
        $line = _replace_trailing_run($line, $charset, $replacement);
    }
    return join("\n", @lines);
}

sub _apply_trim {
    my ($s, $chars, $where, $replacement) = @_;
    return $s if length($chars) == 0;
    my %charset = map { $_ => 1 } split //, $chars;
    my $has_star = (index($where, '*') >= 0);
    my $has_pipe = (index($where, '|') >= 0);
    my $has_lt = (index($where, '<') >= 0);
    my $has_gt = (index($where, '>') >= 0);
    return $s if !($has_star || $has_pipe || $has_lt || $has_gt);
    return _replace_all_runs($s, \%charset, $replacement) if $has_star;
    my $cur = $s;
    $cur = _per_line_edges($cur, \%charset, $replacement) if $has_pipe;
    $cur = _replace_leading_run($cur, \%charset, $replacement) if $has_lt;
    $cur = _replace_trailing_run($cur, \%charset, $replacement) if $has_gt;
    return $cur;
}

sub _apply_modifiers {
    my ($s, $mods) = @_;
    my $cur = $s;
    for my $m (@$mods) {
        my $name = $m->{name};
        my $args = $m->{args};
        if ($name eq '_fold_paragraphs') {
            die "fold_paragraphs() takes no arguments\n" if @$args;
            $cur = _fold_paragraphs($cur);
        } elsif ($name eq '_trim') {
            die qq{trim(chars, where, replacement = "") expects 2 or 3 arguments\n}
                if @$args < 2 || @$args > 3;
            my $chars = $args->[0];
            die "trim: first argument (chars) must be a string\n" if ref($chars) ne '';
            my $where = $args->[1];
            die "trim: second argument (where) must be a string\n" if ref($where) ne '';
            my $replacement = '';
            if (@$args == 3) {
                die "trim: third argument (replacement) must be a string\n" if ref($args->[2]) ne '';
                $replacement = $args->[2];
            }
            $cur = _apply_trim($cur, $chars, $where, $replacement);
        } else {
            die "unknown modifier: $name\n";
        }
    }
    return $cur;
}

# Flow forms

sub parse_flow_array {
    my $self = shift;
    $self->{pos}++;
    my @items;
    while (1) {
        $self->_skip_flow_ws;
        if ($self->_peek eq ']') { $self->{pos}++; return \@items; }
        # Push the current index onto the path so any OriginalLiteral
        # records inside the flow value get the right breadcrumb.
        my $idx = scalar @items;
        push @{$self->{path}}, DMS::Parser::Index->new($idx);
        my $v;
        my $ok = eval { $v = $self->_parse_inline_value_in_flow; 1 };
        my $err = $@;
        pop @{$self->{path}};
        if (!$ok) { die $err; }
        push @items, $v;
        $self->_skip_flow_ws;
        my $c = $self->_peek;
        if ($c eq ',') { $self->{pos}++; }
        elsif ($c eq ']') { $self->{pos}++; return \@items; }
        elsif (!defined($c)) { $self->_die("unterminated flow array"); }
        else { $self->_die("unexpected '$c' in flow array; expected ',' or ']'"); }
    }
}

sub parse_flow_table {
    my $self = shift;
    $self->{pos}++;
    my $lite = $self->{lite};
    my $ignore_order = $self->{ignore_order};
    my ($t, $order);
    if ($ignore_order) {
        $t = new_unordered_table();
    } elsif ($lite) {
        $order = [];
        $t = { $ORDER_KEY => $order };
    } else {
        $t = new_table();
    }
    while (1) {
        $self->_skip_flow_ws;
        if ($self->_peek eq '}') { $self->{pos}++; return $t; }
        my $key = $self->parse_key;
        $self->_die("expected ':' after flow-table key") if $self->_peek ne ':';
        $self->{pos}++;
        my $c = $self->_peek;
        if (!defined($c) || ($c ne ' ' && $c ne "\t" && $c ne "\n" && $c ne "\r")) {
            $self->_die("expected whitespace after ':'");
        }
        $self->_skip_flow_ws;
        # Path push so OriginalLiteral records inside the value get the
        # key path as their breadcrumb.
        push @{$self->{path}}, $key unless $lite;
        my $v;
        if ($lite) {
            $v = $self->_parse_inline_value_in_flow;
        } else {
            my $ok = eval { $v = $self->_parse_inline_value_in_flow; 1 };
            my $err = $@;
            pop @{$self->{path}};
            if (!$ok) { die $err; }
        }
        $self->_die("duplicate key: $key") if exists $t->{$key};
        push @$order, $key if $order;
        $t->{$key} = $v;
        $self->_skip_flow_ws;
        my $c2 = $self->_peek;
        if ($c2 eq ',') { $self->{pos}++; }
        elsif ($c2 eq '}') { $self->{pos}++; return $t; }
        elsif (!defined($c2)) { $self->_die("unterminated flow table"); }
        else { $self->_die("unexpected '$c2' in flow table; expected ',' or '}'"); }
    }
}

sub _skip_flow_ws {
    my $self = shift;
    while (1) {
        pos($self->{src}) = $self->{pos};
        if ($self->{src} =~ /\G[ \t]+/gc) {
            $self->{pos} = pos($self->{src});
        }
        return if $self->{pos} >= $self->{len};
        my $c = substr($self->{src}, $self->{pos}, 1);
        if ($c eq "\n") { $self->{pos}++; $self->_advance_line; next; }
        if ($c eq "\r") {
            if (substr($self->{src}, $self->{pos}, 2) eq "\r\n") {
                $self->{pos} += 2; $self->_advance_line; next;
            }
            return;
        }
        if ($c eq '#') { $self->_die("comments not allowed inside flow forms"); }
        if ($c eq '/') {
            my $n = substr($self->{src}, $self->{pos} + 1, 1);
            if ($n eq '/' || $n eq '*') {
                $self->_die("comments not allowed inside flow forms");
            }
        }
        return;
    }
}

sub _parse_inline_value_in_flow {
    my $self = shift;
    if ($self->_peek eq '"' && $self->_starts_with('"""')) {
        $self->_die("heredocs are not allowed inside flow forms");
    }
    if ($self->_peek eq "'" && $self->_starts_with("'''")) {
        $self->_die("heredocs are not allowed inside flow forms");
    }
    return $self->parse_inline_value_or_heredoc;
}

sub _consume_after_value {
    my ($self, $allow_eof) = @_;
    # Hot-path early-out for the no-comment case (every flat-table leaf):
    # check the byte at pos. Common case: directly at \n with no
    # trailing WS — return after one substr + branch. _advance_line is
    # inlined too so the hot path has zero method calls.
    my $hot_had_ws = 0;
    my $p = $self->{pos};
    {
        if ($p >= $self->{len}) { return; }
        my $c = substr($self->{src}, $p, 1);
        if ($c eq "\n") {
            my $np = $p + 1;
            $self->{pos} = $np;
            $self->{line}++;
            $self->{line_start} = $np;
            return;
        }
        if ($c eq ' ' || $c eq "\t") {
            # Have trailing WS: skip it, then re-check.
            pos($self->{src}) = $p;
            $self->{src} =~ /\G[ \t]+/gc;
            $self->{pos} = pos($self->{src});
            $hot_had_ws = 1;
            $p = $self->{pos};
            if ($p >= $self->{len}) { return; }
            $c = substr($self->{src}, $p, 1);
            if ($c eq "\n") {
                my $np = $p + 1;
                $self->{pos} = $np;
                $self->{line}++;
                $self->{line_start} = $np;
                return;
            }
        }
        if ($c ne '#' && $c ne '/' && $c ne "\r") {
            $self->_die("unexpected character '$c' after value");
        }
        # else fall through to the comment-handling slow path. Pass
        # $hot_had_ws so the first iteration knows ws was already consumed.
    }
    # Same-line comment(s) after a value attach as `trailing`. Multiple
    # block comments may stack; a `#`/`//` line comment, if present,
    # consumes to EOL and must come last.
    my $first_iter = 1;
    while (1) {
        my $ws_start = $self->{pos};
        $self->_skip_inline_ws;
        my $had_ws = $self->{pos} > $ws_start;
        $had_ws = 1 if $first_iter && $hot_had_ws;
        $first_iter = 0;
        my $c = $self->_peek;
        if (defined($c) && $c eq '#' && !$self->_starts_with("###")) {
            $self->_die("expected whitespace before '#' comment") unless $had_ws;
            my $raw = $self->_read_line_comment_to_eol;
            push @{$self->{comments}}, {
                comment  => { content => $raw, kind => 'line' },
                position => 'trailing',
                path     => [@{$self->{path}}],
            } unless $self->{lite};
            last;
        } elsif (defined($c) && $c eq '/' && $self->_starts_with("//")) {
            $self->_die("expected whitespace before '//' comment") unless $had_ws;
            my $raw = $self->_read_line_comment_to_eol;
            push @{$self->{comments}}, {
                comment  => { content => $raw, kind => 'line' },
                position => 'trailing',
                path     => [@{$self->{path}}],
            } unless $self->{lite};
            last;
        } elsif (defined($c) && $c eq '/' && $self->_starts_with("/*")) {
            my $raw = $self->_read_c_block_comment;
            push @{$self->{comments}}, {
                comment  => { content => $raw, kind => 'block' },
                position => 'trailing',
                path     => [@{$self->{path}}],
            } unless $self->{lite};
            next;
        } else {
            last;
        }
    }
    my $c = $self->_peek;
    return if !defined($c);
    if ($c eq "\n") { $self->{pos}++; $self->_advance_line; return; }
    if ($c eq "\r" && $self->_starts_with("\r\n")) { $self->{pos} += 2; $self->_advance_line; return; }
    $self->_die("unexpected character '$c' after value");
}

1;

__END__

=encoding UTF-8

=head1 NAME

DMS::Parser - Pure-Perl parser for DMS, a data syntax with strong typing,
ordered maps, multi-line heredocs, and front-matter metadata

=head1 SYNOPSIS

  use DMS::Parser;

  my $src = do { local $/; <STDIN> };
  my $doc = DMS::Parser::decode($src);

  # Keep metadata and comments
  my $full = DMS::Parser::decode_document($src);

  # Tier-1 (decorator-aware) parse
  my $t1 = DMS::Parser::decode_t1($src);

  # Round-trip via the emitter
  use DMS::Parser::Emitter;
  print DMS::Parser::Emitter::encode($full);

=head1 DESCRIPTION

DMS (Data Meta Syntax) is a config and data format. This module is the
pure-Perl reference parser. It produces native Perl values plus a small
set of blessed type sentinels for DMS scalars that do not map cleanly to
Perl bare scalar types (booleans, integer-vs-float distinction, dates).

For the language specification see L<https://gitlab.com/flo-labs/pub/dms>.

=head1 FUNCTIONS

=head2 decode($src)

Decode a DMS source string. Returns a Perl value tree where:

=over 4

=item * Tables become C<HASH> references (insertion-ordered via Tie::IxHash).

=item * Lists become C<ARRAY> references.

=item * Strings become plain Perl scalars.

=item * DMS scalars without a clean Perl analogue become blessed type sentinels
(see L</TYPE SENTINELS>).

=back

Throws on parse error with a C<line:col: message> diagnostic.

=head2 decode_document($src)

Like L</decode> but returns a Document hashref with keys C<body>, C<meta>,
C<comments>, and C<original_forms>. Needed for full round-trip emit via
L<DMS::Parser::Emitter>.

=head2 decode_lite($src)

Like L</decode> but skips comment and literal-form tracking. ~2x faster on
large documents. Body values are identical to C<decode>.

=head2 decode_lite_document($src)

Like L</decode_document> but lite mode (no comment/form tracking).

=head2 decode_front_matter($src)

Parse only the front-matter block C<+++ ... +++>. Returns a hashref or
C<undef> when the document has no front matter.

=head2 decode_t1($src)

Tier-1 parse (decorator-aware). Returns a hashref with keys C<tier>,
C<imports>, C<body>, C<decorators>, and C<_raw_doc>.
See L<DMS::Parser::Tier1> for the full schema.

=head1 TYPE SENTINELS

The following blessed classes are returned for DMS scalar types that have no
clean Perl analogue. All are blessed scalar refs (one allocation per value).

=head2 DMS::Parser::Bool

DMS C<true> / C<false>. C<value()> returns 1 or 0.

=head2 DMS::Parser::Integer

DMS integer. On 64-bit Perl stored as a native IV. Methods: C<value()>,
C<bstr()> (decimal string), C<is_neg()>.

=head2 DMS::Parser::Float

DMS float. C<value()> returns the NV.

=head2 DMS::Parser::LocalDate

DMS local date (e.g. C<2024-01-15>). C<value()> returns the string.

=head2 DMS::Parser::LocalTime

DMS local time (e.g. C<14:30:00>). C<value()> returns the string.

=head2 DMS::Parser::LocalDateTime

DMS local date-time (e.g. C<2024-01-15T14:30:00>). C<value()> returns the string.

=head2 DMS::Parser::OffsetDateTime

DMS offset date-time (e.g. C<2024-01-15T14:30:00Z>). C<value()> returns the string.

=head2 DMS::Parser::Index

Path-segment marker distinguishing list-index steps from string-key steps in
comment path arrays. C<value()> returns the integer index.

=head2 DMS::Parser::UnorderedTable

Marker class for body tables from the C<*_unordered> entry points. Underlying
storage is a plain hashref (no Tie::IxHash). C<encode> (full mode) refuses to
round-trip a Document containing this type; use C<encode_lite>.

=head1 SEE ALSO

=over 4

=item * L<DMS::Parser::Emitter> - round-trip emitter

=item * L<DMS::Parser::Tier1> - tier-1 helpers (decorator-call lex, sigil
recognition, _dms_imports validation)

=item * L<DMS::Parser::XS> - XS bridge to the C reference parser for ~20x
speedup on large documents

=item * L<https://gitlab.com/flo-labs/pub/dms> - DMS language specification

=back

=head1 AUTHOR

Filip Lopes

=head1 LICENSE

Dual-licensed under the Apache License 2.0 and the MIT license, at your option.

=cut
