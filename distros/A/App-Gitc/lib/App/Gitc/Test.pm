package App::Gitc::Test;
use strict;
use warnings;

# ABSTRACT: Test class for gitc
our $VERSION = '0.60'; # VERSION

use Test::More '';
use App::Gitc::Util qw( branch_point unpromoted );
use Exporter 'import';

BEGIN {
    our @EXPORT = qw( branch_point_is unpromoted_is );
};

sub branch_point_is {
    my ( $ref, $expected, $message ) = @_;
    my $sha1 = branch_point($ref);
    Test::More::is( $sha1, $expected, $message );
}

sub unpromoted_is {
    my ( $source, $target, $expected, $message ) = @_;
    my @changesets = unpromoted( $source, $target );
    Test::More::is_deeply(\@changesets, $expected, $message);
}

1;

__END__

=pod

=head1 NAME

App::Gitc::Test - Test class for gitc

=head1 VERSION

version 0.60

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Grant Street Group.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
