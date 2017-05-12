# This TestApp is used with permission from Juan Camacho, and is from the 0.03 
# release of his Catalyst::Controller::FormBuilder module

package TestApp;
use strict;
use warnings;
use Catalyst;
use Class::Inspector;
use FindBin;

our @TEMPLATES = ( 'HTML::Template', 'Mason', 'TT' );

my @except;
our $template_type;

for (@TEMPLATES) {
    unless ( Class::Inspector->installed( "Catalyst::View::" . $_ ) ) {
        push @except, "TestApp::Component::$_";
    }
    else {
        $template_type = $_;
    }
}

__PACKAGE__->config(
    name             => 'TestApp',
    home             =>  $FindBin::Bin,
    setup_components =>
      { search_extra => ['TestApp::Component'], except => \@except },
    template_type => $template_type || 'Rendered',
);

__PACKAGE__->setup();

1;
