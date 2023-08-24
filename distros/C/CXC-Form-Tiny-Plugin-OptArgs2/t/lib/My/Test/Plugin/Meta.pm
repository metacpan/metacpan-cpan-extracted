package My::Test::Plugin::Meta;

use Moo::Role;
use experimental 'signatures', 'postderef', 'lexical_subs';

our $VERSION = '0.01';

# flip default so we know it worked.
around _build_inherit_required => sub { !!0 };
around _build_inherit_optargs  => sub { !!1 };

1;

