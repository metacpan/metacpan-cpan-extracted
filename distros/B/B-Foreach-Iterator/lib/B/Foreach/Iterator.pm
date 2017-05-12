package B::Foreach::Iterator;

use 5.008_008;
use strict;

our $VERSION = '0.07';

use Exporter ();
our @ISA    = qw(Exporter);
our @EXPORT = qw(iter);

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);


1;
__END__

=head1 NAME

B::Foreach::Iterator - Manipulates foreach iterators

=head1 VERSION

This document describes B::Foreach::Iterator version 0.07.

=head1 SYNOPSIS

	use B::Foreach::Iterator;

	foreach my $key(foo => 10, bar => 20, baz => 30){
		printf "%s => %s\n", $key => iter->next;
	}

=head1 DESCRIPTION

C<B::Foreach::Iterator> provides functions that manipulate C<foreach> iterators.

=head1 INTERFACE

=head2 Exported functions

=over 4

=item iter(?$label)

Finds a C<foreach> iterator, and returns it. You can supply a I<$label> if
necessary.

If no iterators are found, it dies.

=back

=head2 Instance methods

=over 4

=item I<$iterator>-E<gt>next()

Increases I<$iterator> and returns its value.

=item I<$iter>-E<gt>peek()

Returns the value of the next iterator.

=item I<$iter>-E<gt>is_last()

Returns whether the foreach loop iteration is last or not.

=item I<$iter>-E<gt>label()

Returns the label of I<$iterator>.

If I<$iterator> has no labels, it returns C<undef>.

=back

=head1 DEPENDENCIES

Perl 5.8.8 or later, and a C compiler.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 SEE ALSO

L<perlguts>.

F<pp_hot.c> for C<pp_iter()>.

F<cop.h> for C<struct block_loop> and C<struct context>.

=head1 AUTHOR

Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>.

=head1 ACKNOWLEDGEMENTS

Thanks to Hans Dieter Pearcey(HDP) for his suggestions.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Goro Fuji. Some rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
