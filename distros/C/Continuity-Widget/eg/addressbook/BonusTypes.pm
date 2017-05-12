
# This goop is so that we can use DateTime but pass in a string that gets coerced
package BonusTypes;
use Moose::Role;

use Moose::Util::TypeConstraints;
require DateTime;
subtype 'DateTime'
  => as 'Object'
  => where { $_->isa('DateTime') };

coerce 'DateTime'
  => from 'Str'
  => via {
    require DateTime::Format::DateManip;
    DateTime::Format::DateManip->parse_datetime($_);
  };

1;

