package MockedRequest;
use common::sense;
use URI;

sub new {
    my $this   = shift;
    my $class  = ref($this) || $this;
    my $method = shift;
    my $url    = shift;
    my $self   = {
        method => $method,
        url    => URI->new($url),
    };

    return bless $self, $class;
}

sub method { shift->{method} }
sub url    { shift->{url}    }

1;
