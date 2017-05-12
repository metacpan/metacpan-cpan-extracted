package Test::Backbone::Events::Utils;
use parent 'Exporter';
our @EXPORT    = qw(test_handler);
our @EXPORT_OK = @EXPORT;

sub test_handler {
    return Test::Backbone::Events::Handler->new;
}

package Test::Backbone::Events::Handler;
use Moo;
with 'Backbone::Events';

no Moo;

1;
