
# (c) 2009 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
use 5.006; use strict; use warnings;

our $VERSION = '0.002';

package Trustee;

use Data::Type qw(:all);
use Error qw(:try);

Class::Maker::class
{
	public =>
	{
		string => [qw( field type id tiewith )],

		hash => [qw( session args )],
	},
};

sub _preinit : method
{
	my $this = shift;

		$this->tiewith( 'Apache::Session::MySQL' );

		$this->args( { DataSource => 'dbi:mysql:sessions' } );
}

sub _postinit : method
{
	my $this = shift;

		eval 'use '.$this->tiewith;

		die $@ if $@;

		my %session;

		tie( %session, $this->tiewith, $this->id, \%{ $this->args } ) or die "failed to tie to ".$this->tiewith;

		$this->id( $session{_session_id} );

		$this->session( \%session );
}

sub exists : method
{
	my $this = shift;

		my $key = shift;

return exists $this->session->{$key};
}

sub delete : method
{
	my $this = shift;

		my $key = shift;

return delete $this->session->{$key};
}

sub store : method
{
	my $this = shift;

		my %args = @_;

return @{$this->session}{ keys %args } = values %args;
}

sub retrieve : method
{
	my $this = shift;

	my $bouncer = shift;

		my @list;

		while( my ( $key, $obj ) = each %{ $this->session } )
		{
			next if $key eq '_session_id';

			if( $bouncer->inspect( $obj ) )
			{
			        push @list, $obj;
			}
		}

return wantarray ? @list : \@list;
}

sub DESTROY
{
	my $this = shift;

		untie %{ $this->session } if $this->session;
}

1;

__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Trustee - An persistance storage specialized on objects

=head1 SYNOPSIS

	use class::examples::User;

	use Object::Bouncer;

	use Data::Dumper;

		# not visible, but default tiewith is Apache::Session::MySQL

	my $schatzmeister = new Object::Trustee();

		# here an alternative

	my $schatzmeister = new Object::Trustee(

		tiewith => 'Apache::Session::File',

		args => { Directory => 'c:/temp/sessiondata', LockDirectory   => 'c:/temp/sessiondata/locks' }

	);

	print 'Session-ID: ', $schatzmeister->id, "\n\n";

	my %gruppe = (

		toni => new User( firstname => 'toni', email => 'toni@wrong' ),

		eva => new User( firstname => 'eva', email => 'eva@any.de' ),

		maren => new User( firstname => 'maren' )

		);

	print "\n", 'Users:';

	print Dumper \%gruppe;

	$schatzmeister->store( %gruppe );

		# bouncer let filled email fields in....

	my $emailtester = new Object::Bouncer( );

	$emailtester->addtest(

	        new Object::Bouncer::Test( field => 'email', type => 'true' ),
	);

	my $list = $schatzmeister->retrieve( $emailtester );

		# now, bouncer only leaves <valid> emails in...

	print "\n\nUsers with email field filled:";

	my $emailchecker = new Object::Bouncer( );

	$emailchecker->addtest(

	        new Object::Bouncer::Test( field => 'email', type => 'email' ),
	);

	print Dumper $list;

	my $list = $schatzmeister->retrieve( $emailchecker );

	print "\n\nUsers with valid email:";

	print Dumper $list;

=head1 DESCRIPTION

A Trustee keeps files for other people about other people. This files can be modified / requested.
On the backend the trustee object uses Apache::Sesssion tied hashes. Object::Bouncer's objects are
utilized when retrieving selectivly (i.e.filtering).

=head2 EXPORT

None by default.

=head1 PREREQUISITES

	- Apache::Session::* to keep state.
	- Object::Bouncer to retrieve selectivly

=head1 AUTHOR

Murat Uenalan, murat.uenalan@gmx.de

=head1 SEE ALSO

Verify, L<perl>

=cut
