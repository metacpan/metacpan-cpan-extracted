package MY::slurp;

use strict;
use warnings;
use IO::File;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(slurp);

sub slurp {
    my $file = shift;
    my $fin  = IO::File->new( $file, '<' ) or die "can't open $file; $!";
    return join('', <$fin>);
}

1;
