use strictures 1;
package Chart::Weather::Forecast;
BEGIN {
  $Chart::Weather::Forecast::VERSION = '0.04';
}
use Moose;
use namespace::autoclean;


__PACKAGE__->meta->make_immutable;
1
