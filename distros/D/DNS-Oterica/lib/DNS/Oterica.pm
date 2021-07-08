use strict;
use warnings;
package DNS::Oterica;
# ABSTRACT: build dns configuration more easily
$DNS::Oterica::VERSION = '0.312';
#pod =head1 WARNING
#pod
#pod B<HIGHLY EXPERIMENTAL>
#pod
#pod This code is really not stable yet.  We're using it, and we're going to feel
#pod free to make incompatible changes to it whenever we want.  Eventually, that
#pod might change and we will reach a much stabler release cycle.
#pod
#pod This code has been released so that you can see what it does, use it
#pod cautiously, and help guide it toward a stable feature set.
#pod
#pod =head1 OVERVIEW
#pod
#pod DNS::Oterica is a system for generating DNS server configuration based on
#pod system definitions and role-based plugins.  You need to provide a few things:
#pod
#pod =head2 domain definitions
#pod
#pod Domains are groups of hosts.  You know, domains.  This is a DNS tool.  If you
#pod don't know what a domain is, you're in the wrong place.
#pod
#pod =head2 host definitions
#pod
#pod A host is a box with one or more interfaces.  It is part of a domain, it has a
#pod hostname and maybe some aliases.  It's a member of zero or more node groups.
#pod
#pod =head2 node families
#pod
#pod Nodes (both hosts and domains) can be parts of families.  Families are groups
#pod of behavior that nodes perform.  A family object is instantiated for each
#pod family, and once all nodes have been added to the DNS::Oterica hub, the family
#pod can emit more configuration.
#pod
#pod =head1 I WANT TO KNOW MORE
#pod
#pod Please read L<DNS::Oterica::Tutorial|DNS::Oterica::Tutorial>, which may or may
#pod not yet exist.
#pod
#pod =head1 TODO
#pod
#pod There's a lot of stuff to do.
#pod
#pod  * determine location automatically based on world IP
#pod  * look into replacing nodefamily behavior with Moose roles
#pod  * rewrite tests to use Diagnostic recordmaker
#pod  * thorough tests for TinyDNS recordmaker
#pod  * simpler method to say "being in family X implies being in Y"
#pod  * means to replace Module::Pluggable with list of families to register
#pod  * means to track concepts like virts/zones, zonehosts, per-host interfaces
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DNS::Oterica - build dns configuration more easily

=head1 VERSION

version 0.312

=head1 OVERVIEW

DNS::Oterica is a system for generating DNS server configuration based on
system definitions and role-based plugins.  You need to provide a few things:

=head2 domain definitions

Domains are groups of hosts.  You know, domains.  This is a DNS tool.  If you
don't know what a domain is, you're in the wrong place.

=head2 host definitions

A host is a box with one or more interfaces.  It is part of a domain, it has a
hostname and maybe some aliases.  It's a member of zero or more node groups.

=head2 node families

Nodes (both hosts and domains) can be parts of families.  Families are groups
of behavior that nodes perform.  A family object is instantiated for each
family, and once all nodes have been added to the DNS::Oterica hub, the family
can emit more configuration.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 WARNING

B<HIGHLY EXPERIMENTAL>

This code is really not stable yet.  We're using it, and we're going to feel
free to make incompatible changes to it whenever we want.  Eventually, that
might change and we will reach a much stabler release cycle.

This code has been released so that you can see what it does, use it
cautiously, and help guide it toward a stable feature set.

=head1 I WANT TO KNOW MORE

Please read L<DNS::Oterica::Tutorial|DNS::Oterica::Tutorial>, which may or may
not yet exist.

=head1 TODO

There's a lot of stuff to do.

 * determine location automatically based on world IP
 * look into replacing nodefamily behavior with Moose roles
 * rewrite tests to use Diagnostic recordmaker
 * thorough tests for TinyDNS recordmaker
 * simpler method to say "being in family X implies being in Y"
 * means to replace Module::Pluggable with list of families to register
 * means to track concepts like virts/zones, zonehosts, per-host interfaces

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Chris Nehren Joel Shea

=over 4

=item *

Chris Nehren <apeiron@cpan.org>

=item *

Joel Shea <jshea@fastmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
