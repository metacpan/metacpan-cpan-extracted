package TestApp;
use strict;
use warnings;
use Catalyst;
use Class::Inspector;
use FindBin;

our @TEMPLATES = ( 'HTML::Template', 'Mason', 'TT' );

my ( @except, $template_type );
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
    home             => $FindBin::Bin,
    setup_components =>
      { search_extra => ['TestApp::Component'], except => \@except },
    template_type => $template_type || 'Rendered',
);

__PACKAGE__->setup();

1;
