package # hide from the CPAN
    TestApp::Driver::Mock;
use Moose;

with 'Graphics::Primitive::Driver';

sub _do_fill { }

sub _do_stroke { }

sub _draw_arc { }

sub _draw_bezier { }

sub _draw_canvas { }

sub _draw_circle { }

sub _draw_component {
    my ($self, $comp) = @_;

    $self->{DATA} = "Mock: ".$comp->width."x".$comp->height;
}

sub _draw_ellipse { }

sub _draw_line { }

sub _draw_path { }

sub _draw_polygon { }

sub _draw_rectangle { }

sub _draw_textbox { }

sub _finish_page { }

sub _resize { }

sub get_textbox_layout { }

sub reset { }

sub write { }

sub data {
    my ($self) = @_;

    return $self->{DATA};
}

no Moose;
1;