package Gtk2::Ex::FileLocator::Helper;
use strict;
no warnings;

use Gtk2;
use Glib qw(TRUE FALSE);
use Gnome2::VFS -init;

use CGI;
use Unicode::MapUTF8;

use base Exporter::;

our @EXPORT = qw(
  image_set_file_icon
  file_open
  string_shell_escape
  string_shell_unescape
  string_shell_complete
);

sub image_set_file_icon {
	my ( $image, $filename, $iconsize ) = @_;

	if ( -e $filename ) {
		my $theme = Gnome2::IconTheme->new();
		my ($icon_name) = $theme->lookup_sync( undef, $filename, undef, "none" );
		my ($icon) = $theme->lookup_icon( $icon_name, $iconsize );

		my $icontheme = Gtk2::IconTheme->get_default;
		my $pixbuf = $icontheme->load_icon( $icon_name, $iconsize, 'force-svg' );

		$image->set_from_pixbuf($pixbuf);
	} else {
		$image->set_from_stock( 'gtk-none', 'small-toolbar' );
	}

	return $image;
}

sub file_open {
	my $filename = shift;

	my ( $result, $info ) = Gnome2::VFS->get_file_info( $filename, 'get-mime-type' );
	if ( $result eq "ok" ) {
		my $mimeType    = Gnome2::VFS::Mime::Type->new( $info->get_mime_type );
		my $application = $mimeType->get_default_application;
		return system sprintf "$application->{command} %s >/dev/null 2>&1 &", string_shell_escape($filename);
	} else {
		#warn "result: $result";
	}

	return;
}

sub string_shell_escape {
	my $string = shift;
	$string =~ s/([\#\'\&\|\s\<\>\{\}\(\)\?\*\!\[\]])/\\$1/sg;
	$string =~ s/([`"])/?/sg;
	return $string;
}

sub string_shell_unescape {
	my $string = shift;
	$string = CGI::unescape($string);
	$string = Unicode::MapUTF8::from_utf8( { -string => $string, -charset => 'ISO-8859-1' } );
	return $string;
}

sub string_shell_complete {
	my $chunk = string_shell_escape(shift);
	my @pattern = map { "$_/$chunk" } "/bin", split ":", $ENV{PATH};

	chdir $ENV{HOME};

	my $match = "";

	foreach my $pattern ( $chunk, @pattern ) {
		if ( -e $pattern ) {
			$match = $pattern;
			goto MATCH;
		}

		#printf "%s\n", $pattern;

		# file match
		foreach (`ls -C1 $pattern* >/dev/null 2>&1`) {
			chomp;
			last if !$_ or $_ eq '.';
			#printf "%s\n", join "\n", $_;
			if ($_) {
				$match = string_shell_unescape($_);
				goto MATCH;
			}
		}

		# directory match
		foreach (`ls -d -C1 $pattern* 2>/dev/null`) {
			chomp;
			s/:$//o;
			if (-e) {
				$match = string_shell_unescape( -d $_ ? "$_/" : $_ );
				goto MATCH;
			}
		}
	}

  MATCH:
	$match = "$ENV{HOME}/$match" if $match and $match !~ m|^/|o;
	$match .= "/" if -d $match;
	$match =~ s|/+|/|sgo;

	return $match || $chunk;
}

1;
__END__

sub string_shell_complete {
	my $pattern = string_shell_escape(shift);

	my @pattern = map { "$_/$pattern" } "/bin", split ":", $ENV{PATH};

	my $match = "";

	foreach my $pattern ( $pattern, @pattern ) {
		if ( -e $pattern ) {
			$match = $pattern;
			goto MATCH;
		}

		#printf "%s\n", $pattern;

		# file match
		foreach (`ls -C1 $pattern* >/dev/null 2>&1`) {
			chomp;
			last if !$_ or $_ eq '.';
			#printf "%s\n", join "\n", $_;
			if ($_) {
				$match = string_shell_unescape($_);
				goto MATCH;
			}
		}

		# directory match
		foreach (`ls -d -C1 $pattern* 2>/dev/null`) {
			chomp;
			s/:$//o;
			if (-e) {
				$match = string_shell_unescape( -d $_ ? "$_/" : $_ );
				goto MATCH;
			}
		}
	}

  MATCH:
	$match = "$ENV{HOME}/$match" unless $match =~ m|^/|o;
	$match .= "/" if -d $match;
	$match =~ s|/+|/|sgo;

	return $match;
}

sub load_icon {
	my $this = shift;

	if ( -e $this->{filename} ) {
		my $theme = Gnome2::IconTheme->new();
		my ($icon_name) = $theme->lookup_sync( undef, $this->{filename}, undef, "none" );
		my ($icon) = $theme->lookup_icon( $icon_name, $this->{iconsize} );

		my $icontheme = Gtk2::IconTheme->get_default;
		my $pixbuf = $icontheme->load_icon( $icon_name, $this->{iconsize}, 'force-svg' );

		$this->{image}->set_from_pixbuf($pixbuf);
	} else {
		$this->{image}->set_from_stock( 'gtk-none', 'small-toolbar' );
	}

	return;
}
