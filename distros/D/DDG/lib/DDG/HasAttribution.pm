package DDG::HasAttribution;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Role for a plugin that is able to give attribution informations
$DDG::HasAttribution::VERSION = '1017';
use Moo::Role;

requires qw(
	get_attributions
);


1;

__END__

=pod

=head1 NAME

DDG::HasAttribution - Role for a plugin that is able to give attribution informations

=head1 VERSION

version 1017

=head1 DESCRIPTION

This L<Moo::Role> is attached to plugins which are able to give attribution
back. It still can be an empty attribution.

The class using this role must implement a B<get_attributions> function which
gives back the attribution array.

For more information about the attributions see L<DDG::Meta::Attribution>.

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
