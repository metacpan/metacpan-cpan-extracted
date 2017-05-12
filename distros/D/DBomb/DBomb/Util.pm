package DBomb::Util;

=head1 NAME

DBomb::Util - Miscellany with no place else to go.

=head1 SYNOPSIS

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.4 $';

use base qw(Exporter);

our %EXPORT_TAGS = ( all => [qw{
    ctx_0 is_same_value
}]);
Exporter::export_ok_tags('all');

## returns @args if caller's caller is in list context, or $args[0] otherwise
## ctx_0(@args)
sub ctx_0
{
    (caller(1))[5] ? @_ : $_[0];
}

## like cmp but allows undef
sub is_same_value
{
    my ($a,$b) = @_;
    ## True if they are equal or if both undef
    return ((defined($a) && defined($b) && $a eq $b)
           || (!defined($a) && !defined($b)));
}
1;
__END__
