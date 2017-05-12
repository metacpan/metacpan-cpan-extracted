package DBIx::Inspector::ForeignKey::Pg;
use strict;
use warnings;
use utf8;
use base qw/DBIx::Inspector::ForeignKey/;

sub pktable_cat   { $_[0]->{UK_TABLE_CAT} }
sub pktable_schem { $_[0]->{UK_TABLE_SCHEM} }
sub pktable_name  { $_[0]->{UK_TABLE_NAME} }
sub pkcolumn_name { $_[0]->{UK_COLUMN_NAME} }

sub fktable_cat   { $_[0]->{FK_TABLE_CAT} }
sub fktable_schem { $_[0]->{FK_TABLE_SCHEM} }
sub fktable_name  { $_[0]->{FK_TABLE_NAME} }
sub fkcolumn_name { $_[0]->{FK_COLUMN_NAME} }

1;

