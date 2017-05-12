package Data::Library;
use base qw(Class::Virtual);

use vars qw($VERSION);
$VERSION = '0.2';

=head1 NAME

Data::Library - virtual class for repository support classes

=head1 SYNOPSIS

Data::Library provides a general repository service.  Specifics are
implemented in subclasses.

=head1 METHODS

=cut

__PACKAGE__->virtual_methods(qw(new lookup find cache toc reset));

1;

=item B<new>

  my $library = new Data::Library(...configuration...);

Configuration parameters are specific to subclasses.

=item B<new>

  my $boolean = $library->lookup($tag);

Returns cached data items, by tag.  If the source has changed since
it was cached, returns false.

=item B<find>

  my $data = $library->find($tag);

Searches for data item identified by $tag.

=item B<cache>

  $library->cache($tag, $data);

Caches data by tag for later fetching via lookup().

=item B<toc>

  my @array = $library->toc;

Search through the library and return a list of all available entries.
Does not cache any of the items.

=item B<reset>

  $library->reset;

Erase all entries from the cache.

=cut
