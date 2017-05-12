
package AppSessionObjectTest;
use App::SessionObject;
@ISA = ("App::SessionObject");

sub hello {
    return "hello";
}

sub finish_hello {
    my ($self, $results) = @_;
    my $context = $self->{context};
    $context->so_set("results",  undef, $results);
}

1;

