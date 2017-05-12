use Glib qw/ TRUE FALSE /;
use Clutter;

Clutter::init;

my $stage = Clutter::Stage->new();
$stage->signal_connect('destroy' => sub { Clutter::main_quit });
$stage->set_title('Three flowers in a vase');
$stage->set_user_resizable(TRUE);

my $vase = Clutter::Actor->new();
$vase->set_layout_manager(Clutter::BoxLayout->new());
$vase->set_background_color(Clutter::color_get_static('sky-blue-light'));
$vase->add_constraint(Clutter::AlignConstraint->new($stage, 'both', 0.5));
$stage->add_child($vase);

my %flowers = ();

$flowers{'red'} = Clutter::Actor->new();
$flowers{'red'}->set_name('flowers.1');
$flowers{'red'}->set_size(128, 128);
$flowers{'red'}->set_margin_left(12);
$flowers{'red'}->set_background_color(Clutter::color_get_static('red'));
$flowers{'red'}->set_reactive(TRUE);
$flowers{'red'}->signal_connect(button_press_event => sub {
    $flowers{'red'}->save_easing_state();
    $flowers{'red'}->set_easing_duration(500);
    $flowers{'red'}->set_easing_mode('linear');

    if ($flowers{'red'}->{'toggled'}) {
        $flowers{'red'}->set_background_color(Clutter::color_get_static('red'));
        $flowers{'red'}->{'toggled'} = FALSE;
    } else {
        $flowers{'red'}->set_background_color(Clutter::color_get_static('blue'));
        $flowers{'red'}->{'toggled'} = TRUE;
    }

    $flowers{'red'}->restore_easing_state();

    return TRUE;
});
$vase->add_child($flowers{'red'});

$flowers{'yellow'} = Clutter::Actor->new();
$flowers{'yellow'}->set_name('flowers.3');
$flowers{'yellow'}->set_size(128, 128);
$flowers{'yellow'}->set_margin_left(6);
$flowers{'yellow'}->set_margin_top(12);
$flowers{'yellow'}->set_margin_bottom(12);
$flowers{'yellow'}->set_margin_right(6);
$flowers{'yellow'}->set_background_color(Clutter::color_get_static('yellow'));
$flowers{'yellow'}->set_reactive(TRUE);
$flowers{'yellow'}->signal_connect(enter_event => sub {
    my ($self, $event) = @_;

    $self->save_easing_state();
    $self->set_easing_duration(500);
    $self->set_easing_mode('ease-out-bounce');

    $self->set_depth(-250);

    $self->restore_easing_state();

    return TRUE;
});
$flowers{'yellow'}->signal_connect(leave_event => sub {
    my ($self, $event) = @_;

    $self->save_easing_state();
    $self->set_easing_duration(500);
    $self->set_easing_mode('ease-out-bounce');

    $self->set_depth(0);

    $self->restore_easing_state();

    return TRUE;
});
$vase->add_child($flowers{'yellow'});

$flowers{'green'} = Clutter::Actor->new();
$flowers{'green'}->set_name('flowers.2');
$flowers{'green'}->set_size(128, 128);
$flowers{'green'}->set_margin_right(12);
$flowers{'green'}->set_background_color(Clutter::color_get_static('green'));
$flowers{'green'}->set_reactive(TRUE);
$flowers{'green'}->signal_connect(button_press_event => sub {
    my ($self, $event) = @_;

    $self->save_easing_state();
    $self->set_easing_duration(1000);
    $self->set_rotation('y-axis', 360.0, $self->get_width() / 2, 0, 0);

    $self->get_transition('rotation-angle-y')->signal_connect(completed => sub {
        $self->save_easing_state();
        $self->set_rotation('y-axis', 0.0, $self->get_width() / 2, 0, 0);
        $self->restore_easing_state();
    });

    $self->restore_easing_state();

    return TRUE;
});
$vase->add_child($flowers{'green'});

$stage->show;

Clutter::main;

0;
