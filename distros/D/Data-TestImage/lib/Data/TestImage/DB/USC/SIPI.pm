package Data::TestImage::DB::USC::SIPI;
# ABSTRACT: provides access to the USC SIPI test image database
$Data::TestImage::DB::USC::SIPI::VERSION = '0.007';
use strict;
use warnings;
use Data::TestImage;
use Path::Class;
use Try::Tiny;
use List::AllUtils qw(first);
use v5.14;

use parent qw(Data::TestImage::DB);

use constant ARCHIVE_TYPE => 'tgz';
# from <http://sipi.usc.edu/database/>.
# Text is from the catalog <http://sipi.usc.edu/database/SIPI_Database.pdf>.
use constant IMAGE_DB_VOLUME => {
	textures => {
			volume => 1,
			dir => 'textures',
			description => 'Brodatz textures, texture mosaics, etc.',
			description_longer =>
q{For the Brodatz texture images, the number in parenthesis (i.e. D12) is the
page number in the Brodatz texture book that the image came from (P. Brodatz,
Textures: A Photographic Album for Artists and Designers, Dover Publications,
New York, 1966). Images 1.2.01 through 1.2.13 (marked below with a ‘∗’) are
histogram equalized versions of 1.1.01 through 1.1.13.

The texture mosaics (texmos1, texmos2, and texmos3) are mosaics of eight Brodatz textures for use in
image texture segmentation research. The files texmos2.s512 and texmos3.s512 are images containing eight
gray levels which indicate which of the eight textures are present at each point in the corresponding texture
mosaic. A document containing a more detailed description of the texture mosaics is available on the SIPI
web site <http://sipi.usc.edu/database/USCTextureMosaics.pdf>.},
			url => 'http://sipi.usc.edu/database/textures.tar.gz',
			alt_urls => [ 'https://github.com/EntropyOrg-data/usc-sipi-image-database-backup/blob/master/textures.tar.gz?raw=true' ],
		},
	aerials => {
			volume => 2,
			dir => 'aerials',
			description => 'High altitude aerial images',
			url => 'http://sipi.usc.edu/database/aerials.tar.gz',
			alt_urls => [ 'https://github.com/EntropyOrg-data/usc-sipi-image-database-backup/blob/master/aerials.tar.gz?raw=true' ],
		},
	miscellaneous => {
			volume => 3,
			dir => 'misc',
			description => 'Lena, the mandrill, and other favorites',
			url => 'http://sipi.usc.edu/database/misc.tar.gz',
			alt_urls => [ 'https://github.com/EntropyOrg-data/usc-sipi-image-database-backup/blob/master/misc.tar.gz?raw=true' ],
		},
	sequences => {
			volume => 4,
			dir => 'sequences',
			description => 'Moving head, fly-overs, moving vehicles',
			description_longer =>
q{Each of the sequences consist of multiple images showing motion of the subject matter. The image filenames
consist of the name shown below followed by the number in the sequence (e.g. 6.1.01, 6.1.02, etc.)

Sequence 6.2 consists of 32 images but only the first 16 appear to be a true motion sequence. Images
17 through 32 show some motion but not in any clear direction. They are included in the database only
because they have been part of it for several years.},
			url => 'http://sipi.usc.edu/database/sequences.tar.gz',
			alt_urls => [ 'https://github.com/EntropyOrg-data/usc-sipi-image-database-backup/blob/master/sequences.tar.gz?raw=true' ],
		},
};

sub get_db_dir {
	Data::TestImage->get_dist_dir()->subdir(qw{ USC SIPI });
}

sub _get_volume_dir {
	my ($self, $volume) = @_;
	$self->_valid_volume( $volume );
	$self->get_db_dir->subdir( IMAGE_DB_VOLUME()->{$volume}{dir} );
}

sub installed_volumes {
	my ($self) = @_;
	[ grep { -d $self->_get_volume_dir($_) } keys %{ IMAGE_DB_VOLUME() } ];
}

sub _valid_volume {
	my ($self, $volume) = @_;
	die "$volume does not exist" unless exists IMAGE_DB_VOLUME->{$volume};
}

sub install_package {
	my ($self, $args, %opts) = @_;
	require HTTP::Tiny;
	require Archive::Extract;
	require File::Temp;
	no warnings 'exiting'; # for the next/last URL
	my @volumes = split ',', $args;

	# if :all is the name used, then just download all known volumes
	@volumes = keys %{ IMAGE_DB_VOLUME() } if grep { $_ eq ":all" } @volumes;

	for my $volume (@volumes) {
		$self->_valid_volume( $volume );

		# get all URLs to try
		my @volume_urls = ( IMAGE_DB_VOLUME->{$volume}{url}, @{ IMAGE_DB_VOLUME->{$volume}{alt_urls} } );

		my $response;
		URL: for my $url (@volume_urls) {
			print "Downloading $url...\n" if $opts{verbose};
			# try each one until you get a response
			try {
				$response = HTTP::Tiny->new->get($url);
				die "Failed to download $volume @ $url\n" unless $response->{success};

				# save the response to temp file
				my $temp_fh = File::Temp->new;
				file($temp_fh->filename)->spew(
					$response->{content} );

				# extract to appropriate directory
				print "Extracting $volume...\n" if $opts{verbose};
				my $ae = Archive::Extract->new(
					archive => $temp_fh->filename,
					type => ARCHIVE_TYPE );
				$ae->extract( to => $self->get_db_dir );

				last URL; # done with this URL
			} catch {
				next URL; # something went wrong...try alternatives
			};
		}
	}
}

sub get_installed_images {
	my ($self) = @_;
	[ grep { $_->basename ne 'data.yml' } @{$self->SUPER::get_installed_images()} ];
}

sub get_all_images {
	my ($self) = @_;
	my $top = $self->get_db_dir;
	[ map { $top->file( split('/', $_) ) } keys %{ $self->get_metadata } ];
}

sub get_metadata {
	my ($self) = @_;
	require YAML::Tiny;
	state $data = YAML::Tiny::LoadFile( $self->get_db_dir->file('data.yml') );
	$data;
}

sub get_image {
	my ($self, $image) = @_;
	my $image_file = $self->SUPER::get_image($image);
	return $image_file if $image_file;
	# otherwise
	my $data = $self->get_metadata;
	first {
		my $relative_path = $_->relative( $self->get_db_dir )->stringify;
		$data->{$relative_path}{description}  =~ /\Q$image\E/i
	} @{ $self->get_installed_images };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TestImage::DB::USC::SIPI - provides access to the USC SIPI test image database

=head1 VERSION

version 0.007

=head1 SYNOPSIS

    use Data::TestImage::DB::USC::SIPI;

    # two different ways of referring to the same image
    my @mandrill_images = map {
        Data::TestImage::DB::USC::SIPI->get_image($_)
    } qw(4.2.03 mandrill);
    say join " & ", map { $_->basename } @mandrill_images;
    # 4.2.03.tiff & 4.2.03.tiff

Produces the L<mandrill|http://EntropyOrg.github.io/p5-Data-TestImage/USC/SIPI/mandrill.png> image.

=for html <div><img width="200" alt="Mandrill image" src="http://EntropyOrg.github.io/p5-Data-TestImage/USC/SIPI/mandrill.png"/></div>

=head1 INHERITANCE

=over 4

=item L<Data::TestImage::DB>

=back

=head1 DESCRIPTION

This module installs and provides metadata for the USC SIPI image database.
This database is made up of 4 volumes: textures, aerials, miscellaneous, and
sequences. By default, only the miscellaneous volume is installed.

=head1 METHODS

=head2 IMAGE_DB_VOLUME

    IMAGE_DB_VOLUME()

Returns a hash containing information about each of the volumes in the image database.

=head2 installed_volumes

    installed_volumes()

Returns an arrayref of strings indicating which volumes are installed.

=head2 get_metadata

    get_metadata()

Returns a hashref of metadata about all images in the database (even those not
installed).  This data includes the size, a textual description, and whether
the image is 24 bpp color or 8 bpp monochrome.

=head2 get_image

    get_image($image_name)

Overrides L<Data::TestImage::DB/get_image> to provide the default lookup by
filename first and then if the image is not found, search the metadata text.

=head1 INSTALLATION

As discussed in L<Data::TestImage|Data::TestImage/INSTALLATION>, installing
further volumes can be done by setting the C<PERL_DATA_TESTIMAGE_INSTALL>
environment variable. The syntax for installing each volume is

    USC::SIPI=<volume>,<volume>,<volume>,...

where C<<volume>> is one of the volume names as listed in L</DESCRIPTION>.

A shortcut for installing all volumes in the database is to use C<:all> as the
volume name, that is, set the environment variable to

    USC::SIPI=:all

and then install the distribution.

=head1 COPYRIGHT INFORMATION

The images in this database are not licensed for commercial use. For more
information, see the database website.

The textual descriptions returned by L</IMAGE_DB_VOLUME> and L</get_metadata>
are taken from the database catalog.

=head1 SEE ALSO

L<USC SIPI database|http://sipi.usc.edu/database/>,
L<database catalog|http://sipi.usc.edu/database/SIPI_Database.pdf>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
