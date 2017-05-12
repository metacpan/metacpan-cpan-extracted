#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use DBIx::NoSQL::ClassScaffold;

my ( $schema_class, $class );

$schema_class = $class = DBIx::NoSQL::ClassScaffold->new;
ok( $class );
diag( $class->package );
$class->become_Schema;
diag( $class->package_meta->superclasses );

$class = DBIx::NoSQL::ClassScaffold->new;
ok( $class );
diag( $class->package );
$class->become_ResultClass_Store;
diag( $class->package_meta->superclasses );

$class->package->register( $schema_class->package, '__Store__' );

done_testing;
