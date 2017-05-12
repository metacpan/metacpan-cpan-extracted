package TestApp::Widget::SimplePager;

use Moose;

extends 'CatalystX::Widget::Paginator';


has '+edges'    => ( is => 'ro', default => undef );
has '+invalid'  => ( is => 'ro', default => 'last' );
has '+page_arg' => ( is => 'ro', default => 'page' );
has '+prefix'   => ( is => 'ro', default => undef );
has '+side'     => ( is => 'ro', default => 0 );
has '+suffix'   => ( is => 'ro', default => undef );


__PACKAGE__->meta->make_immutable;

1;

