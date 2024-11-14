package Data::Annotation::Util;
use v5.24;
use experimental qw< signatures >;
use Data::Annotation::Overlay;
use Exporter qw< import >;
our @EXPORT_OK = qw< o overlay >;

sub o { Data::Annotation::Overlay->new(under => @_) }

*{overlay} = \&o;

1;
