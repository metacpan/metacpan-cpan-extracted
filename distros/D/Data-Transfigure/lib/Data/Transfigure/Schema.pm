package Data::Transfigure::Schema 1.01;
use v5.26;
use warnings;

use Object::Pad;

class Data::Transfigure::Schema : does(Data::Transfigure::Node) {
  use Scalar::Util qw(blessed);
  use Data::Transfigure::Constants;

  field $schema : param;

  ADJUST {
    say blessed($schema);
    say ref($schema);
    die("schema must be a JSON::Validator") unless (blessed($schema) && $schema->isa('JSON::Validator'));
  }

  method applies_to (%params) {
    my $node   = $params{value};
    my @errors = $schema->validate($node);
    # warn @errors if @errors;
    return $NO_MATCH if (@errors);
    return $MATCH_EXACT_VALUE;
  }
}
