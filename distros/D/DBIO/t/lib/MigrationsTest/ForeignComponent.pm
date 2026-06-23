#   belongs to t/05components.t
package # hide from PAUSE
    MigrationsTest::ForeignComponent;
use warnings;
use strict;

use base qw/ DBIO /;

__PACKAGE__->load_components( qw/ +MigrationsTest::ForeignComponent::TestComp / );

1;
