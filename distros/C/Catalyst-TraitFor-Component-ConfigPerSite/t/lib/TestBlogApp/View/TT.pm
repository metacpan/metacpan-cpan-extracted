package TestBlogApp::View::TT;

use Moose;

extends 'Catalyst::View::TT'; 

with qw(Catalyst::TraitFor::View::TT::ConfigPerSite);

1;
