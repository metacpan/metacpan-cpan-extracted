package DDG::Meta::AnyBlock;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Implement L<DDG::Block::Blockable::Any> to the plugin
$DDG::Meta::AnyBlock::VERSION = '1016';
use strict;
use warnings;
use Carp;
require Moo::Role;


my %applied;

sub apply_keywords {
	my ( $class, $target ) = @_;

	return if exists $applied{$target};
	$applied{$target} = undef;

	Moo::Role->apply_role_to_package($target,'DDG::Block::Blockable::Any');

}

1;

__END__

=pod

=head1 NAME

DDG::Meta::AnyBlock - Implement L<DDG::Block::Blockable::Any> to the plugin

=head1 VERSION

version 1016

=head1 DESCRIPTION

=head1 METHODS

=head2 apply_keywords

Adds the role L<DDG::Block::Blockable::Any> to the target classname. It's
named I<apply_keywords> to be the same as in the other meta classes which
actually really install keywords.

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
