package Commons::Link;

use strict;
use warnings;

use Class::Utils qw(set_params);
use File::Spec::Functions qw(catfile);
use Digest::MD5 qw(md5_hex);
use Readonly;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

Readonly::Scalar our $BASE_URI => q{http://upload.wikimedia.org/wikipedia/commons/};

our $VERSION = 0.02;

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

	my $url = $BASE_URI.catfile($a, $b, $file);

	return $url;
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

=head1 DEPENDENCIES

L<Class::Utils>,
L<File::Spec::Functions>,
L<Digest::MD5>,
L<Readonly>,
L<Unicode::UTF8>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Commons-Link>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2021

BSD 2-Clause License

=head1 VERSION

0.02

=cut
