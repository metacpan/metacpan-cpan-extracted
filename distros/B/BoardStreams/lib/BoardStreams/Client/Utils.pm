package BoardStreams::Client::Utils;

use Mojo::Base -strict, -signatures;

use Mojo::Promise;

use Exporter 'import';
our @EXPORT_OK = qw/ unique_id observable_to_promise /;

our $VERSION = "v0.0.23";

my $cursor = 1;
sub unique_id () {
    my $ret = $cursor;
    $cursor++;
    if ($cursor > 1e11) {
        $cursor = 1;
    }
    return "$ret";
}

sub observable_to_promise ($o) {
    my $p = Mojo::Promise->new;

    my @last_value;
    $o->subscribe({
        next     => sub {
            my ($val) = @_;
            $last_value[0] = $val;
        },
        error    => sub {
            my ($error) = @_;
            $p->reject($error);
        },
        complete => sub {
            $p->resolve(@last_value) if @last_value;
        },
    });

    return $p;
}

1;
