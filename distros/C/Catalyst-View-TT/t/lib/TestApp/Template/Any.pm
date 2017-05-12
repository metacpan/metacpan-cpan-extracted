use strict;
use warnings;

package TestApp::Template::Any;

use base 'Template';
use FindBin;
use Path::Class;

sub new {
    my $class = shift;

    my $params = defined($_[0]) && ref($_[0]) eq 'HASH' ? shift : {@_};

    my $includepath = dir($FindBin::Bin, '/lib/TestApp/root/any_include_path');
    $params->{INCLUDE_PATH} = $includepath;

    return $class->SUPER::new( $params );
}

1;
