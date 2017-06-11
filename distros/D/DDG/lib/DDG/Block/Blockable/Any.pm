package DDG::Block::Blockable::Any;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Role for something blockable that has no triggers
$DDG::Block::Blockable::Any::VERSION = '1017';
use Moo::Role;

with 'DDG::Block::Blockable';

sub get_triggers {}
sub triggers {}

sub has_triggers { 0 }
sub triggers_block_type { 'Any' }


1;

__END__

=pod

=head1 NAME

DDG::Block::Blockable::Any - Role for something blockable that has no triggers

=head1 VERSION

version 1017

=head1 DESCRIPTION

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
