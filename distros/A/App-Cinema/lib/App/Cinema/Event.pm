package App::Cinema::Event;
use Moose;
use namespace::autoclean;
use HTTP::Date qw/time2iso/;

BEGIN {
	our $VERSION = $App::Cinema::VERSION;
}

=head1 NAME

App::Cinema::Event - Record a user's 
actions in the system.

=head1 SYNOPSIS

	my $e = App::Cinema::Event->new();
	$e->content(' deleted account : ');
	$e->target($id);
	$e->insert($c);
	
	The result will look like this :
	
	USER		 ACTION					DESC		TIME
	test02  	 deleted account :  	test02  	2010-01-22 13:01:54

=head1 DESCRIPTION

Record a user's actions in the system.

=pod

=head2 Methods

=over 12

=item C<uid>

This method gets/sets uid attribute of this object.

=cut

has 'uid' => (
	is      => 'rw',
	isa     => 'Str',
	default => ""
);

=item C<desc>

This method gets/sets desc attribute of this object.

=cut

has 'desc' => (
	is      => 'rw',
	isa     => 'Str',
	default => '',
);

=item C<now>

This method gets now time of this object.

=cut

has 'now' => (
	is      => 'ro',
	isa     => 'Str',
	default => sub { time2iso(time) }
);

=item C<target>

This method gets/sets target attribute of this object.

=cut

has 'target' => (
	is      => 'rw',
	isa     => 'Str',
	default => '',
);

=pod

=item C<insert>

This method adds a new event to the database.

=cut

sub insert {
	my ( $self, $c, ) = @_;

	my $username;
	if ( $self->uid() eq '' ) {
		$username = $c->user->obj->username();
	}
	else {
		$username = $self->uid();
	}

	$c->model('MD::Event')->create(
		{
			uid    => $username,
			content  => $self->desc(),
			target => $self->target(),
			e_time => $self->now()
		}
	);
}
1;

=back

=head1 AUTHOR

Jeff Mo <mo0118@gmail.com>
