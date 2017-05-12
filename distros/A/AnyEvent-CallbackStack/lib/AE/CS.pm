package AE::CS;

use AnyEvent::CallbackStack;

our $VERSION = $AnyEvent::CallbackStack::VERSION;

=encoding utf8

=head1 NAME

AE::CS - Shorter AnyEvent::CallbackStack API.

Inspired by AE.
Starting with version 0.05, AnyEvent::CallbackStack officially supports a second, much
simpler in name, API that is designed to reduce the typing.

There is No Magic like what AE has on reducing calling and memory overhead.

See the L<AnyEvent::CallbackStack> manpage for details.

=head1 SYNOPSIS

Use L<AE::CS> with the following style.

	use feature 'say';
	use AnyEvent::CallbackStack;
	
	my $cs = AE::CS;
	my $cv = AE::cv;
	
	$cs->add( sub { $cv->send( $_[0]->recv ) } );
	$cs->start('hello world');
	say $cv->recv;

# or

	my $cs = AE::CS;
	http_get http://BlueT.org => sub { $cs->start($_[0]) };
	$cs->add( sub { say $_[0]->recv } );

# or

	my $cs = AE::CS;
	my %foo = (bar => vbar, yohoo => vyohoo);
	
	$cs->start( %foo );
	$cs->add( sub {
		my %foo = $_[0]->recv;
		$cs->next( $foo{'bar'}, $foo{'yohoo'} );
	});
	
	$cv = $cs->last;
	$cv->cb( sub {
		my @a = $_[0]->recv;
		$cv->send( $a[0].$a[1] )
	});
	
	say $cv->recv;


=head1 METHODS

=head2 start

Start and walk through the Callback Stack from step 0.

	$cs->start( 'foo' );

=head2 add

Add (append) callback into the Callback Stack.

	$cs->add( $code_ref );

=head2 next

Check out from the current step and pass value to the next callback in callback stack.

	$cs->next( @result );

IMPORTANT:
Remember that only if you call this method, the next callback in stack will be triggered.

=head2 step

Experimental.

Start the callback flow from the specified step.

	$cs->step( 3, @data );

=head2 last

Get the very last L<AnyEvent::CondVar> object.

Usually it's called when you are writing a module and need to return it to your caller.

	my $cv = $cs->last;
	# or
	return $cs->last;


=head1 AUTHOR

BlueT - Matthew Lien - 練喆明, C<< <BlueT at BlueT.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-anyevent-callbackstack at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AnyEvent-CallbackStack>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AnyEvent::CallbackStack


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AnyEvent-CallbackStack>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AnyEvent-CallbackStack>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/AnyEvent-CallbackStack>

=item * Search CPAN

L<http://search.cpan.org/dist/AnyEvent-CallbackStack/>

=item * Launchpad

L<https://launchpad.net/p5-anyevent-callbackstack>

=item * GitHub

L<https://github.com/BlueT/AnyEvent-CallbackStack>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 BlueT - Matthew Lien - 練喆明.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of AnyEvent::CallbackStack

