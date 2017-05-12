package TestImmediate;

use Exporter;
use base 'Exporter';

our @EXPORT = qw<begin xbegin>;

sub begin(&) {
    my ($code) = @_;
    $code->();
}

sub xbegin { }

use Call::Immediate qw<begin xbegin>;

1;
