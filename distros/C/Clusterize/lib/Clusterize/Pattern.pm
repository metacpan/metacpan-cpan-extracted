use warnings;
use strict;
package Clusterize::Pattern;
use Digest::MD5;
our $VERSION = '0.02';

sub new { return bless {}, shift }
sub text2digest { return {} }
sub pattern { return }
sub accuracy { return }
sub size { return }

1;

=head1 NAME

Clusterize::Pattern - provides various information about clusters built by Clusterize module.

=head1 VERSION

Version 0.02

=head1 DESCRIPTION

B<Clusterize::Pattern> module is used by B<Clusterize> module to provide the following information for the cluster: B<pattern>, B<accuracy>, B<size>, B<digest>.

=head1 METHODS

=head2 pattern

Returns regular expression that matches all strings in given cluster.

=head2 accuracy

Returns the value between 0 and 1 that reflects the similarity of strings in the given cluster.
The accuracy value tends to 1 for very accurate clusters and to 0 for fuzzy clusters.

=head2 size

Returns the number of unique keys in given cluster.

=head2 digest

Returns MD5 hex digest for given cluster. It could be used to identify unique clusters.

=head2 pairs

Returns hash of key/value pairs for given cluster.


=head1 AUTHOR

Slava Moiseev, <slava.moiseev@yahoo.com>

