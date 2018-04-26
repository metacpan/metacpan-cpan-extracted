use Carp qw(carp);
carp "The xisbn service was due to be turned off on March 15, 2016.";
package Business::xISBN;
use Business::ISBN 2;

package # hide from PAUSE
	Business::ISBN;

use strict;

=encoding utf8

=head1 NAME

Business::xISBN - access the xISBN service

=head1 SYNOPSIS

	use Business::ISBN;
	use Business::xISBN;

	# maybe you don't care what it is as long as everything works
	my $isbn = Business::ISBN->new( $ARGV[0] );
	my @xisbns = $isbn->xisbn;


=head1 DESCRIPTION

This is a mixin for L<Business::ISBN>. Although it looks like it has
a different package name, it really declares methods to L<Business::ISBN>.
This means that you can use this module and not change code from the 2.x
major version of L<Business::ISBN>.

This is not a complete interface to xISBN. It merely retrieves related
ISBNs. If someone wants to expand this to handle other parts of the API,
send a pull request!

=cut

$VERSION = "1.003";

=item xisbn

In scalar context, returns an anonymous array of related ISBNs using xISBN.
In list context, returns a list. It does not include the original ISBN.

This feature uses L<Mojo::UserAgent> or L<LWP::UserAgent> depending on
which one it finds first.

=cut

no warnings qw(redefine);

sub xisbn {
	my $self = shift;

	my $data = $self->_get_xisbn;
	$data =~ tr/x/X/;

	my @isbns = do {
		if( eval "require Mojo::DOM; 1" ) {
			my $dom = Mojo::DOM->new( $data );
			$dom->find( 'isbn' )->map('text')->each;
			}
		else {
			$data =~ m|<isbn.*?>(.*?)</isbn>|g;
			}
		};

	shift @isbns;
	wantarray ? @isbns : \@isbns;
	}

sub _get_xisbn {
	my $self = shift;

	my $data = eval {
		if( eval "require Mojo::UserAgent; 1" ) {
			Mojo::UserAgent->new->get( $self->_xisbn_url )->res->text;
			}
		elsif( eval "require LWP::Simple; 1" ) {
			LWP::Simple::get( $self->_xisbn_url );
			}
		else {
			carp "Could not load either Mojo::UserAgent or LWP::Simple to fetch xISBN\n";
			return;
			}
		};

	carp "Could not fetch xISBN data" unless defined $data;

	return $data;
	}

sub _xisbn_url {
	my $self = shift;
	my $isbn = $self->as_string([]);

	return "http://xisbn.worldcat.org/xid/isbn/$isbn";
	}

1;

__END__

=head1 SOURCE AVAILABILITY

This source is in Github:

    https://github.com/briandfoy/business-xisbn

=head1 AUTHOR

brian d foy C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.

=cut
