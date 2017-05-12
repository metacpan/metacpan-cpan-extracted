package TestApp::Controller::Root;
use strict;
use warnings;

__PACKAGE__->config( namespace => q{} );

use base 'Catalyst::Controller';

use Text::CSV;
use TestApp::View::Download::CSV;
use TestApp::View::Download::Plain;
use TestApp::View::Download::HTML;

# your actions replace this one
sub main : Path {
    $_[1]->res->body('<h1>It works</h1>');
}

sub csv_test : Global {
    my ( $self, $c ) = @_;

    my @data = $self->_generate_test_data();

    $c->stash->{'csv'} = \@data;

    my $view = new TestApp::View::Download::CSV;

    $c->res->body( '' . $view->render( $c, '', $c->stash ) );
}

sub html_test : Global {
    my ( $self, $c ) = @_;

    my $data = $self->_generate_test_data();

    $c->stash->{'html'} =
'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"><html><head><title></title></head><body>'
          . $data
          . '</body></html>';

    my $view = new TestApp::View::Download::HTML;

    $c->res->body( '' . $view->render( $c, '', $c->stash ) );
}

sub xml_test : Global {
    my ( $self, $c ) = @_;

    my $data = $self->_generate_test_data();

    $c->stash->{'xml'} = { 'root' => { 'text' => [ $data ] } };

    my $view = new TestApp::View::Download::XML;

    $c->res->body( '' . $view->render( $c, '', $c->stash ) );
}

sub plain_test : Global {
    my ( $self, $c ) = @_;

    my $data = $self->_generate_test_data();

    $c->stash->{'plain'} = $data;

    my $view = new TestApp::View::Download::Plain;

    $c->res->body( '' . $view->render( $c, '', $c->stash ) );
}

sub _generate_test_data {
    my ( $self, $c ) = @_;

    my $data;

    if ( wantarray() ) {
        $data = [
            [ 'a', 'b',  'c',  'd' ],
            [ '1', '2',  '3',  '4' ],
            [ ' ', "\n", "\t", '!' ],
            [ '@', ',',  '"',  "'" ]
        ];

        return @{$data};
    }
    else {
        $data = <<"TEST";
Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Vestibulum tempus augue interdum neque. Curabitur ac libero. Aliquam faucibus mi a lectus. Sed et elit. Etiam volutpat suscipit quam. Phasellus sit am
et odio. Sed faucibus magna quis diam. Nulla facilisi. Vivamus id erat porttitor elit aliquam ornare. Integer tincidunt varius lacus. Pellentesque sit amet mauris id ligula faucibus semper. Maecenas eros. Cur
abitur hendrerit ligula ac nulla. Mauris dolor eros, pellentesque vel, varius porttitor, convallis non, lectus.

Curabitur lacinia laoreet felis. Vivamus a urna. Aenean adipiscing aliquam velit. Aliquam varius bibendum nulla. Praesent quis tortor nec nisi scelerisque facilisis. Cras tristique. Phasellus mi libero, vulpu
tate ac, hendrerit ac, iaculis at, elit. Pellentesque ac ante sit amet orci viverra condimentum. Fusce aliquam semper justo. Integer tincidunt. Pellentesque habitant morbi tristique senectus et netus et males
uada fames ac turpis egestas. Nullam id lectus. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Curabitur ut felis non mauris auctor viverra. Fusce dignissim. Morbi qui
s magna.

Proin scelerisque, lacus blandit consequat sodales, augue ligula laoreet quam, condimentum pretium velit diam eget lorem. Suspendisse potenti. Nam rhoncus mi vitae tortor. Sed eget neque. Fusce sagittis. Null
a rutrum nibh et justo. Suspendisse dolor libero, rhoncus a, pretium id, feugiat eget, velit. Aenean accumsan. Nunc vel nulla. Mauris semper consectetuer velit. Vivamus semper. Nulla fermentum sapien nec feli
s. Aenean iaculis felis nec ipsum. Aliquam tristique. Nam ut quam. Suspendisse ornare tristique arcu. Morbi pellentesque dolor eget lorem. Morbi ac nunc euismod lorem porttitor hendrerit. Lorem ipsum dolor si
t amet, consectetuer adipiscing elit.
TEST
        return $data;
    }
}

1;
