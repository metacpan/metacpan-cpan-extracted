package DBIx::QuickORM::Schema::View;
use strict;
use warnings;

our $VERSION = '0.000014';

use Carp qw/croak/;
use Scalar::Util qw/blessed/;

use parent 'DBIx::QuickORM::Schema::Table';
use DBIx::QuickORM::Util::HashBase;

sub is_view { 1 }

1;
