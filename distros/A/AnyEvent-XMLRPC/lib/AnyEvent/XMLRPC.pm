package AnyEvent::XMLRPC;

use common::sense;
# roughly the same as, with much lower memory usage:
#
# use strict qw(vars subs);
# use feature qw(say state switch);
# no warnings;

use utf8;
#~ use Data::Dumper;
use Frontier::RPC2;

use base qw(AnyEvent::HTTPD);

=encoding utf8

=head1 NAME

AnyEvent::XMLRPC - Non-Blocking XMLRPC Server. Originally a AnyEvent implementation of Frontier.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

    use AnyEvent::XMLRPC;

	my $serv = AnyEvent::XMLRPC->new(
		methods => {
			'echo' => \&echo,
		},
	);
or

	my $serv = AnyEvent::XMLRPC->new(
		port	=> 9090,
		uri	=> "/RPC2",
		methods => {
			'echo' => \&echo,
		},
	);

and

	sub echo {
		@rep = qw(bala bababa);
		return \@rep;
	}

	$serv->run;

=head1 DESCRIPTION

I<AnyEvent::XMLRPC> is a Non-Blocking XMLRPC Server.
Originally a L<AnyEvent> implementation of L<Frontier>.
I<AnyEvent::XMLRPC> is base on elmex's L<AnyEvent::HTTPD>.

=head1 FUNCTIONS

=head2 new (%options)

=cut

sub new {
	my $class = shift;
	my %args = @_;
	
	$args{'port'} ||= 9090;
	
	# extract args which are not for httpd
	my $methods = delete $args{'methods'};
	my $uri = delete $args{'uri'};
	$uri ||= "/RPC2";
	
	# get a new clean AnyEvent::HTTPD
	my $self = $class->SUPER::new(%args);
	return undef unless $self;
	
	# Now I'm AnyEvent::XMLRPC
	bless $self, $class;
	
	
	# register methods, use Frontier::RPC2 to encode/decode xml
	${$self}{'methods'} = $methods;
	${$self}{'decode'} = new Frontier::RPC2 'use_objects' => $args{'use_objects'};
	
	
	# register AnyEvent(::HTTPD) callbacks
	$self->reg_cb (
		'/RPC2' => sub {
			my ($httpd, $req) = @_;
			
			#~ my $reply = ${$self}{'decode'}->serve(
					#~ $req->content, ${$self}{'methods'}
			#~ );
			
			$req->respond ({ content => [
				'text/xml',
				${$self}{'decode'}->serve(
					$req->content, ${$self}{'methods'}
				)
			]});
			
			$httpd->stop_request;
		},
		'' => sub {
			my ($httpd, $req) = @_;
			$req->respond ({ content => ['text/html',
				"I'm not something you think I am..."
			]});
		},
	);

	return $self;
}

=head1 AUTHOR

BlueT - Matthew Lien - 練喆明, C<< <BlueT at BlueT.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-anyevent-xmlrpc at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AnyEvent-XMLRPC>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AnyEvent::XMLRPC


You can also look for information at:

=over 4

=item * Git repository

L<http://github.com/BlueT/AnyEvent-XMLRPC>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AnyEvent-XMLRPC>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AnyEvent-XMLRPC>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/AnyEvent-XMLRPC>

=item * Search CPAN

L<http://search.cpan.org/dist/AnyEvent-XMLRPC>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 BlueT - Matthew Lien - 練喆明, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of AnyEvent::XMLRPC
