package Catalyst::Plugin::Message;

use warnings;
use strict;
our $VERSION = '0.03';

sub errmsg {
	my $c = shift;
	my ( $key, $msg ) = @_;
	if ( $key and $msg ){
		$c->stash->{errmsg}{$key} = $msg if ( not defined $c->stash->{errmsg}{$key} );
	}else{
		return scalar keys %{$c->stash->{errmsg}};
	}
}

sub tipmsg {
	my $c = shift;
	my ( $key, $msg ) = @_;
	if ( $key and $msg ){
		$c->stash->{tipmsg}{$key} = $msg if ( not defined $c->stash->{tipmsg}{$key} );
	}else{
		return scalar keys %{$c->stash->{tipmsg}};
	}
}

sub diemsg {
	my $c = shift;
	my ( $msg, @string ) = @_;
	$c->stash->{diemsg} = sprintf( $msg, @string );
	$c->stash->{template} = 'error.tpl';
	$c->res->status(500);
	die $c->error(0);
}

1;

=pod

=head1 NAME

Catalyst::Plugin::Message - The great new Catalyst::Plugin::Message!

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

 # in your controller
 use Catalyst qw/Message/;
 sub register : Local {
     my ( $self, $c ) = @_;
     if ( $c->req->method eq 'POST' ){
        my $email = $c->req->param('email');
        $c->errmsg( email => 'email can not be empty.' ) unless defined $email;
        $c->errmsg( email => 'email invalid.' ) unless $email =~ /\@/;
        if ( not $c->errmsg ){
        	# save data
        }
     }
     $c->stash->{'template'} = 'register.tpl';
 }

 # register.tpl
 [% errmsg.email %]

=head2 errmsg

pass some error message return to the previous page, every message has a key to indicate which aspect.

you can make more error messages relate to a key, only the first message will save into stash.

=head2 tipmsg

same as errmsg, just make some tips message return.

=head3 diemsg

 # in your controller
 use Catalyst qw/Message/;
 sub edit : Local {
     my ( $self, $c ) = @_;
     my $client_id = $c->req->param('client_id');
     my $client = $c->model('DBIC::Client')->find( $client_id );
     $c->diemsg( "client not found with id: %s", $client_id ) unless $client;

	 # continue when $client object is valid
	 # ...
	 
     $c->stash->{'template'} = 'edit.tpl';
 }

 # error.tpl
 [% diemsg %]

Sometimes the fatal error occurs, which means we cannot continue to execute the rest code,
and we wanner just raise the error to the client. For example as above, if the $client object
not exists, maybe the parameter client_id invalid or the client has been deleted, then we need
tell that what happened, but the internal $c->error simple save the error informations into
stash and continue rest codes - of course we can use if-else to let it work, but why should we
make it simple, just like native die() did? Here diemsg() comes, and the error information is a
business logic, but not code logic, so we need not show the req-res-stash to user. Just tell your
user what happend, and make them understand what's the point. :)

=head1 AUTHOR

Chunzi, C<< <chunzi at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-plugin-message at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-Message>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::Message

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-Message>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-Message>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-Message>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-Message>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Chunzi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
