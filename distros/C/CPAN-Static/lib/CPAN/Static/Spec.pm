package CPAN::Static::Spec;
$CPAN::Static::Spec::VERSION = '0.004';
use strict;
use warnings;

1;

# ABSTRACT: Static install specification for CPAN distributions

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Static::Spec - Static install specification for CPAN distributions

=head1 VERSION

version 0.004

=head1 DESCRIPTION

*THIS DOCUMENT IS STILL A DRAFT*

This document describes a way for CPAN clients to install
distributions without having to run a F<Makefile.PL> or a F<Build.PL>

=head1 PURPOSE

Historically, Perl distributions have always been able to build, test
and install without any help of a CPAN client. C<perl Makefile.PL>,
C<make>, C<make test>, C<make install>. This is a powerful feature,
but it is overly complicated for many modules that have no
non-standard needs.

=head1 CONTEXT

This specification relies on a number of other specifications. This
includes in particular on the L<CPAN Meta spec|CPAN::Meta::Spec>,
L<Build.PL Spec|CPAN::API::BuildPL>. The terms B<must>, B<should>,
B<may> and their negations have the usual IETF semantics
L<RFC2119|https://www.ietf.org/rfc/rfc2119.txt>.

=head1 AUTHOR TOOL REQUIREMENTS

As static install intends to be an optimization, a valid F<Build.PL>
(per CPAN::API::BuildPL) or F<Makefile.PL> B<must> be present as a
fallback.

=head1 META REQUIREMENTS

The author tool will add an C<x_static_install> entry to the C<META>.
This entry will contain the version of the C<CPAN::Static::Spec> that
it expects the install tool to perform. The install tool C<must not>
perform a static install if it doesn't support the specified version.

=head1 FLOW OF EXECUTION

Building a distribution has four stages. They B<must> be performed in
order, and any error in one stage B<must> abort the entire process,
unless the user explicitly asks otherwise; the CPAN client B<may> try
to fall back on dynamic install on error. Actions B<must> be done
during build-time unless noted otherwise. The order of different
actions within the same phase is unspecified. Arguments that would be
passed to a stage for a dynamic install B<must> be handled by the CPAN
client exactly as in CPAN::API::BuildPL.

=head2 Configuration

The cpan client b<must> be able to configure a distribution. A valid
F<MYMETA.json> (with the C<dynamic_config> key set to C<0>) B<must> be
generated, it B<may> be copied verbatim to from F<META.json>. The same
may be done for F<MYMETA.yml>/F<META.yml>. This action B<must> be done
during configure-time.

=head2 Building

Various actions must or may be performed during the building stage.

=over 4

=item * module files

The cpan client B<must> be able to build and install modules. It
B<must> look recursively in F<lib/> for all F<*.pm> and F<*.pod> files
and copy these to the appropriate location for C<lib> files during
install. If applicable, these modules B<should> be autosplit and their
permissions B<should> be set appropriately for that platform.

=item * script files

The cpan client B<must> be able to build and install scripts. It
B<must> look non-recursively in F<script/> for all files and install
these to the appropriate location for C<script> files during
intstall. Their permissions B<must> be set appropriately for that
platform for an executable and if necessary on that platform helpers
B<must> be added.

=item * documentation

The cpan client B<must> be able to build and install platform
appropriate documentation for modules and scripts from POD unless
configured otherwise. The modules and scripts B<must> be found as
described for C<module files> and C<script files>. If generating man
pages, they B<must> be put in appropriate location for C<libdoc> and
C<bindoc>. If generating HTML documentation, they B<must> be put in
the location for C<libhtml> and C<binhtml>.

=item * sharedir

Thee cpan client B<must> be able to build and install a distribution
sharedir. The cpan client B<must> install the content of F<share/> to
F<auto/share/dist/$distribution_name/> subdirectory of the appropriate
directory for C<lib> files, where C<$distribution_name> is defined by
the C<name> field in the META file.

=back

=head2 test

The cpan client B<must> be able to test modules. Unless the user has
explicitly asked this step to be skipped, it B<must> look recursively
in F<t/> for all F<*.t> files and run them through a TAP harness. A
failure of any of the tests B<must> be considered a fatal error.

=head2 install

The cpan client B<must> be able to install the contents of
F<blib/>. The files and the generated metadata B<must> be installed as
described in C<CPAN::API::BuildPL> 1.0.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
