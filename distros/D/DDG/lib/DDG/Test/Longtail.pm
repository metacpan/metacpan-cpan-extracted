package DDG::Test::Longtail;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Adds keywords to easily test Longtail plugins.
$DDG::Test::Longtail::VERSION = '1016';
use strict;
use warnings;
use Carp;
use Test::More;
use DDG::Test::Block;
use DDG::Longtail;
use Package::Stash;


sub import {
	my ( $class, %params ) = @_;
	my $target = caller;
	my $stash = Package::Stash->new($target);
}

1;

__END__

=pod

=head1 NAME

DDG::Test::Longtail - Adds keywords to easily test Longtail plugins.

=head1 VERSION

version 1016

=head1 DESCRIPTION

Installs functions for testing Longtails.

B<Warning>: Be aware that you only use this module inside your test files in B<t/>.

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
