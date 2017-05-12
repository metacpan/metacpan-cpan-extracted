package My::slurp;
##
# also lifted from gtermans
#
#
use strict;
use warnings;
use IO::File;
use base qw( Exporter );
our @EXPORT = qw(slurp);

sub slurp {
    my $file = shift;
    my $fin  = IO::File->new( $file, '<' ) or die "can't open $file; $!";
    return join('', <$fin>);
}

1;

