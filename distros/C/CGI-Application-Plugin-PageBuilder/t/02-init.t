
use strict;
use warnings;

use Test::More;
plan tests => 27;

my $data = {
            one => 'The one',
            two => 'The two',
            three => 'The three',
            four => 'The four',
        };


{
    package TestApp;
    use Test::More;

    use base 'CGI::Application';
    use CGI::Application::Plugin::PageBuilder;

    sub setup {
        my $self = shift;

        $self->header_type( 'none' );
        $self->run_modes(
                         'start' => 'default',
                     );
        $ENV{ 'PATH_INFO' } = "/tmp/honkus/fleeb";

        $self->tmpl_path( "./t/templates" );
        $self->mode_param(
                          -path_info => 2,
                      );
    }

    sub default {
        my $self = shift;
        ok( $self->pb_template( 'header.tmpl' ), 'pb_template' );
        ok( $self->pb_template( 'test_top.tmpl' ), "pb_template" );

        while ( my( $k, $v ) = each( %{ $data } ) ) {
            ok( $self->pb_template( 'test_element.tmpl' ), "pb_template" );
            ok( $self->pb_param( 'name', $k ), "pb_param" );
            ok( $self->pb_param( 'value', $v ), "pb_param" );
        }

        ok( $self->pb_template( 'test_bottom.tmpl' ), "pb_template" );
        ok( my $html = $self->pb_build, "pb_build" );

        while ( my( $k, $v ) = each( %{ $data } ) ) {
            like( $html, qr/$v/, "content" );
        }

        ok( $self->pb_template( 'test_element.tmpl', die_on_bad_params => 0 ), "bad params" );
        ok( $self->pb_param( 'thisdoesntexist', 'noreally' ), "set bad param" );
        ok( $self->pb_param( 'name', 'doesntexist' ), "good param" );
        ok( $self->pb_param( 'value', 'doesntexistvalue' ), "good value" );
        $html = $self->pb_build();

        like( $html, qr/doesntexist/, "good check" );
        like( $html, qr/doesntexistvalue/, "good value" );

        # might as well make a complete page even if it's just a test.
        ok( $self->pb_template( 'footer.tmpl' ), 'footer' );
    }
}

my $a = new TestApp;
$a->run();
