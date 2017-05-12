package TestApp::HashTree::Default;
use base qw( Apache2::Controller Apache2::Request );
sub allowed_methods {qw( default bar )}
sub default {
}
sub bar {
}
1;
