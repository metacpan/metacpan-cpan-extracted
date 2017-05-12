
use strict;
use warnings;

package Circle;

use overload ( '==' => \&equalTo );

use Class::Trait
  "TCircle" => { exclude => 'equalTo' },
  "TColor"  => { exclude => 'equalTo' };

sub new {
    return bless { name => "Circle" } => "Circle";
}

sub getCenter { }
sub getRadius { }
sub setRadius { }
sub setCenter { }

sub getRGB { }
sub setRGB { }

sub equalTo {
    my ( $self, $right ) = @_;
    $self->isSameTypeAs($right);
    return $self->{name} eq $right->{name};
}

1;

__DATA__
