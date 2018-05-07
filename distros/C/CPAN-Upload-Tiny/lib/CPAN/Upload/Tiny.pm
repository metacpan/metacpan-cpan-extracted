package CPAN::Upload::Tiny;
$CPAN::Upload::Tiny::VERSION = '0.008';
use strict;
use warnings;

use Carp ();
use File::Basename ();
use MIME::Base64 ();
use HTTP::Tiny;
use HTTP::Tiny::Multipart;

my $UPLOAD_URI = $ENV{CPAN_UPLOADER_UPLOAD_URI} || 'https://pause.perl.org/pause/authenquery?ACTION=add_uri';

sub new {
	my ($class, $user, $password) = @_;
	return bless {
		user     => $user,
		password => $password,
	}, $class;
}

sub new_from_config {
	my ($class, $filename) = @_;
	my $config = read_config_file($filename);
	bless $config, $class;
}

sub upload_file {
	my ($self, $filename) = @_;

	open my $fh, '<:raw', $filename or die "Could not open $filename: $!";
	my $content = do { local $/; <$fh> };

	my $tiny = HTTP::Tiny->new(verify_SSL => 1);

	my $auth = 'Basic ' . MIME::Base64::encode("$self->{user}:$self->{password}", '');

	my $result = $tiny->post_multipart($UPLOAD_URI, {
		HIDDENNAME                        => $self->{user},
		CAN_MULTIPART                     => 1,
		pause99_add_uri_httpupload        => {
			filename     => File::Basename::basename($filename),
			content      => $content,
			content_type => 'application/gzip',
		},
		pause99_add_uri_uri               => '',
		SUBMIT_pause99_add_uri_httpupload => ' Upload this file from my disk ',
	}, { headers => { Authorization => $auth } });

	if (!$result->{success}) {
		my $key = $result->{status} == 599 ? 'content' : 'reason';
		die "Upload failed: $result->{$key}\n";
	}

	return;
}

sub read_config_file {
	my $filename = shift || glob('~/.pause');
	die 'Missing configuration file' unless -r $filename;

	my %conf;
	if ( eval { require Config::Identity } ) {
		%conf = Config::Identity->load($filename);
		$conf{user} = delete $conf{username} unless $conf{user};
	}
	else { # Process .pause manually
		open my $pauserc, '<', $filename or die "can't open $filename for reading: $!";

		while (<$pauserc>) {
			chomp;
			Carp::croak "$filename seems to be encrypted. Maybe you need to install Config::Identity?" if /BEGIN PGP MESSAGE/;

			next if not length or $_ =~ /^\s*#/;

			if (my ($k, $v) = / ^ \s* (user|password) \s+ (.+?) \s* $ /x) {
				Carp::croak "Multiple entries for $k" if $conf{$k};
				$conf{$k} = $v;
			}
		}
	}
	Carp::croak('No user set in configuration file')     if not $conf{user};
	Carp::croak('No password set in configuration file') if not $conf{password};

	return \%conf;
}

1;

#ABSTRACT: A tiny CPAN uploader

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Upload::Tiny - A tiny CPAN uploader

=head1 VERSION

version 0.008

=head1 SYNOPSIS

 use CPAN::Upload::Tiny;
 my $upload = CPAN::Upload::Tiny->new_from_config($optional_file);
 $upload->upload_file($filename);

=head1 DESCRIPTION

This is a light-weight module for uploading files to CPAN.

=head1 METHODS

=head2 new($username, $password)

This creates a new C<CPAN::Upload::Tiny> object. It requires a C<$username> and a C<$password>.

=head2 new_from_config($filename)

This creates a new C<CPAN::Upload::Tiny> based on a F<.pause> configuration file. It will use C<Config::Identity> if available.

=head2 upload_file($filename)

This uploads the given file to PAUSE/CPAN.

=head1 SEE ALSO

=over 4

=item * L<CPAN::Uploader|CPAN::Uploader>

A heavier but more featureful CPAN uploader

=item * L<Config::Identity|Config::Identity>

This allows you to encrypt your configuration file.

=back

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
