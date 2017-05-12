package TestApp::Moostash;

use Moose;
extends 'Catalyst::Plugin::Moostash::Base';

=head2 test_attr

=cut

has test_attr => (
    is     => 'ro',
    isa    => 'Int',
    writer => 'set_test_attr',
);

1;    # eof
