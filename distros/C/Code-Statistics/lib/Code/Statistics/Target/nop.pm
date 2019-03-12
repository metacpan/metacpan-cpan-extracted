use strict;
use warnings;

package Code::Statistics::Target::nop;
$Code::Statistics::Target::nop::VERSION = '1.190680';
# ABSTRACT: represents nothing

use Moose;
extends 'Code::Statistics::Target';


sub find_targets {}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::Statistics::Target::nop - represents nothing

=head1 VERSION

version 1.190680

=head2 find_targets
    Returns nothing.

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
