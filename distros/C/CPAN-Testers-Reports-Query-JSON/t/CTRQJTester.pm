package CTRQJTester;

use lib qw(lib);

use Moose;
use File::Slurp;

extends 'CPAN::Testers::Reports::Query::JSON';

has 'test_file' => ( is => 'rw', default => 't/data-pageset.json' );

# For tests we'll use our own file thanks
sub _raw_json {
    my $self = shift;
    my $file = read_file( $self->test_file );
    return $file;
}

1;
