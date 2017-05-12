use strict;

package Copy::From::Git;

use File::Basename;

our $VERSION = 0.0003_02;

sub new {
	my $class = shift;

	my $args = {
		server => 'guthub.com',
		path   => undef, 
		repo   => undef,
		branch => 'master',
		subdir => '.',
		user   => getlogin(),
		@_,
	};

	return bless $args => $class;
}

sub clone {
	my ($self, $target) = @_;

	$target = '/tmp/testing/' unless $target;

	unless( -d $target ){
		my $cmd;
		if( $self->{http} ){
			$cmd = sprintf "git clone -b %s %s%s/%s %s", $self->{branch}, $self->{http}, ${self}->{server}, ${self}->{path}, $target ;
		} else {
			$cmd = sprintf "git clone -b %s %s\@%s:%s/%s %s", $self->{branch}, $self->{user}, ${self}->{server}, ${self}->{path}, ${self}->{repo}, $target ;
		}
		print "Executing: [$cmd]\n";
		system( $cmd );
	} else {
		my $cmd = sprintf "cd %s && git pull", $target;
		print "Executing: [$cmd]\n";
		system( $cmd );
	}

	$self->{target} = $target;

}

sub cleanup {
	my ($self) = @_;

	print "Cleaning up $self->{target}..\n";
	system( "rm -rI $self->{target}" );
}

sub copy {
	my $self = shift;

	my @files = `find $self->{target} -type f`;
	chomp for @files;

	for my $k ( keys %{$self->{files}} ){
		print "Finding [$k]..\n";
		my $target = ${self}->{files}->{"$k"};
		my @f = grep { /$k/ } @files;

		#print "Target: [$target]\n";

		# We need to ensure that the target dir
		# exists for each of these files.
		for ( @f ){
			my ($filename, $directories, $suffix) = fileparse($_);
			#print "$filename => $directories .. ";

			# Check that $directories exists
			$directories =~ s/^$self->{target}//;
			#print "$directories\n";

			`mkdir -p ${target}/${directories}`
				unless -d "${target}/${directories}";

			`cp -v $_ ${target}/${directories}`;
		}
	}
}

sub run {
	my ($self) = @_;
	$self->clone;
	$self->copy;
	$self->cleanup;
}

1;

__END__

=head1 NAME

Copy::From::Git - A small class to pull files from remote git repos into your current space

=head1 SYNOPSIS

  use Copy::From::Git;
  
  Copy::From::Git->new(
          repo => 'zabbix',
          files => { 'agent-probes/.*?\.py$' => 'usr/bin/', },
  )->run;

=head1 METHODS

Only two methods are to be used by this class, the I<new> and I<run> methods.  The I<new> method accepts a number of named parameters to override the defaults provided within the constructor.

=head2 NEW

Within the constructor, the hash reference is initialized as follows:

  my $args = {
  	server => 'guthub.com',
  	path   => '/petermblair/',
  	repo   => undef,
  	branch => 'master',
  	subdir => '.',
  	user   => getlogin(),
  	@_,
  };


The parameters of note:

=over 4

=item server

The server from which we will pull from.

=item path

The path preceding the name of the repository on the server.

=item repo

The name of the git repository

=item branch

An optional branch name to pull

=item subdir

B<deprecated>

=item user

This is inferred from the B<getlogin()> function.  As this module will likely be called within a I<sudo> reference, we want to execute any git over ssh calls as our login username.

=item files

This is a I<HASHREF> in the format of B<regex-location> => B<target path>.  Meaning:

  files => { 'agent-probes/.*?\.py$' => 'usr/bin/', },

will look for all files that match the filename within the regex and place said file into the I<usr/bin> location I<relative> to your current directory.

=back

=head1 AUTHOR

pblair@tucows.com
