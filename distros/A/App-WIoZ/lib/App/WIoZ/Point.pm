use strict;
use warnings;
package App::WIoZ::Point;
{
  $App::WIoZ::Point::VERSION = '0.004';
}
use Moose;

has ['x','y'] => (
    is => 'rw', isa => 'Int'
    );

1;
