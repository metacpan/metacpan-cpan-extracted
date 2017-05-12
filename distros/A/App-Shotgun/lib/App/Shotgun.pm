package App::Shotgun;
BEGIN {
  $App::Shotgun::AUTHORITY = 'cpan:GETTY';
}
BEGIN {
  $App::Shotgun::VERSION = '0.001';
}
use strict;
use warnings;

# ABSTRACT: mass upload of files via SCP/FTP/...

use Moose;
use MooseX::Types::Path::Class;
use Cwd qw( getcwd );
use Path::Class::Dir;

with(
	'MooseX::Getopt' => { -version => '0.37' },
	'MooseX::LogDispatch' => { -version => '1.2002' },
);

# TODO unimplemented stuff

# support getting user/pass from a .netrc file ( use Net::Netrc ? )

## log our transfers to a file somewhere
#has transferlog => (
#	isa => 'Str',
#	is => 'ro',
#	predicate => 'has_transferlog',
#);
#
## enable full parallel uploads to ALL targets at the same time
#has parallel => (
#	isa => 'Bool',
#	is => 'ro',
#	default => 0,
#);
#
## get file list from the source, recursively ( ls -lR basically )
#has filerecursive => (
#	isa => 'Bool',
#	is => 'ro',
#	default => 0,
#);

has source => (
	isa => 'Str',
	is => 'ro',
	default => sub { getcwd },
);

has filelist => (
	isa => 'Str',
	is => 'ro',
	predicate => 'has_filelist',
);

has file => (
	traits  => ['Array'],
	is      => 'ro',
	isa     => 'ArrayRef[Str]',
	predicate => 'has_file',
);

has files => (
	traits  => ['Array'],
	is      => 'ro',
	isa     => 'ArrayRef[Str]',
	default => sub {
		my $self = shift;
		my @files;
		my $ok;
		if ( $self->has_filelist ) {
			$ok = 1;
			open( my $fh, '<', $self->filelist ) or die "Unable to open " . $self->filelist . ": $!";
			while ( my $file = <$fh> ) {
				chomp($file);
				push @files, $file;
			}
			close( $fh ) or die "Unable to close " . $self->filelist . ": $!";
		}
		if ( $self->has_file ) {
			$ok = 1;
			@files = @{$self->file};
		}
		$ok ? \@files : die "no files given";
	},
	handles => {
		next_file => 'shift',
		num_files => 'count',
	},
);

has targets => (
	traits => ['NoGetopt'],
	is      => 'ro',
	isa     => 'ArrayRef[HashRef[Str]]',
	default => sub {
		my $self = shift;
		if ( $self->has_target ) {
			my @targets;
			for (@{$self->target}) {
				my ($type, @other) = split(/:/,$_);
				my %params;
				for (@other) {
					my ($var, @values) = split(/\=/,$_);
					my $value = @values ? join('=',@values) : 1;
					$params{$var} = $value;
				}
				push @targets, {
					type => $type,
					%params,
				};
			}
			return \@targets;
		} else {
			die "no targets given";
		}
	},
);

has target => (
	traits  => ['Array'],
	is      => 'ro',
	isa     => 'ArrayRef[Str]',
	predicate => 'has_target',
);

has connections => (
	traits => ['Array','NoGetopt'],
	isa => 'ArrayRef',
	is => 'ro',
	default => sub { [] },
	init_arg => undef,
	handles => {
		new_connection => 'push',
	},
);

has current_connection => (
	traits => ['NoGetopt'],
	isa => 'Int',
	is => 'rw',
	default => 0,
	init_arg => undef,
);

has current_file => (
	traits => ['NoGetopt'],
	isa => 'Path::Class::File',
	is => 'rw',
	coerce => 1,
	init_arg => undef,
);

has success => (
	traits => ['NoGetopt'],
	isa => 'Bool',
	is => 'rw',
	default => 0,
	init_arg => undef,
);

has error => (
	isa => 'Str',
	is => 'rw',
	init_arg => undef,
);


sub shot {
	my $self = shift;

	$self->_init;

	# fire up the POE kernel
	POE::Kernel->run;

	# All done!
	return;
}


sub shot_poe {
	my $self = shift;

	$self->_init;

	return;
}

sub _init {
	my $self = shift;

	$self->logger->debug( "Starting SHOTGUN" );
	
	# TODO: Checking if there is any [^|/].{1,2}[$|/] in the files

	die "No targets defined" if ! scalar @{ $self->targets };

	# construct all of our connection targets
	foreach my $t ( @{ $self->targets } ) {
		if ( ! exists $t->{'type'} ) {
			die "type missing from target info";
		}

		# convert the path to an absolute path
		if ( exists $t->{'path'} ) {
			$t->{'path'} = Path::Class::Dir->new( $t->{'path'} )->absolute( '/' );
		}

		my $type = delete $t->{'type'};
		eval "use App::Shotgun::Target::$type";
		if ( $@ ) {
			die "Unknown target type: $type - $@";
		} else {
			my $connection = "App::Shotgun::Target::$type"->new( %$t, shotgun => $self );
			$self->new_connection( $connection );
		}
	}
}

sub _error {
	my( $self, $error ) = @_;

	# ignore stacked errors
	return if defined $self->error;

	$self->logger->debug( "ERROR: $error" );
	$self->error( $error . "\n" );

	# Tell all of our targets to shutdown
	foreach my $t ( @{ $self->connections } ) {
		$t->yield( 'shutdown' );
	}

	return;
}

sub _ready {
	my( $self, $target ) = @_;

	# target is ready, set it's state
	# convenience, really - so I don't have to type this in all the targets :)
	$self->logger->debug( "Target [" . $target->name . "] is ready" );
	$target->state( 'ready' );

	# $target is now ready for transfer, are all of our targets ready?
	foreach my $t( @{ $self->connections } ) {
		if ( $t->state ne 'ready' ) {
			return;
		}
	}

	# got here, all of our targets are ready!
	# start the process by transferring the first file!
	$self->current_file( $self->next_file );
	$self->connections->[ $self->current_connection ]->yield( 'transfer' );

	return;
}

sub _xferdone {
	my( $self, $target ) = @_;

	# target finished transferring
	# convenience, really - so I don't have to type this in all the targets :)
	$self->logger->debug( "Target [" . $target->name . "] finished transferring '" . $self->current_file . "'" );
	$target->state( 'ready' );

	# Okay, move on to the next connection
	$self->current_connection( $self->current_connection + 1 );
	if ( ! defined $self->connections->[ $self->current_connection ] ) {
		# finished sending this file to all connections!
		# do we have more files to send?
		if ( $self->num_files ) {
			# process the next file
			$self->current_connection( 0 );
			$self->current_file( $self->next_file );
			$self->connections->[ $self->current_connection ]->yield( 'transfer' );
		} else {
			# SHOTGUN DONE
			$self->success( 1 );

			# Tell all of our targets to shutdown
			foreach my $t ( @{ $self->connections } ) {
				$t->yield( 'shutdown' );
			}
		}
	} else {
		# Tell the next connection to process the file
		$self->connections->[ $self->current_connection ]->yield( 'transfer' );
	}

	return;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;


__END__
=pod

=head1 NAME

App::Shotgun - mass upload of files via SCP/FTP/...

=head1 VERSION

version 0.001

=head1 SYNOPSIS

	use App::Shotgun;

	my $shotgun = App::Shotgun->new(
		source => '../relative/path',
		files => [
			# NEVER NEVER EVER EVER use relative paths here!
			# They should be in the source path
			'robots.txt',
			'dir/dir/dir/file.txt',
			'category/index.html',
			'index.html',
		],
		targets => [
			{
				type => 'FTP',
				name => 'Target 1', # optional
				path => 'htdocs/', # optional
				hostname => 'my.local',
				username => 'notfor',
				password => 'you321',
			},
			{
				type => 'SFTP',
				name => 'Target 2', # optional
				path => '/tmp/testenv', # optional
				hostname => 'myother.local',
				username => 'notfor',

				# prepared key authentifications are just working
				# probably more options for configuring ssh, like alternative private key
			},
		],
	);

	# Order of upload:
	# Target 1: robots.txt
	# Target 2: robots.txt
	# Target 1: dir/dir/dir/file.txt
	# Target 2: dir/dir/dir/file.txt
	# ...

	$shotgun->shot;

	print "Success: ".($shotgun->success ? 'YES' : 'NO')."\n";
	print "Error: ".$shotgun->error if (!$shotgun->success);

	my $other_shotgun = App::Shotgun->new(
		source => '/absolute/path',
		filelist => 'filelist.txt',
	);

=head1 DESCRIPTION

This module uploads the filelist textfile given via B<filelist> or the filelist given as array via B<files> to all given B<targets>.
It uploads file after file, to target after target, that means, first file will get uploaded to all target, and if they all are
successful done, the next file will be uploaded. This module doesn't do any "smart" things like compare filesize/modification time/etc and
just uploads the files. Hence the name "shotgun" which is appropriate :)

For first the module is made to try again very often but will not continue on fail and close with an exit code above 0.

Please look at the appropriate C<App::Shotgun::Target::*> classes for their attributes and how to use them.

=head1 METHODS

=head2 shot

The main entry point of this module.

Returns nothing.

=head2 shot_poe

Use this method if you are embedding this module in a bigger POE-based program. The only difference with L</shot> is that
this method will not run the POE kernel, leaving it to the caller to do so.

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

