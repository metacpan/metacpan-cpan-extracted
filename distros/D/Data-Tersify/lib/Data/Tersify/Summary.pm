package Data::Tersify::Summary;

use strict;
use warnings;

=head1 NAME

Data::Tersify::Summary - a summary of a verbose object

=head1 DESCRIPTION

Data::Tersify::Summary objects are generated when Data::Tersify finds an
object that it knows how to summarise. They're simple blessed scalars
describing the object, or blessed hashrefs or arrayrefs that match the
object's internal status. You can't do anything useful with them.

=cut

1;
