package AppTest::Controller::Root;
our $VERSION = '0.001';
use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller'; }

with 'Catalyst::TraitFor::Controller::Ping';

__PACKAGE__->config
(
    {
        namespace => '',
        model_name => 'SomeModel',
        model_method => 'some_method',
        model_method_arguments => [qw/ one two three /],
    }
);

sub default :Private {}

1;
__END__
