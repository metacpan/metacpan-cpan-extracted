package Be::Attribute;

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

bootstrap Be::Attribute $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!
# yes, mom. -- dogcow

=head1 NAME

Be::Attribute - get and set MIME file attributes

=head1 SYNOPSIS

  use Be::Attribute;
  $node  = Be::Attribute::GetBNode("/my/file/here");
  @attrs = Be::Attribute::ListAttrs($node);
  for $i (@attrs) {
    print "$i - ", Be::Attribute::ReadAttr($node, $i), "\n";
  }
  Be::Attribute::CloseNode($node);

=head1 DESCRIPTION

Get (or set) MIME file attributes.

=head1 USAGE

lookit the synopsis. look at example.pl. Look at the .xs code.
Read the Node webpage.

=head1 AUTHOR

Tom Spindler, dogcow@globalcenter.net

=head1 SEE ALSO

http://www.be.com/documentation/be_book/The%20Storage%20Kit/Node.html

=cut
