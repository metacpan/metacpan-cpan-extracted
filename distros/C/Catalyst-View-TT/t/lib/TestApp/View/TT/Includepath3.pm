package TestApp::View::TT::Includepath3;

use FindBin;
use Path::Class;
use strict;
use base 'Catalyst::View::TT';

our @include_path;
my $includepath = dir($FindBin::Bin, '/lib/TestApp/root/test_include_path');
__PACKAGE__->config(
    PRE_CHOMP          => 1,
    POST_CHOMP         => 1,
    TEMPLATE_EXTENSION => '.tt',
    INCLUDE_PATH        => \@include_path,
);

1;
