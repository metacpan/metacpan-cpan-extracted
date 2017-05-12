=head1 Data::Downloader::DB::Object::Cached

Base class for Data::Downloader cached objects.

Inherits from Rose::DB::Object::Cached

=head1 METHODS

=over

=cut

package Data::Downloader::DB::Object::Cached;

use base qw/Rose::DB::Object::Cached/;
use Log::Log4perl qw/:easy/;

=item init_db

Gets the database handle.

=cut

sub init_db { Data::Downloader::DB->new_or_cached("main") }

=back

=head1 SEE ALSO

L<Rose::DB::Object::Cached>

=cut

1;



