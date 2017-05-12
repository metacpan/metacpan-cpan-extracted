#!/usr/bin/perl
package t::Test;
use Burpsuite::Parser;
use Test::Class;     eval 'use Test::Class';
plan( skip_all => 'Test::Class required for additional testing' ) if $@;

use base 'Test::Class';
use Test::More;

sub setup : Test(setup => no_plan) {
    my ($self) = @_;
    
    my $parser = XML::LibXML->new();
    my $doc = $parser->parse_file('t/test1.xml');

    $self->{parser1} = Burpsuite::Parser->parse_file('t/test1.xml');
}
1;
