
package MyHelper;
use Moo;

sub beep {
    my $self = shift;
    my %args = @_;

    return $args{warning} || "beep beep";
}

1;
