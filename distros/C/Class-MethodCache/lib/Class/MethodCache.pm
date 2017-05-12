#!/usr/bin/perl

package Class::MethodCache;

use strict;
use warnings;

use vars qw($VERSION @ISA);

BEGIN {
	$VERSION = '0.05';

	local $@;

	eval {
		require XSLoader;
		__PACKAGE__->XSLoader::load($VERSION);
		1;
	} or do {
		warn $@;
		require DynaLoader;
		push @ISA, 'DynaLoader';
		__PACKAGE__->bootstrap($VERSION);
	};

}

use Sub::Exporter -setup => {
	exports => [qw(
		get_gv_refcount
		set_cvgen
		get_cvgen
		set_cv
		get_cv
		get_class_gen

		delete_cv
		update_cvgen
		set_cached_method
		get_cached_method
	)],
	groups => {
		default => [qw(
			update_cvgen
			set_cached_method
			get_cached_method
		)],
	},
};



__PACKAGE__

__END__

=pod

=head1 NAME

Class::MethodCache - Manipulate Perl's method resolution cache

=head1 SYNOPSIS

	use Class::MethodCache;

=head1 DESCRIPTION

=head1 EXPORTS

=head2 High level API

=over 4

=item set_cached_method $glob, $coderef

Sets the CV slot of the glob to $coderef, and sets the cvgen slot of the glob
to signify that this is a currently valid cache entry.

Overwriting a real method is an error. Use C<set_cvgen> with C<get_class_gen> first
to force this.

Adding a cache entry to a shared GV (get_gv_refcount > 1) is an error, too,
because the GV is shared by more than one stash and this will cause strange
behavior. Use C<set_cv> and C<set_cvgen> for that. L<Devel::Peek> will probably
tell you wtf is going on.

=item get_cached_method $glob

Gets the CV slot of the glob if this is a currently valid cache entry.

=item update_cvgen $glob

Updates the cvgen slot to mark this cache entry as valid.

It is an error to update cvgen if it is not set but the CV slot is set, because
that will overwrite a real method.

To force this behavior call C<set_cvgen> with C<get_class_gen>.

=item delete_cv $glob

Remove the CV and reset the CVGEN of a glob.

=back

=head2 Low level API

=over 4

=item get_class_gen $class

Returns the current class generation for a class.

This is like L<mro/get_pkg_gen> (See also L<MRO::Compat>).

This is equal to C<PL_sub_generation> under perls predating L<mro>, but still
requires C<$class> to be passed in for consistency.

This is provided mainly for convenience, for furthere manipuatlion of method
caching please consult L<MRO::Compat>, it has all the encessary functionality
for manipulating cache invalidation. Using it in conjunction with
L<Class::C3::XS> is reccomended on perls below 5.9.5.

=item get_cv $glob

This differs from C<*{$glob}{CODE}> in that it will return the cached code ref
if any, wheras accessing the code slot is more like C<GvCVu(gv)> (which checks
that C<GvCVGEN> is == 0 first).

=item set_cv $glob, $coderef

Manipulate C<GvCV> directly.

A value of C<undef> will clear the field.

=item get_cvgen $glob

Returns the cvgen slot of the gv.

=item set_cvgen $glob, $uint

Manipulate C<GvCVGEN> directly.

Any value greater than zero implies the C<GvCV> is a cache entry. If C<GvCV> is
not set then this is a cache of a failed lookup.

=item 

=back

=head1 SEE ALSO

L<mro>, L<MRO::Compat>, L<Class::C3::XS>

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/code>, and use C<darcs send> to commit
changes.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
