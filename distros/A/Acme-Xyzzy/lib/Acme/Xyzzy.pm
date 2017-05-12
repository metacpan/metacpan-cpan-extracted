package Acme::Xyzzy;

# ABSTRACT: Nothing happens.

use strict;
use warnings;

use Exporter;
use vars qw(@ISA @EXPORT);

our $VERSION = "0.001";

@ISA = ('Exporter');
@EXPORT = ('xyzzy');


sub xyzzy {
	print "Nothing happens.\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Xyzzy - Nothing happens.

=head1 VERSION

version 0.001

=head1 SYNOPSIS

	use Acme::Xyzzy;

	xyzzy;

=head1 DESCRIPTION

Nothing happens.

=head2 Methods

=over 12

=item C<< xyzzy() >>

Nothing happens.

=back

=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/Xyzzy_%28computing%29>

=head1 AUTHOR

William Woodruff <william@tuffbizz.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by William Woodruff.

This is free software, licensed under:

  The MIT (X11) License

=cut
