package DDG::IsSpice;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Role for Spice
$DDG::IsSpice::VERSION = '1016';
use Moo::Role;

requires qw(
	handle_request_matches
);


1;

__END__

=pod

=head1 NAME

DDG::IsSpice - Role for Spice

=head1 VERSION

version 1016

=head1 DESCRIPTION

This role is for plugins which are Spice. They need to implement a
B<handle_request_matches> function.

Please see L<DDG::Meta::RequestHandler> and L<DDG::Meta> for more information.

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
