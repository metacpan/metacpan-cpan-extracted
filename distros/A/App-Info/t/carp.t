#!/usr/bin/perl -w

use strict;
use Test::More tests => 23;

my $msg = "Error retrieving version";

# Set up an App::Info subclass to ruin.
package App::Info::Category::FooApp;
use App::Info;
use File::Spec;
use strict;
use vars qw(@ISA);
@ISA = qw(App::Info);

sub version { shift->error($msg) }

(my $fn = File::Spec->catfile('t', 'carp.t')) =~ s/\\/\\\\/g;

package main;

BEGIN { use_ok('App::Info::Handler::Carp') }

# Try confess first.
ok( my $app = App::Info::Category::FooApp->new( on_error => 'confess'),
    "Set up for confess" );
eval { $app->version };
ok( my $err = $@, "Get confess" );
like( $err, qr/^Error retrieving version/, "Starts with confess message" );
like( $err, qr/called (?:at\s+$fn|$fn\s+at)\s+line/, "Confess has stack trace" );

# Now try croak.
ok( $app = App::Info::Category::FooApp->new( on_error => 'croak'),
    "Set up for croak" );
eval { $app->version };
ok( $err = $@, "Get croak" );
like( $err, qr/^Error retrieving version at.*$fn/, "Starts with croak message" );
unlike( $err, qr/called (?:at\s+$fn|$fn\s+at)\s+line/, "Croak has no stack trace" );

# Now die.
ok( $app = App::Info::Category::FooApp->new( on_error => 'die'),
    "Set up for die" );
eval { $app->version };
ok( $err = $@, "Get die" );
like( $err, qr/^Error retrieving version/, "Starts with die message" );
unlike( $err, qr/called (?:at\s+$fn|$fn\s+at)\s+line/, "Die has no stack trace" );

# Set up to capture warnings.
$SIG{__WARN__} = sub { $err = shift };

# Cluck.
ok( $app = App::Info::Category::FooApp->new( on_error => 'cluck'),
    "Set up for cluck" );
$app->version;
like( $err, qr/^Error retrieving version/, "Starts with cluck message" );
like( $err, qr/called (?:at\s+$fn|$fn\s+at)\s+line/, "Cluck as stack trace" );

# Carp.
ok( $app = App::Info::Category::FooApp->new( on_error => 'carp'),
    "Set up for carp" );
$app->version;
like( $err, qr/^Error retrieving version/, "Starts with carp message" );
unlike( $err, qr/called (?:at\s+$fn|$fn\s+at)\s+line/, "Carp has no stack trace" );

# Warn.
ok( $app = App::Info::Category::FooApp->new( on_error => 'warn'),
    "Set up for warn" );
$app->version;
like( $err, qr/^Error retrieving version/, "Starts with warn message" );
unlike( $err, qr/called (?:at\s+$fn|$fn\s+at)\s+line/, "Warn has no stack trace" );

# Dissallow bogus error levels.
eval { App::Info::Category::FooApp->new( on_error => 'bogus') };
like( $@, qr/No such handler 'bogus'/, "Check for bogus error level" );
