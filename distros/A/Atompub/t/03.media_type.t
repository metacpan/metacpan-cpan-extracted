use strict;
use warnings;
#use Data::Dumper; $Data::Dumper::Indent = 1;
use Test::More tests => 37;

use Atompub::MediaType qw(media_type);

my $png = media_type('image/png');
isa_ok $png, 'Atompub::MediaType';

is $png->type, 'image';
is $png->subtype, 'png';
is $png->parameters, undef;

is $png->subtype_major, 'png';

is $png->without_parameters, 'image/png';
is $png->as_string, 'image/png';

is $png->extensions, 'png';
is $png->extension, 'png';

ok $png->is_a('*/*');
ok $png->is_a('image/*');
ok $png->is_a('image/png');

ok $png->is_not_a('text/*');
ok $png->is_not_a('image/jpeg');

is "$png", 'image/png';

ok $png eq '*/*';
ok $png ne 'text/*';

my $atom = media_type('entry');
isa_ok $atom, 'Atompub::MediaType';

is $atom->type, 'application';
is $atom->subtype, 'atom+xml';
is $atom->parameters, 'type=entry';

is $atom->subtype_major, 'xml';

is $atom->without_parameters, 'application/atom+xml';
is $atom->as_string, 'application/atom+xml;type=entry';

is $atom->extensions, 'atom';
is $atom->extension, 'atom';

ok $atom->is_a('*/*');
ok $atom->is_a('application/*');
ok $atom->is_a('application/xml');
ok $atom->is_a('application/atom+xml');
ok $atom->is_a('application/atom+xml;type=entry');

ok $atom->is_not_a('text/*');
ok $atom->is_not_a('application/octet-stream');
ok $atom->is_not_a('application/atom+xml;type=feed');

is "$atom", 'application/atom+xml;type=entry';

ok $atom eq '*/*';
ok $atom ne 'text/*';
