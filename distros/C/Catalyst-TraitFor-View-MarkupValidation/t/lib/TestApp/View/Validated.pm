package TestApp::View::Validated;

use Moose;
use namespace::autoclean;

extends qw/Catalyst::View::TT/;
with qw/Catalyst::TraitFor::View::MarkupValidation/;