use strict;
use warnings;


use Async::Selector;

my $selector = Async::Selector->new();

## Register resource
my $resource = "some text.";  ## 10 bytes

$selector->register(resource_A => sub {
    ## If length of $resource is more than or equal to $threshold bytes, provide it.
    my $threshold = shift;
    return length($resource) >= $threshold ? $resource : undef;
});


## Watch the resource with a callback.
$selector->watch(
    resource_A => 20,  ## When the resource gets more than or equal to 20 bytes...
    sub {              ## ... execute this callback.
        my ($watcher, %resource) = @_;
        print "$resource{resource_A}\n";
        $watcher->cancel();
    }
);


## Append data to the resource
$resource .= "data";  ## 14 bytes
$selector->trigger('resource_A'); ## Nothing happens

$resource .= "more data";  ## 23 bytes
$selector->trigger('resource_A'); ## The callback prints 'some text.datamore data'
