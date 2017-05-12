package App::Shotgun::Target;
BEGIN {
  $App::Shotgun::Target::AUTHORITY = 'cpan:GETTY';
}
BEGIN {
  $App::Shotgun::Target::VERSION = '0.001';
}
use strict;
use warnings;

# ABSTRACT: Base class for all App::Shotgun targets

use Moose::Role;
use MooseX::Types::Path::Class;

has shotgun => (
	isa => 'App::Shotgun',
	is => 'ro',
	required => 1,
	weak_ref => 1,
	handles => {
		error => '_error',
		ready => '_ready',
		xferdone => '_xferdone',
		file => 'current_file',
	},
);

has _type => (
	isa => 'Str',
	is => 'ro',
	lazy => 1,
	init_arg => undef,
	default => sub {
		my $self = shift;
		if ( ref( $self ) =~ /::([^\:]+)$/ ) {
			return $1;
		} else {
			die "Unknown object: $self";
		}
	},
);


has name => (
	isa => 'Str',
	is => 'ro',
	lazy => 1,
	default => sub {
		my $self = shift;
		my $str = $self->_type . "::" . $self->hostname;
		if ( $self->can( 'port' ) ) {
			$str .= ":" . $self->port;
		}
		$str .= "::" . $self->path;
		return $str;
	},
);


has hostname => (
	isa => 'Str',
	is => 'ro',
	required => 1,
);


has path => (
	isa => 'Path::Class::Dir',
	is => 'ro',
	coerce => 1,
	default => sub { Path::Class::Dir->new( '/' ) },
);

# the state this target is in
{
	use Moose::Util::TypeConstraints;

	# init means it's still connecting/authenticating to the target
	# ready means it's ready to transfer files
	# testdir means it's testing to see if a path exists on the target
	# dir means it's creating/processing a directory on the target
	# xfer means it's currently transferring a file to the target
	has state => (
		isa => enum( [ qw( init ready testdir dir xfer ) ] ),
		is => 'rw',
		default => 'init',
		init_arg => undef,
	);

	no Moose::Util::TypeConstraints;
}

# the file we are currently transferring's path entries
has _filedirs => (
	isa => 'ArrayRef[Str]',
	is => 'rw',
	default => sub { [] },
	init_arg => undef,
);

# directories we know that is on the server
has _knowndirs => (
	traits => ['Hash'],
	isa => 'HashRef[Str]',
	is => 'ro',
	init_arg => undef,
	default => sub {
		return {
			# obviously the root exists... :)
			'/' => 1,
		};
	},
	handles => {
		known_dir => 'exists',
	},
);

sub add_known_dir {
	my( $self, $path ) = @_;

	$self->_knowndirs->{ $path } = 1;
	return;
}

sub _build_filedirs {
	my $self = shift;

	my @dirs;
	foreach my $d ( $self->file->dir->dir_list ) {
		if ( ! defined $dirs[0] ) {
			push( @dirs, Path::Class::Dir->new( $self->path, $d )->stringify );
		} else {
			push( @dirs, Path::Class::Dir->new( $dirs[-1], $d )->stringify );
		}
	}

	# Weed out the known directories
	foreach my $d ( @dirs ) {
		if ( ! $self->known_dir( $d ) ) {
			push( @{ $self->_filedirs }, $d );
		}
	}

	return;
}

1;


__END__
=pod

=head1 NAME

App::Shotgun::Target - Base class for all App::Shotgun targets

=head1 VERSION

version 0.001

=head1 DESCRIPTION

The master target class, used in subclasses. Provides some convenience functions and common attributes.

=head1 ATTRIBUTES

=head2 name

The name of the target. Set this to something descriptive so you can figure out what went wrong in the logs!

The default is: type::hostname:port::path

Example: "FTP::foo.com:21::/"

=head2 hostname

The hostname of the target to connect to. Can be a DNS string or ipv4/6 address.

required.

=head2 path

The path on the target to consider our "root" directory.

The default is: /

=for Pod::Coverage add_known_dir

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Apocalypse <APOCAL@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Raudssus Social Software L<http://www.raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

