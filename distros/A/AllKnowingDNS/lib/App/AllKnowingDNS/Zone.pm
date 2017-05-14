# vim:ts=4:sw=4:expandtab
package App::AllKnowingDNS::Zone;

use Mouse;

has 'network' => (is => 'rw', isa => 'Str');
has 'resolves_to' => (is => 'rw', isa => 'Str');
has 'upstream_dns' => (is => 'rw', isa => 'Str');

# These are set when adding the zone to the ::Config object.
has 'ptrzone' => (is => 'rw', isa => 'Str');
has 'aaaazone' => (is => 'rw', isa => 'Regexp');

__PACKAGE__->meta->make_immutable();

1
