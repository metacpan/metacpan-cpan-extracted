package List::SkipList::Node;

use base 'Algorithm::SkipList::Node';

1;

package List::SkipList::Header;

use base 'Algorithm::SkipList::Header';

1;

package List::SkipList;

use base 'Algorithm::SkipList';

our $VERSION = '0.74';
# $VERSION = eval $VERSION;

use Carp qw( carp );

BEGIN {
  carp "The List::SkipList namespace is deprecated; use Algorithm::SkipList";
}

1;

__END__

=head1 NAME

List::SkipList - Perl implementation of skip lists (deprecated)

=head1 DESCRIPTION

This namespace is deprecated.  Please see L<Algorithm::SkipList>.

=cut
