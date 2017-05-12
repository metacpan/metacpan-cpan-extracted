package TestApp::View::PDFBoxer;
use Moose;
use namespace::clean -except => 'meta';

extends qw/Catalyst::View::TT/;
with qw/Catalyst::View::PDFBoxer/;

1;
