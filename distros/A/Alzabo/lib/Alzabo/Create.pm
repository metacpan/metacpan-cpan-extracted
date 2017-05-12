package Alzabo::Create;

use Alzabo;

use Alzabo::Create::Column;
use Alzabo::Create::ColumnDefinition;
use Alzabo::Create::ForeignKey;
use Alzabo::Create::Index;
use Alzabo::Create::Table;
use Alzabo::Create::Schema;

use vars qw($VERSION);

$VERSION = 2.0;

1;

__END__

=head1 NAME

Alzabo::Create - Loads all Alzabo::Create::* classes

=head1 SYNOPSIS

  use Alzabo::Create;

=head1 DESCRIPTION

Using this module loads Alzabo::Create::* modules.

These are the core modules that allow a new set of objects to be
created.  This module should be used by any schema creation interface.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
