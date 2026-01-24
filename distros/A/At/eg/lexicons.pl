use v5.42;
use lib '../lib';
use At;
#
my $at = At->new( share => '../share', host => 'https://bsky.social' );
use Data::Dumper;
print Dumper $at->_locate_lexicon('com.atproto.server.activateAccount');
print Dumper $at->_locate_lexicon('com.atproto.repo.defs#commitMeta');

=head1 NAME

lexicons.pl - Lexicon Loading Debugger

=head1 SYNOPSIS

    perl eg/lexicons.pl

=head1 DESCRIPTION

A simple diagnostic script to verify that At.pm can correctly locate
and load lexicon schemas from the C<share/> directory.

=cut
