package TestApp;

use Moose;
extends 'Catalyst';

use Catalyst::Runtime '5.80';
use FindBin;

use Catalyst ( qw(-Log=error) );

__PACKAGE__->config(
        name => 'TestApp',
        home => "$FindBin::Bin",
);

__PACKAGE__->setup();
 
around 'uri_for' => sub {
    my $orig = shift;
    my $c = shift;
    my $path = shift;
    my @args = @_;
    
    if (blessed($path) && $path->class && $path->class->can('uri_for')) {
        return $c->component($path->class)->uri_for($c, $path, @args);
    }
    
    return $c->$orig($path, @args);
};

1;