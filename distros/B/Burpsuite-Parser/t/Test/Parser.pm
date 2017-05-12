#!/usr/bin/perl

package t::Test::Parser;

use base 't::Test';
use Test::More;
use Data::Dumper;
sub fields : Tests {
    my ($self) = @_;

    my $parser = $self->{parser1};
    my @issues = $parser->get_all_issues();
    my $issue1 = $issues[0];
    my $issue2 = $issues[1];
    my $issue3 = $issues[2];

    is ( $issue1->type, '3145984', 'issue1 type');
    is ( $issue1->path, '/beef/', 'issue1 path');
    is ( $issue1->severity, 'High', 'issue1 severity');

    is ( $issue2->type, '6291968', 'issue2 type');
    is ( $issue2->path, '/beef/js/msf.js', 'issue2 path');
    is ( $issue2->severity, 'Information', 'issue2 severity');

    is ( $issue3->type, '6291712', 'issue3 type');
    is ( $issue3->path, '/beef/images/', 'issue3 path');
    is ( $issue3->severity, 'Information', 'issue3 severity');
}
1;
