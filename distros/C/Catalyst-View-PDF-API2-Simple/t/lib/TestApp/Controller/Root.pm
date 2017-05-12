package TestApp::Controller::Root;
use strict;
use warnings;

__PACKAGE__->config(namespace => q{});

use base 'Catalyst::Controller';

use TestApp::View::PDF::API2::Simple;

sub main :Path { $_[1]->res->body('<h1>It works</h1>') }

sub pdf_test : Global {
  my ($self, $c) = @_;

  $c->stash( {
    data => "This is a test page",
    pdf_template=>'simple_pdf.tt',
    pdf_filename=>'test_pdf.pdf',    
  } );

  $c->forward('View::PDF::API2::Simple');
}

sub pdf_another : Global {
  my ($self, $c) = @_;

  $c->log->debug("PATH: " . $c->path_to('root/pdf_templates/another_template'));

  $c->stash( {
    data => "This is a test page",
    pdf_template=>'simple2_pdf.tt',
    pdf_filename=>'test_pdf.pdf',
    additional_template_path=>$c->path_to('root/pdf_templates/another_template'),
  } );

  $c->forward('View::PDF::API2::Simple');
}

1;
