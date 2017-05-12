use utf8;
use strict;
use warnings;

package DR::Tnt::Msgpack::Types;
use base 'Exporter';

use DR::Tnt::Msgpack::Types::Int;
use DR::Tnt::Msgpack::Types::Str;
use DR::Tnt::Msgpack::Types::Blob;
use DR::Tnt::Msgpack::Types::Bool;

our %EXPORT_TAGS = (
    'all'     => [
        'mp_int',
        'mp_bool',
        'mp_string',
        'mp_blob',

        'mp_true',
        'mp_false',
    ]
);

our @EXPORT_OK = @{ $EXPORT_TAGS{all} };


sub mp_int($) {
    DR::Tnt::Msgpack::Types::Int->new($_[0]);
}
sub mp_string($) {
    DR::Tnt::Msgpack::Types::Str->new($_[0]);
}
sub mp_blob($) {
    DR::Tnt::Msgpack::Types::Blob->new($_[0]);
}

sub mp_bool($) {
    DR::Tnt::Msgpack::Types::Bool->new($_[0]);
}
sub mp_true() {
    DR::Tnt::Msgpack::Types::Bool->new(1);
}
sub mp_false() {
    DR::Tnt::Msgpack::Types::Bool->new(0);
}

=head1 NAME

DR::Tnt::Msgpack::Types - types for msgpack.

=head1 SYNOPSIS

    use DR::Tnt::Msgpack::Types;

    # pack as msgpack INT
    msgpack(mp_int(123));

    # pack number as string
    msgpack(mp_string(123));

    # bools
    msgpack(mp_true);
    msgpack(mp_false);
    msgpack(mp_bool(1));
    msgpack(mp_bool(0));


    # blob
    msgpack(mp_blob $blob);


=head1 DESCRIPTION

Perl doesn't differ C<123> and C<'123'>:

    msgpack(123);
    msgpack('123'); # the same

From time to time You want to pack numbers as strings (for example You
use tarantool's STR-index for user's texts, that contain numbers, too).

So You can use C<mp_string($)> constructor for L<DR::Tnt::Msgpack::Types::Str>.

=head1 METHODS

=over

=item mp_int($)

Create L<DR::Tnt::Msgpack::Types::Int> object. Its method C<TO_MSGPACK>
packs number as msgpack signed integer value.

=item mp_string($)

Create L<DR::Tnt::Msgpack::Types::Str> object. Its method C<TO_MSGPACK>
packs perl scalar as msgpack string.

=item mp_blob($)

Create L<DR::Tnt::Msgpack::Types::Blob> object. Its method C<TO_MSGPACK>
packs perl scalar as msgpack bin object.

=item mp_bool($) and shortcuts mp_true/mp_false

Create L<DR::Tnt::Msgpack::Types::Bool> object. Its method C<TO_MSGPACK>
package perl scalar as msgpack boolean.

=back

=cut
1;
