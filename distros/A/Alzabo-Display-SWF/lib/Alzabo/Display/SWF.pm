package Alzabo::Display::SWF;

use strict;
use warnings;
use base qw/Exporter/;

use YAML;
use Alzabo::Display::SWF::Schema;

our $VERSION = '0.01';
our @EXPORT_OK = qw/$cfg/;
our $cfg = Load( <<'...' );
---
schema:
  fdb: Verdana-B
  color:
    bg: xFFFFFF
    fg: xA80806
  edge:
    width:   2
    opacity: 40

table:
  fdb: Verdana-B
  linestyle:
    width: 2
    color: x999999
  color:
    bg: xD8DDB3
    fg: xA80806
  edge:
    width:   2
    opacity: 40
  key:
    primary: xE6BAB9
    foreign: xA80806

column:
  fdb:
    over: Verdana-B
    up:   Verdana-B
  color:
    bg: xF3F5E5
    fg:
      over: x72726E
      up:   xCC9966

fdb_dir: '.'
...

sub create {
  my ($pkg, $name) = @_;
  my $schema = Alzabo::Display::SWF::Schema->new(
    name => $name, cfg => $cfg 
  );
  $schema->create_graph;
  $schema->create_movie;
  return $schema;
}

sub import {
  shift;
  return unless $_[0];
  local $/ = undef;
  open CFG, "<$_[0]" or die "$_[0]: $!";
  $_ = <CFG>;
  close CFG;
  $cfg  = Load ( $_ );
}

1;

__END__

=head1 NAME

Alzabo::Display::SWF - Create SWF (Flash) Movies for
visualizing Alzabo database schemas.

=head1 SYNOPSIS

  use Alzabo::Display::SWF;
  my $s = Alzabo::Display::SWF->create( $alzabo_schema_name );
  $s->save("$alzabo_schema_name.swf");
  my ($width, $height) = $s->dim;

  use Alzabo::Display::SWF qw/my_conf.yml/;

=head1 DESCRIPTION

This Module uses the information provided by an Alzabo database schema
and - with the help of the GraphViz module and the Ming library -
creates a SWF Movie which contains a visualization of the data model.

Each table of the Database Schema is displayed, with the
name in a table header and the columns following in the body. Primary
and foreign keys are indicated by a small circle in front of the
column name. In the case of a foreign key, moving the mouse over
the indicator displays a line to the indicator(s) of the column(s) it
is related to (in the same or in another table).

In the bottom of the movie there is a label with the  name of the Alzabo
schema. Clicking on this label toggles the display of all relations
between tables.

Individual configuration of the colors, fonts and linestyles in the movie
can be done via a YAML configuration file (see SYNOPSIS).

=head1 TODO

=over 4

=item *

Signify cardinality and (in)dependence of relationships.

=item *

Show column metadata.

=item *

...

=back

=head1 AUTHOR

Stefan Baumann <s.baumann@uptime.at>

=head1 SEE ALSO

Alzabo, GraphViz, YAML, SWF

=cut

