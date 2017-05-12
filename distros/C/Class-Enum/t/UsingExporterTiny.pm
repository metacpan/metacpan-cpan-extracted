package t::UsingExporterTiny;
use strict;
use warnings;

use Class::Enum qw(Left Right), -install_exporter => 0;
use parent 'Exporter::Tiny';
our @EXPORT_OK = __PACKAGE__->names;

1;
