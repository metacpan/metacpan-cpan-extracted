use 5.12.0;

use OpenGL qw/:all/;
use AntTweakBar qw/:all/;
use AntTweakBar::Type;
use Data::Dump qw/dump/;
use Variable::Magic qw/cast wizard/;

sub display {
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glEnable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    glEnable(GL_NORMALIZE);

    AntTweakBar::draw;
    glutSwapBuffers;
    glutPostRedisplay;
}

sub reshape {
    my ($width, $height) = @_;
    glViewport(0, 0, $width, $height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity;
    gluPerspective(40, $width/$height, 1, 10);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity;
    gluLookAt(0,0,5, 0,0,0, 0,1,0);
    glTranslatef(0, 0.6, -1);

    say "window size: ${width} x ${height}";
    AntTweakBar::window_size($width, $height);
}


glutInit;
glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH);
glutInitWindowSize(640, 480);
glutCreateWindow("[perl] AntTweakBar simple example using GLUT");

AntTweakBar::init(TW_OPENGL);

glutDisplayFunc(\&display);
glutReshapeFunc(\&reshape);
glutMouseFunc(\&AntTweakBar::eventMouseButtonGLUT);
glutMotionFunc(\&AntTweakBar::eventMouseMotionGLUT);
glutPassiveMotionFunc(\&AntTweakBar::eventMouseMotionGLUT);
glutKeyboardFunc(\&AntTweakBar::eventKeyboardGLUT);
glutSpecialFunc(\&AntTweakBar::eventSpecialGLUT);
AntTweakBar::GLUTModifiersFunc(\&glutGetModifiers);

reshape(640, 750);

my $bar = AntTweakBar->new("TweakBar & Perl", color => '0 128 0', alpha => 200);
$bar->add_separator("x-sep");

my $custom_type = AntTweakBar::Type->new(
    "custom_arr",
    ["a", "b", "c"],
);

my $bool_ro       = 1;
my $bool_rw       = undef;
my $int_ro        = 100;
my $int_rw        = 200;
my $number_ro     = 3.14;
my $number_rw     = 2.78;
my $string_ro     = "abc";
my $string_rw     = "cde";
my $color3f_ro    = [1.0, 1.0, 0.0];
my $color3f_rw    = [0.5, 0.5, 1.0];
my $color4f_ro    = [1.0, 1.0, 0.0, 0.1];
my $color4f_rw    = [0.5, 0.5, 1.0, 0.2];
my $direction_ro  = [1.0, 0.0, 0.0];
my $direction_rw  = [0.0, 0.0, 1.0];
my $quaternion_ro = [1.0, 0.1, 0.0, 0.0];
my $quaternion_rw = [0.0, 1.0, 1.1, 0.0];
my $custom_ro     = "a";
my $custom_rw     = undef;
my $magic_var_rw  = 1.234;

my $wizzard = wizard(
    set => sub { say "set magic to ", ${$_[0]} },
);

cast $magic_var_rw, $wizzard;

# types: bool, integer, number, string, color3f, color4f, direction, quaternion, custom enums
$bar->add_variable(
    mode       => 'ro',
    name       => "bool_ro",
    type       => 'bool',
    value      => \$bool_ro,
    definition => "",
);
$bar->add_variable(
    mode       => 'rw',
    name       => "bool_rw",
    type       => 'bool',
    value      => \$bool_rw,
    definition => "",
);
$bar->add_variable(
    mode       => 'ro',
    name       => "integer_ro",
    type       => 'integer',
    value      => \$int_ro,
    definition => "",
);
$bar->add_variable(
    mode       => 'rw',
    name       => "integer_rw",
    type       => 'integer',
    value      => \$int_rw,
    definition => "max=300 step=5",
);
$bar->add_variable(
    mode       => 'ro',
    name       => "number_ro",
    type       => 'number',
    value      => \$number_ro,
    definition => "",
);
$bar->add_variable(
    mode       => 'rw',
    name       => "number_rw",
    type       => 'number',
    value      => \$number_rw,
    definition => "min=0 step=0.01",
);
$bar->add_variable(
    mode       => 'ro',
    name       => "string_ro",
    type       => 'string',
    value      => \$string_ro,
    definition => "",
);
$bar->add_variable(
    mode       => 'rw',
    name       => "string_rw",
    type       => 'string',
    value      => \$string_rw,
);
$bar->add_variable(
    mode       => 'ro',
    name       => "color3f_ro",
    type       => 'color3f',
    value      => \$color3f_ro,
);
$bar->add_variable(
    mode       => 'rw',
    name       => "color3f_rw",
    type       => 'color3f',
    value      => \$color3f_rw,
);
$bar->add_variable(
    mode       => 'ro',
    name       => "color4f_ro",
    type       => 'color4f',
    value      => \$color4f_ro,
);
$bar->add_variable(
    mode       => 'rw',
    name       => "color4f_rw",
    type       => 'color4f',
    value      => \$color4f_rw,
);
$bar->add_variable(
    mode       => 'ro',
    name       => "direction_ro",
    type       => 'direction',
    value      => \$direction_ro,
);
$bar->add_variable(
    mode       => 'rw',
    name       => "direction_rw",
    type       => 'direction',
    value      => \$direction_rw,
);
$bar->add_variable(
    mode       => 'ro',
    name       => "quaternion_ro",
    type       => 'quaternion',
    value      => \$quaternion_ro,
);
$bar->add_variable(
    mode       => 'rw',
    name       => "quaternion_rw",
    type       => 'quaternion',
    value      => \$quaternion_rw,
);
$bar->add_variable(
    mode       => 'ro',
    name       => "custom_array_ro",
    type       => $custom_type,
    value      => \$custom_ro,
);
$bar->add_variable(
    mode       => 'rw',
    name       => "custom_array_rw",
    type       => $custom_type,
    value      => \$custom_rw,
);
$bar->add_variable(
    mode       => 'rw',
    name       => "magic_var_rw",
    type       => "number",
    value      => \$magic_var_rw,
);

$bar->add_button(
    name       => "my-btn-name",
    cb         => sub {
        say "bool_ro=$bool_ro, bool_rw=$bool_rw";
        say "int_ro=$int_ro, int_rw=$int_rw";
        say "number_ro=$number_ro, number_rw=$number_rw";
        say "string_ro=$string_ro, string_rw=$string_rw";
        say "color3f_ro=", dump($color3f_ro), ", color3f_rw=", dump($color3f_rw);
        say "color4f_ro=", dump($color4f_ro), ", color4f_rw=", dump($color4f_rw);
        say "direction_ro=", dump($direction_ro), ", direction_rw=", dump($direction_rw);
        say "quaternion_ro=", dump($quaternion_ro), ", quaternion_rw=", dump($quaternion_rw);
        say "custom_rw=$custom_rw";
    },
    definition => "label='dump'",
);
$bar->add_separator("separator2");
$bar->add_button(
    name => "remove quaternions & refresh",
    cb   => sub {
        if ($quaternion_ro) {
            $bar->remove_variable('quaternion_ro');
            $quaternion_ro = undef;
        }
        if ($quaternion_rw) {
            $bar->remove_variable('quaternion_rw');
            $quaternion_rw = undef;
        }
        $bar->set_bar_params(size => '300 600', valueswidth => '200');
        $bar->refresh;
    }
);

my $bool = undef;
my $double = 0.33;
my $string = "bla-bla";
my $color3f = [1.0, 0.2, 0.4];
my $color4f = [0.0, 0.2, 0.4, 1.0];
my $direction = [1.0, 0.2, 0.4];
my $quaternion = [0.1, 0.2, 0.4, 1.0];
my $custom_idx = 0;
my $b2 = AntTweakBar->new("Perl callbacks");
$b2->add_variable(
    mode       => 'ro',
    name       => "bool_ro_cb",
    type       => 'bool',
    cb_read    => sub {
        say "hello from bool_ro_cb!, bool = $bool";
        return undef;
    },
);
$b2->add_variable(
    mode       => 'rw',
    name       => "bool_rw_cb",
    type       => 'bool',
    cb_read    => sub { $bool; },
    cb_write   => sub {
        $bool = shift;
        say "writing value $bool";
    }
);
$b2->add_variable(
    mode       => 'ro',
    name       => "number_ro_cb",
    type       => 'number',
    cb_read    => sub {
        say "returning double value $double";
        $double;
    },
);
$b2->add_variable(
    mode       => 'rw',
    name       => "number_rw_cb",
    type       => 'number',
    cb_read    => sub { $double },
    cb_write   => sub { $double = shift; },
);
$b2->add_variable(
    mode       => 'ro',
    name       => "string_ro_cb",
    type       => 'string',
    cb_read    => sub { $string },
);
$b2->add_variable(
    mode       => 'rw',
    name       => "string_rw_cb",
    type       => 'string',
    cb_read    => sub { $string },
    cb_write   => sub { $string = shift; },
);
$b2->add_variable(
    mode       => 'ro',
    name       => "color3f_ro_cb",
    type       => 'color3f',
    cb_read    => sub { $color3f },
);
$b2->add_variable(
    mode       => 'rw',
    name       => "color3f_rw_cb",
    type       => 'color3f',
    cb_read    => sub { $color3f },
    cb_write   => sub {
        @$color3f = @{$_[0]};
        say "now color3f = " . dump($color3f);
    },
);
$b2->add_variable(
    mode       => 'rw',
    name       => "color4f_rw_cb",
    type       => 'color4f',
    cb_read    => sub { $color4f },
    cb_write   => sub { @$color4f = @{$_[0]} },
);
$b2->add_variable(
    mode       => 'rw',
    name       => "direction_rw_cb",
    type       => 'direction',
    cb_read    => sub { $direction },
    cb_write   => sub { @$direction = @{$_[0]} },
);
$b2->add_variable(
    mode       => 'rw',
    name       => "quaternion_rw_cb",
    type       => 'quaternion',
    cb_read    => sub { $quaternion },
    cb_write   => sub { @$quaternion = @{$_[0]} },
);
$b2->add_variable(
    mode       => 'ro',
    name       => "custom_idx_ro_cb",
    type       => $custom_type,
    cb_read    => sub { $custom_idx },
);
$b2->add_variable(
    mode       => 'rw',
    name       => "custom_idx_rw_cb",
    type       => $custom_type,
    cb_read    => sub { $custom_idx },
    cb_write   => sub { $custom_idx = shift },
);

glutMainLoop;
