package Commons::Link;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Digest::MD5 qw(md5_hex);
use File::Basename;
use Readonly;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);
use URI;

Readonly::Scalar our $UPLOAD_URI => q{http://upload.wikimedia.org};
Readonly::Scalar our $COMMONS_URI => q{https://commons.wikimedia.org};
Readonly::Array our @UPLOAD_SEGS => qw(wikipedia commons);
Readonly::Array our @COMMONS_SEGS => qw(wiki);

our $VERSION = 0.06;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# UTF-8 mode.
	$self->{'utf-8'} = 1;

	# Process parameters.
	set_params($self, @params);

	return $self;
}

sub link {
	my ($self, $file) = @_;

	$self->_cleanup(\$file);
	
	# Digest characters.
	my ($a, $b) = $self->_compute_ab($file);

	my $u = URI->new($UPLOAD_URI);
	$u->path_segments(@UPLOAD_SEGS, $a, $b, $file);

	return $u->as_string;
}

sub mw_file_link {
	my ($self, $file) = @_;

	if ($file !~ m/^(File|Image):/ms) {
		$file = 'File:'.$file;
	}

	return $self->mw_link($file);
}

sub mw_link {
	my ($self, $file) = @_;

	my $u = URI->new($COMMONS_URI);
	$u->path_segments(@COMMONS_SEGS, $file);

	return $u->as_string;
}

sub mw_user_link {
	my ($self, $user) = @_;

	if ($user !~ m/^User:/ms) {
		$user = 'User:'.$user;
	}

	return $self->mw_link($user);
}

sub thumb_link {
	my ($self, $file, $width) = @_;

	$self->_cleanup(\$file);

	# Digest characters.
	my ($a, $b) = $self->_compute_ab($file);

	my $thumb_file = $file;
	my ($name, undef, $suffix) = fileparse($file, qr/\.[^.]*/ms);
	if ($suffix eq '.svg') {
		$suffix = '.png';
		$thumb_file = $name.$suffix;
	}

	my $u = URI->new($UPLOAD_URI);
	$u->path_segments(@UPLOAD_SEGS, 'thumb', $a, $b, $file,
		$width.'px-'.$thumb_file);

	return $u->as_string;
}

sub _cleanup {
	my ($self, $file_sr) = @_;

	# Rewrite all spaces to '_'.
	${$file_sr} =~ s/ /_/g;

	# Remove 'File:' or 'Image:' prefixes.
	${$file_sr} =~ s/^(File|Image)://ig;

	# Upper case
	${$file_sr} =~ s/^(\w)/uc($1)/e;

	return;
}

sub _compute_ab {
	my ($self, $file) = @_;

	# MD5 only on bytes not utf8 chars.
	my $digest;
	if ($self->{'utf-8'}) {
		my $tmp = encode_utf8($file);
		$digest = lc(md5_hex($tmp));
	} else {
		$digest = lc(md5_hex($file));
	}

	my $a = substr $digest, 0, 1;
	my $b = substr $digest, 0, 2;

	return ($a, $b);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Commons::Link - Object for creating link for Wikimedia Commons.

=head1 SYNOPSIS

 use Commons::Link;

 my $obj = Commons::Link->new(%params);
 my $link = $obj->link($file);
 my $mw_file_link = $obj->mw_file_link($file);
 my $mw_link = $obj->mw_link($object);
 my $mw_user_link = $obj->mw_user_link($user);
 my $thumb_link = $obj->thumb_link($file, $width_in_pixels);

=head1 METHODS

=head2 C<new>

 my $obj = Commons::Link->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<utf-8>

UTF-8 mode.
In UTF-8 mode input string will be encoded to bytes and compute md5 hash.

Default value is 1.

=back

=head2 C<link>

 my $link = $obj->link($file);

Get URL from Wikimedia Commons computed from file name.
File name could be with 'Image:' and 'File:' prefix or directly file.
Spaces are translated to '_'.

Returns string with URL.

=head2 C<mw_file_link>

 my $mw_file_link = $obj->mw_file_link($file);

Get URL from Wikimedia Commons MediaWiki view page defined by file name.
File name could be with 'Image:' and 'File:' prefix or directly file.

Returns string with URL.

=head2 C<mw_link>

 my $mw_link = $obj->mw_link($object);

Get URL from Wikimedia Commons MediaWiki view page defined by object name.
e.g. File:__FILENAME__, User:__USERNAME__, Category:__CATEGORY__

Returns string with URL.

=head2 C<mw_user_link>

 my $mw_user_link = $obj->mw_user_link($user);

Get URL from Wikimedia Commons MediaWiki view page defined by user name.
File name could be with 'User:' prefix or directly file.

Returns string with URL.

=head2 C<thumb_link>

 my $thumb_link = $obj->thumb_link($file, $width_in_pixels);

Get URL from Wikimedia Commons computed from file name and image width in pixels.
File name could be with 'Image:' and 'File:' prefix or directly file.
Spaces are translated to '_'.

Returns string with URL.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Commons::Link;

 # Object.
 my $obj = Commons::Link->new;

 # Input name.
 my $commons_file = 'Michal from Czechia.jpg';

 # URL to file.
 my $commons_url = $obj->link($commons_file);

 # Print out.
 print 'Input file: '.$commons_file."\n";
 print 'Output link: '.$commons_url."\n";

 # Output:
 # Input file: Michal from Czechia.jpg
 # Output link: http://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Commons::Link;

 # Object.
 my $obj = Commons::Link->new;

 # Input name.
 my $commons_file = 'File:Michal from Czechia.jpg';

 # URL to file.
 my $commons_url = $obj->link($commons_file);

 # Print out.
 print 'Input file: '.$commons_file."\n";
 print 'Output link: '.$commons_url."\n";

 # Output:
 # Input file: File:Michal from Czechia.jpg
 # Output link: http://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg

=head1 EXAMPLE3

 use strict;
 use warnings;

 use Commons::Link;

 # Object.
 my $obj = Commons::Link->new;

 # Input name.
 my $commons_file = 'File:Michal from Czechia.jpg';

 # URL to thumbnail file.
 my $commons_url = $obj->thumb_link($commons_file, 200);

 # Print out.
 print 'Input file: '.$commons_file."\n";
 print 'Output thumbnail link: '.$commons_url."\n";

 # Output:
 # Input file: File:Michal from Czechia.jpg
 # Output thumbnail link: http://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Michal_from_Czechia.jpg/200px-Michal_from_Czechia.jpg

=head1 DEPENDENCIES

L<Class::Utils>,
L<Digest::MD5>,
L<Readonly>,
L<Unicode::UTF8>,
L<URI>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Commons-Link>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2021

BSD 2-Clause License

=head1 VERSION

0.06

=cut
