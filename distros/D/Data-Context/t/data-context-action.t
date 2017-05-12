use strict;
use warnings;
use Test::More;
use Path::Tiny;
use Data::Dumper qw/Dumper/;
use AnyEvent;
use AnyEvent::HTTP;
use Test::Warn;
use lib 't/lib';

use Data::Context;

eval { require JSON; require XML::Simple; require YAML::XS; };
plan skip_all => 'This test requires JSON, XML::Simple and YAML::XS to be installed to run' if $@;

my $path = path($0)->parent->child('dc');

test_creation();
test_getting();

done_testing;

sub test_creation {
    my $dc = Data::Context->new( path => "$path" );
    isa_ok $dc, 'Data::Context', 'get a new object correctly';
}

sub test_getting {
    my $dc = Data::Context->new(
        path     => "$path",
        fallback => 1,
    );
    my $data = $dc->get( 'deep/action', { test => { value => [qw/a b/] } } );

    ok $MyApp::MyAction::INSTANCIATED, 'Loaded class';
    ok !$data->{content}{with}[0]{some}{deep}[0]{nesting}{replace}, "Replace is removed";
    is $data->{content}{with}[0]{some}{deep}[0]{nesting}{some}, 'data', "new data set";
}

