package DDG::Block::Blockable;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Role for plugins that can go into a block
$DDG::Block::Blockable::VERSION = '1017';
use Moo::Role;

requires qw(
	get_triggers
	has_triggers
	triggers_block_type
	triggers
);


has block => (
	is => 'ro',
	required => 1,
);

1;

__END__

=pod

=head1 NAME

DDG::Block::Blockable - Role for plugins that can go into a block

=head1 VERSION

version 1017

=head1 DESCRIPTION

This role is for plugins that can go into a plugin. The required functions are
given via L<DDG::Meta::Block>, but can also be made in an own implementation.

The class using this role require B<get_triggers>, B<has_triggers>,
B<triggers_block_type> and B<triggers>.

Please lookup in L<DDG::Meta::Block> how you have to set them if you want to
make your own implementation.

=head1 ATTRIBUTES

=head2 block

Every blockable plugin requires a block as attribute on creation.

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
