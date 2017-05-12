package Conan::Deploy;

use Carp;
use File::Rsync;

sub __config {
	my @config_files = glob '/etc/conan.cfg ~/.conanrc';

	my %config_options;

	for( @config_files ){
		next unless -f $_;
		print "D: Parsing [$_]\n" if -f $_;

		my $fd;
		open $fd, "<$_";

		next unless $fd;

		my @lines = <$fd>;
		chomp for @lines;

		s/#.*// for @lines;

		@lines = grep { /^\S/ } @lines;

		my %r = map { ($1,$2) if /^(\S+)=(\S+)/ } @lines;

		for ( keys %r ){
			$config_options{"$_"} = $r{"$_"};
		}
	}
	return %config_options;
}

sub new {
	my $class = shift;

	my %config_options = __config @_;

	my $args = {
		%config_options,
		@_,
	};

	return bless $args => $class;
}

# Call for the "promot image" call
sub promote_image {
	my $self = shift;
	my $image = shift;
	my $orig_image = $image;

	unless( defined $self->{srcimagebase} ){
		croak "Must supply a srcimagebase to the Conan::Deploy constructor";
	}

	unless( -d "$self->{srcimagebase}" ){
		croak "$self->{srcimagebase} doesn't exist";
	}

	unless( $self->{targetimagebase} ){
		croak "Must supply a targetimagebase to the Conan::Deploy constructor";
	}

	
	unless( -d "$self->{targetimagebase}" ){
		croak "$self->{targetimagebase} doesn't exist";
	}

	# Check if the source image has a / in it
	unless( $image =~ /\// ){
		$image = $self->{srcimagebase} . "/" . $image;
	}

	unless( -d $image || -f $image ){
		croak "$image doesn't exist";
	}

	printf "D: Copying [%s] to [%s]\n", $image, $self->{targetimagebase};

	my $obj = File::Rsync->new( { archive => 1, compress => 1 } );

	$obj->exec( { src => $image, dest => $self->{targetimagebase} } ) or croak "rsync failed";

	$self->md5( $orig_image );
}

sub md5 {
	my $self = shift;
	my $image = shift;

	sub md5dir {
		my ($base, $image) = @_;

		my $cmd = 'find ' . $base . "/" . $image . " -type f | xargs md5sum";
		print "D: Running [$cmd]\n";

		open $fd, "$cmd |";

		my @lines = <$fd>;

		close $fd;

		chomp for @lines;

		use Data::Dumper;

		s/\s+$base\// / for @lines;
		s/\s+$image/ / for @lines;

		my %r = map { ($2,$1) if /^(\S+)\s+(\S+)/ } @lines;
		return %r;
	}

	my %t = md5dir( $self->{targetimagebase}, $image );
	my %s = md5dir( $self->{srcimagebase}, $image );

	for my $file ( keys %s ){
		# Check that the md5s match
		croak "Mismatch between target and source on [$file]"
			if( $t{"$file"} ne $s{"$file"} );
	}

	return 1;
}

1;

__END__

=head1 NAME

Conan::Deploy - A package for deploying images using the I<Conan> deployment system.

=head1 SYNOPSIS

  use Conan::Deploy;
  my $d = Conan::Deploy->new(
          srcimagebase => '/tmp/base/qa',
          targetimagebase => '/tmp/base/prod',
  );

  $d->promote_image( 'foo-0.1' );

This will look for the directory I<foo-0.1> within the I</tmp/base/qa> base
directory and copy it into the I</tmp/base/prod> directory via rsync.  A
checksum is made on the entire file contents of both directories to ensure that
the integrity of the copy was maintained.

=head1 DESCRIPTION

=head2 USAGE

=over 4

=item new

The I<new> method accepts a series of configuration overrides.  If left without
the given overrides, the I<new> method calls the I<__config> function to parse
the config files for default variable initialization.

=item promote_image

This method is responsible for copying the source image directory to the target
space and subsequently executing an md5 checksum on the entirety of the file
structure to ensure that the copy was successful.

=item md5

This is called by the I<promote_image> method and recursively checks both the
source and target directories to ensure that each file was copied properly.  It
can also be used later to ensure the file integrity of the directory structure,
to detect if an image has been altered.

=item __config

This function is not a method of the class, but is called by the I<new> method
to fulfil the default configuration settings during instance initialization.

This function searches the C</etc/conan.cfg> and C<~/.conanrc> files, looking
for regexes that satisfy the C<(\S+?)=(\S+)> pattern, setting the key/val pairs
from each line.

=back
