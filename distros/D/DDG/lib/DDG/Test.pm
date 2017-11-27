package DDG::Test;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: TODO
$DDG::Test::VERSION = '1018';
use strict;
use warnings;
use Carp;
use Test::More;
use Package::Stash;

sub import {
	my ( $class, %params ) = @_;
	my $target = caller;
}

1;

__END__

=pod

=head1 NAME

DDG::Test - TODO

=head1 VERSION

version 1018

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
