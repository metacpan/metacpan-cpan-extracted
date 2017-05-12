package TestApp::Controller::Root;
use strict;
use warnings;

__PACKAGE__->config(namespace => q{});

use base 'Catalyst::Controller';

use TestApp::View::PDF::API2;

sub main :Path { $_[1]->res->body('<h1>It works</h1>') }

sub pdf_test : Global {
  my ($self, $c) = @_;

  $c->stash( {
    data => "This is a test page",
    pdf_template=>'test_pdf.tt',
    pdf_filename=>'test_pdf.pdf',    
  } );

  $c->forward('View::PDF::API2');
}

1;
