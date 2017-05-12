package TestApp::View::TT;

eval "use base 'Catalyst::View::TT'";
eval "use base 'Catalyst::View'" if $@;


__PACKAGE__->config( INCLUDE_PATH => 't/lib/TestApp/tt' );

1;

