package DDG::IsControllable;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Role for data managed inside the DuckDuckGo infrastructure
$DDG::IsControllable::VERSION = '1017';
use Moo::Role;


has is_cached => (
	is => 'ro',
	default => sub { shift->isa('DDG::ZeroClickInfo::Spice') ? 1 : 0 },
);


has is_unsafe => (
	is => 'ro',
	default => sub { 0 },
);


has ttl => (
	is => 'ro',
	predicate => 'has_ttl',
);


has caller => (
	is => 'ro',
    predicate => 'has_caller',
);


1;

__END__

=pod

=head1 NAME

DDG::IsControllable - Role for data managed inside the DuckDuckGo infrastructure

=head1 VERSION

version 1017

=head1 DESCRIPTION

This role is used for classes which should be cacheable or marked as safe or
unsafe for kids.

=head1 ATTRIBUTES

=head2 is_cached

Defines if the data should get cached. Default on for spice, default off for
anything else.

=head2 is_unsafe

Define that this data might not be appropiate for underage.

=head2 ttl

If the data is cached, which time to life for the data should be set. If none
is given, then unlimited cachetime will be assumed.

=head2 caller

Must be set with the class generating the result for fetching additional
configuration from there.

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
