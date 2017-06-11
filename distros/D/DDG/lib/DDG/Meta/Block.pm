package DDG::Meta::Block;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Inject keywords to make a L<DDG::Block::Blockable> plugin
$DDG::Meta::Block::VERSION = '1017';
use strict;
use warnings;
use Carp;
use DDG::Block::Blockable::Triggers;
use Package::Stash;
require Moo::Role;


my %applied;

sub apply_keywords {
	my ( $class, $target ) = @_;

	return if exists $applied{$target};
	$applied{$target} = undef;

	#
	# triggers
	#

	my $triggers;
	my $stash = Package::Stash->new($target);


	$stash->add_symbol('&triggers_block_type',sub { $triggers->block_type });


	$stash->add_symbol('&get_triggers',sub { $triggers->get });


	$stash->add_symbol('&has_triggers',sub { $triggers ? 1 : 0 });


	$stash->add_symbol('&triggers',sub {
		$triggers = DDG::Block::Blockable::Triggers->new unless $triggers;
		$triggers->add(@_)
	});

	#
	# apply role
	#

	Moo::Role->apply_role_to_package($target,'DDG::Block::Blockable');

}

1;

__END__

=pod

=head1 NAME

DDG::Meta::Block - Inject keywords to make a L<DDG::Block::Blockable> plugin

=head1 VERSION

version 1017

=head1 DESCRIPTION

=head1 EXPORTS FUNCTIONS

=head2 triggers_block_type

Gives back the block type for this plugin

=head2 get_triggers

=head2 has_triggers

Gives back if the plugin has triggers at all

=head2 triggers

Adds a new trigger. Possible parameter are block specific, so see
L<DDG::Block::Words> or L<DDG::Block::Regexp> for more informations.

=head1 METHODS

=head2 apply_keywords

Uses a given classname to install the described keywords.

It also adds the role L<DDG::Block::Blockable> to the target classname.

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
