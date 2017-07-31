package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config->{namespace} = '';

sub index : Path('/') Args(0) { 
    my ( $self, $c ) = @_; 

    my $format = {
        font => 'Times New Roman',
        size => '15',
        color => 'Black',
        bold  => 1,
        italic => 0,
        underline => 0,
        font_strikeout => 0,
        font_script => 0,
        font_outline => 0,
        font_shadow => 0,
        num_format => '0.00'
    };

    my $xlsx_data = {
        data => [
            {
                row => 0,
                col => 0,
                data => 10,
                format => $format,
                value => '10'
            },
            {
                row => 0,
                col => 1,
                data => 20,
                format => $format,
                value => '20'
            },
            {
                row => 0,
                col => 2,
                data => '=SUM(A1:B1)',
                format => $format,
                value => '30'
            }
        ],
        filename => "TestExcel.xlsx"
    };

    $c->stash(xlsx => $xlsx_data, current_view => 'XLSX');
} 

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

sub end : ActionClass('RenderView') {}

1;
