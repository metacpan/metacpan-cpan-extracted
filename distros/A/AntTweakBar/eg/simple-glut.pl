#!/usr/bin/env perl

# This is almost one-to-one perl's rewrite of C-original
# http://anttweakbar.sourceforge.net/doc/tools:anttweakbar:examples#twsimpleglut
# http://sourceforge.net/p/anttweakbar/code/ci/master/tree/examples/TwSimpleGLUT.c

use 5.12.0;
use strict;
use warnings;

use OpenGL qw/:all/;
use AntTweakBar qw/:all/;
use AntTweakBar::Type;
use List::MoreUtils qw/pairwise/;
use List::Util qw/reduce/;
use Data::Dump qw/dump/;
use Time::HiRes qw/tv_interval gettimeofday/;

sub display;

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

sub set_quaternion_from_axis_angle {
    my ($axis, $angle) = @_;
    my $sina2 = sin($angle * 0.5);
    my $norm = sqrt( reduce { $a + $b} map { $_ * $_} @$axis );
    my $q = [];
    @$q = map { $sina2 * $_ / $norm } @$axis;
    $q->[3] = cos( $angle * 0.5 );
    return $q;
}

sub convert_quaternion_t_omatrix {
    my $q = shift;
    my $m = [];
    my $yy2 = 2.0 * $q->[1] * $q->[1];
    my $xy2 = 2.0 * $q->[0] * $q->[1];
    my $xz2 = 2.0 * $q->[0] * $q->[2];
    my $yz2 = 2.0 * $q->[1] * $q->[2];
    my $zz2 = 2.0 * $q->[2] * $q->[2];
    my $wz2 = 2.0 * $q->[3] * $q->[2];
    my $wy2 = 2.0 * $q->[3] * $q->[1];
    my $wx2 = 2.0 * $q->[3] * $q->[0];
    my $xx2 = 2.0 * $q->[0] * $q->[0];

    $m->[0*4+0] = - $yy2 - $zz2 + 1.0;
    $m->[0*4+1] = $xy2 + $wz2;
    $m->[0*4+2] = $xz2 - $wy2;
    $m->[0*4+3] = 0;
    $m->[1*4+0] = $xy2 - $wz2;
    $m->[1*4+1] = - $xx2 - $zz2 + 1.0;
    $m->[1*4+2] = $yz2 + $wx2;
    $m->[1*4+3] = 0;
    $m->[2*4+0] = $xz2 + $wy2;
    $m->[2*4+1] = $yz2 - $wx2;
    $m->[2*4+2] = - $xx2 - $yy2 + 1.0;
    $m->[2*4+3] = 0;
    $m->[3*4+0] = $m->[3*4+1] = $m->[3*4+2] = 0;
    $m->[3*4+3] = 1;

    return $m;
}

sub multiply_quaternions {
    my ($q1, $q2) = @_;
    my $qr = [];
	$qr->[0] = $q1->[3]*$q2->[0] + $q1->[0]*$q2->[3] + $q1->[1]*$q2->[2] - $q1->[2]*$q2->[1];
	$qr->[1] = $q1->[3]*$q2->[1] + $q1->[1]*$q2->[3] + $q1->[2]*$q2->[0] - $q1->[0]*$q2->[2];
	$qr->[2] = $q1->[3]*$q2->[2] + $q1->[2]*$q2->[3] + $q1->[0]*$q2->[1] - $q1->[1]*$q2->[0];
	$qr->[3] = $q1->[3]*$q2->[3] - ($q1->[0]*$q2->[0] + $q1->[1]*$q2->[1] + $q1->[2]*$q2->[2]);
    return $qr;
}

my @shape_drawings = (
    Teapot => { function => \&glutSolidTeapot, arguments => [ 1.0 ] },
    Torus  => { function => \&glutSolidTorus,  arguments => [ 0.3, 1.0, 16, 32] },
    Cone   => { function => \&glutSolidCone,   arguments => [ 1.0, 1.5, 64, 4] },
);

# Create some 3D objects (stored in display lists)
for my $i ( 0 .. @shape_drawings/2-1 ) {
    my $shape_id = ($i * 2) + 1; # shape_id shouldn't be zero
    my $defintion = $shape_drawings[$i*2+1];
    my $drawer = $defintion->{function };
    my $args   = $defintion->{arguments};
    glNewList($shape_id, GL_COMPILE);
    $drawer->(@$args);
    glEndList;
}

my $shape_type = AntTweakBar::Type->new(
    "ShapeType",
    { map { ($shape_drawings[$_*2] => $_*2) } (0 .. @shape_drawings/2-1) },
);

# variables
my $angle            = 0.8;
my $axis             = [ 0.7, 0.7, 0.0 ];
my $zoom             = 1.0;
my $rotation         = set_quaternion_from_axis_angle($axis, $angle);
my $rotate_start     = set_quaternion_from_axis_angle($axis, $angle);
my $auto_rotation    = 0;
my $rotate_time      = [ gettimeofday ];
my $light_multiplier = 1.0;
my $light_direction  = [ -0.57735, -0.57735, -0.57735 ];
my $material_ambient = [ 0.5, 0.0, 0.0];
my $material_diffuse = [ 1.0, 1.0, 0.0];
my $shape            = 2; # torus

sub display {
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glEnable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    glEnable(GL_NORMALIZE);

    # set light
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
    my $ambient_light = OpenGL::Array->new_list(
        GL_FLOAT, (0.4 * $light_multiplier) x 3, 1.0);
    my $diffuse_light = OpenGL::Array->new_list(
        GL_FLOAT, (0.8 * $light_multiplier) x 3, 1.0);
    glLightfv_c(GL_LIGHT0, GL_AMBIENT, $ambient_light->ptr);
    glLightfv_c(GL_LIGHT0, GL_DIFFUSE, $diffuse_light->ptr);
    my $light_position = OpenGL::Array->new_list(
        GL_FLOAT, map { $_ * -1 } @$light_direction, 0.0);
    glLightfv_c(GL_LIGHT0, GL_POSITION, $light_position->ptr);

    # set material
    my $oga_material_ambient = OpenGL::Array->new_list(
        GL_FLOAT, @$material_ambient);
    my $oga_material_diffuse = OpenGL::Array->new_list(
        GL_FLOAT, @$material_diffuse);
    glMaterialfv_c(GL_FRONT_AND_BACK, GL_AMBIENT, $oga_material_ambient->ptr);
    glMaterialfv_c(GL_FRONT_AND_BACK, GL_DIFFUSE, $oga_material_diffuse->ptr);

    # Rotate and draw shape
    glPushMatrix;
    {
        glTranslatef(0.5, -0.3, 0.0);
        if ($auto_rotation) {
            my $axis = [0.0, 1.0, 0.0];
            my $elapsed = tv_interval( $rotate_time, [gettimeofday]);
            my $angle = $elapsed;
            my $q = set_quaternion_from_axis_angle($axis, $angle);
            $rotation = multiply_quaternions($rotate_start, $q);
        }
        my $m = convert_quaternion_t_omatrix($rotation);
        glMultMatrixf_p(@$m);
        glScalef($zoom, $zoom, $zoom);
        glCallList($shape + 1); # shape_id = shape + 1
    }
    glPopMatrix;

    AntTweakBar::draw;
    glutSwapBuffers;
    glutPostRedisplay;
}

my $bar = AntTweakBar->new(
    "TweakBar & Perl",
    size  => '200 400',
    color => '96 216 224'
);
$bar->add_variable(
    mode       => 'rw',
    name       => "Zoom",
    type       => 'number',
    value      => \$zoom,
    definition => {
        min     => "0.01",
        max     => "2.5",
        step    => "0.01",
        keyIncr => 'z',
        keyDecr => 'Z',
        help    => 'Scale the object (1=original size).'
    },
);
$bar->add_variable(
    mode       => 'rw',
    name       => "ObjRotation",
    type       => 'quaternion',
    value      => \$rotation,
    definition => " label='Object rotation' opened=true help='Change the object orientation.' ",
);
$bar->add_variable(
    mode       => 'rw',
    name       => "AutoRotate",
    type       => 'bool',
    cb_read    => sub { $auto_rotation },
    cb_write   => sub {
        $auto_rotation = shift;
        if ($auto_rotation) {
            $rotate_time = [ gettimeofday ];
            @$rotate_start = @$rotation;
            $bar->set_variable_params('ObjRotation', readonly => 'true');
        }
        $bar->set_variable_params('ObjRotation', readonly => 'false');
    },
    definition => " label='Auto-rotate' key=space help='Toggle auto-rotate mode.' ",
);
$bar->add_variable(
    mode       => 'rw',
    name       => "Multiplier",
    type       => 'number',
    value      => \$light_multiplier,
    definition => " label='Light booster' min=0.1 max=4 step=0.02 keyIncr='+' keyDecr='-' help='Increase/decrease the light power.' ",
);
$bar->add_variable(
    mode       => 'rw',
    name       => "LightDir",
    type       => 'direction',
    value      => \$light_direction,
    definition => " label='Light direction' opened=true help='Change the light direction.' ",
);
$bar->add_variable(
    mode       => 'rw',
    name       => "Ambient",
    type       => 'color3f',
    value      => \$material_ambient,
    definition => " group='Material' ",
);
$bar->add_variable(
    mode       => 'rw',
    name       => "Diffuse",
    type       => 'color3f',
    value      => \$material_diffuse,
    definition => " group='Material' ",
);
$bar->add_variable(
    mode       => 'rw',
    name       => "Shape",
    type       => $shape_type,
    value      => \$shape,
    definition => " keyIncr='<' keyDecr='>' help='Change object shape.' ",
);

glutMainLoop;
