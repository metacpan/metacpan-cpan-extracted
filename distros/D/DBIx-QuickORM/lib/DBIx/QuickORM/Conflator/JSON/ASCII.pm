package DBIx::QuickORM::Conflator::JSON::ASCII;
use strict;
use warnings;

our $VERSION = '0.000002';

use parent 'DBIx::QuickORM::Conflator::JSON';

use Cpanel::JSON::XS();

my $ASCII = Cpanel::JSON::XS->new->ascii(1)->convert_blessed(1)->allow_nonref(1);
sub JSON { $ASCII }

1;
