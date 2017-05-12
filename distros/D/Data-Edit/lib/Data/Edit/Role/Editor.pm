package Data::Edit::Role::Editor;
use Moose::Role;
use MooseX::Types::Moose qw/ Str /;

has path => (
    is => 'ro',
    isa => Str,
    required => 1,
);

1;
