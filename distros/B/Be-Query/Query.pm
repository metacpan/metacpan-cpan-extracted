package Be::Query;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.2';

bootstrap Be::Query $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!
# yes, mom. -- dogcow

=head1 NAME

Be::Query - do a Query for a given filesystem.

=head1 SYNOPSIS

  use Be::Query;
  @files = Be::Query::Query($filesystem, $query);

=head1 DESCRIPTION

do a Query for a given filesystem

=head1 USAGE

  @files = Be::Query::Query("/boot", "name=lib*.so");

$filesystem is a path anywhere in the target filesystem;
$query is a query construction, of the form
attribute op value [connector attribute op value]

Such as (name = fido) || (size >= 500)

See the below URLs for more information on constructing queries.

=head1 AUTHOR

Tom Spindler, dogcow@globalcenter.net

=head1 SEE ALSO

http://www.be.com/documentation/be_book/The%20Storage%20Kit/Query.html#14835:Zhead2:ZTheZPredicate,ZAttributes,ZandZIndices and
http://www.be.com/documentation/be_book/The%20Storage%20Kit/Query.html29556:Zhead3:ZConstructingZaZPredicate give help on how to construct queries. (Sorry
for the annoying URLs.)

=cut
