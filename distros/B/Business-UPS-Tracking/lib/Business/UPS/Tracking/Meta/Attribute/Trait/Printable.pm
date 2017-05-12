# ============================================================================
package Business::UPS::Tracking::Meta::Attribute::Trait::Printable;
# ============================================================================
use utf8;
use 5.0100;

use Moose::Role;

package Moose::Meta::Attribute::Custom::Trait::Printable;
sub register_implementation { return 'Business::UPS::Tracking::Meta::Attribute::Trait::Printable' }

no Moose::Role;
1;
