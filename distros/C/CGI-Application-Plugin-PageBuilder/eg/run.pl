
package MyApp;
use base 'CGI::Application';
use CGI::Application::Plugin::PageBuilder;

sub setup {
    my $self = shift;

    $self->header_type('none');
    $self->run_modes( 'start' => 'default', );

    $self->tmpl_path("./t/templates");
    $self->mode_param( -path_info => 2, );
}

sub default {
    my $self = shift;
    $self->pb_template( 'header.tmpl' );
    $self->pb_template( 'data.tmpl' );
    while ( my( $k, $v ) = each( %{ $data } ) ) {
        $self->pb_template( 'element.tmpl' );
        $self->pb_param( 'name', $k );
        $self->pb_param( 'value', $v );
    }
    $self->pb_template( 'footer.tmpl' );
    return $self->pb_build();
}

package main;

my $a = new TestApp;
$a->run();
