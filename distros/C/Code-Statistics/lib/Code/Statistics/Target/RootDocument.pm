use strict;
use warnings;

package Code::Statistics::Target::RootDocument;
$Code::Statistics::Target::RootDocument::VERSION = '1.190680';
# ABSTRACT: represents the root PPI document of a perl file

use Moose;
extends 'Code::Statistics::Target';


sub find_targets {
    my ( $class, $file ) = @_;
    return [ $file->ppi ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::Statistics::Target::RootDocument - represents the root PPI document of a perl file

=head1 VERSION

version 1.190680

=head2 find_targets
    Returns the root PPI document of the given perl file.

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
