#!perl
use strict;
use warnings;

use Test::More tests => 5;
use Test::NoWarnings;

my $CLASS;
my $USERID = 'username';
my $APPID  = 'MyApp';

BEGIN { $CLASS = 'App::Toodledo'; use_ok $CLASS }

my $todo = $CLASS->new( app_id => $APPID );

my @objects = map { App::Toodledo::Task->new( title => $_ ) }
                  qw(one two three four);
my $selector = sub { $_->title =~ /e/ };
my @found = $todo->grep_objects( \@objects, $selector );
ok eq_array [ map { $_->title } @found ], [ qw(one three) ];

$_->completed( 1 ) for @objects;

@found = $todo->select( \@objects, 'title =~ /e/' );
is scalar( @found ), 0;

$_->completed( 0 ) for @objects;
@found = $todo->select( \@objects, 'title =~ /e/' );
ok eq_array [ map { $_->title } @found ], [ qw(one three) ];

