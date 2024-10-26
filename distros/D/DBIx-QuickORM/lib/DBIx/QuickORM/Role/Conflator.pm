package DBIx::QuickORM::Role::Conflator;
use strict;
use warnings;

our $VERSION = '0.000001';

use Carp qw/confess/;

use Role::Tiny;

requires 'qorm_inflate';
requires 'qorm_deflate';

sub qorm_immutible { 0 }

sub qorm_sql_type { confess "No sql type defined" }

1;
