package CPANPLUS::Dist::Gentoo::Maps;

use strict;
use warnings;

use File::Spec;
use POSIX ();

=head1 NAME

CPANPLUS::Dist::Gentoo::Maps - Map CPAN distribution names, version numbers and license identifiers to their Gentoo counterparts.

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';

=head1 DESCRIPTION

This is an helper package to L<CPANPLUS::Dist::Gentoo>.

=cut

my %name_mismatch;

/^\s*([\w-]+)\s+([\w-]+)\s*$/ and $name_mismatch{$1} = $2 while <DATA>;

close DATA;

=head1 FUNCTIONS

=head2 C<name_c2g $name>

Maps a CPAN distribution name to the corresponding Gentoo package name.

=cut

sub name_c2g {
 my ($name) = @_;
 return $name_mismatch{$name} || $name;
}

=head2 C<license_c2g @licenses>

Maps F<META.yml> C<license> tag values to the corresponding list of Gentoo license identifiers.
Duplicates are stripped off.

The included data was gathered from L<Module::Install> and L<Software::License>.

=cut

my %licenses = (
 apache     => [ 'Apache-2.0' ],
 artistic   => [ 'Artistic' ],
 artistic_2 => [ 'Artistic-2' ],
 bsd        => [ 'BSD' ],
 gpl        => [ 'GPL-1' ],
 gpl2       => [ 'GPL-2' ],
 gpl3       => [ 'GPL-3' ],
 lgpl       => [ 'LGPL-2.1' ],
 lgpl2      => [ 'LGPL-2.1' ],
 lgpl3      => [ 'LGPL-3' ],
 mit        => [ 'MIT' ],
 mozilla    => [ 'MPL-1.1' ],
 perl       => [ 'Artistic', 'GPL-2' ],
);

sub license_c2g {
 my %seen;

 grep !$seen{$_}++,
  map @{$licenses{+lc} || []},
   grep defined,
    @_;
}

=head2 C<version_c2g $name, $version>

Converts the C<$version> of a CPAN distribution C<$name> to a Gentoo version number.

=cut

my $default_mapping = sub {
 my ($version, @no_strip) = @_;

 my $is_dev = $version =~ /_/;
 my $has_v  = $version =~ s/^v//;

 for ($version) {
  y/_-//d;
  s/^\.*//;
  s/\.*\z//;
  s/\.+/./g;
 }

 my $dots   = $version =~ y/\.//;

 my @parts;
 if ($has_v or $dots >= 2) {
  @parts = split /\./, $version;
 } else {
  ($parts[0], my $subversion) = split /\./, $version, 2;
  $subversion = '0' unless defined $subversion;
  my $sublen = length $subversion;
  if ($sublen < 6) {
   $subversion .= '0' x (6 - $sublen);
  } else {
   my $pad = $sublen % 3;
   $subversion .= '0' x (3 - $pad) if $pad;
  }
  push @parts, $subversion =~ /(...)/g;
 }

 for my $i (0 .. $#parts) {
  next if $no_strip[$i];
  $parts[$i] =~ s/^0+([^0]|0\z)/$1/;
 }
 $version  = join '.', @parts;

 $version .= '_rc' if $is_dev;

 return $version;
};

my $default_but_ignore_v = sub {
 my ($version) = @_;

 $version =~ s/^v//;

 return $default_mapping->($version);
};

my $default_but_no_strip_1 = sub {
 return $default_mapping->($_[0], 0, 1);
};

my $default_but_no_strip_2 = sub {
 return $default_mapping->($_[0], 0, 1, 1);
};

my $insert_dot_every = sub {
 my ($version, $step) = @_;

 my $is_dev = $version =~ /_/;

 for ($version) {
  s/^v//;
  y/_-//d;
  s/^\.*//;
  s/\.*\z//;
  s/\.+/./g;
 }

 my @parts;
 ($parts[0], my $subversion) = split /\./, $version, 2;
 $subversion =~ s/\.//g;
 my $pat = sprintf '.{1,%d}', $step || 1;
 push @parts, $subversion =~ /($pat)/g;

 s/^0+([^0]|0\z)/$1/ for @parts;
 $version = join '.', @parts;

 $version .= '_rc' if $is_dev;

 return $version;
};

my $simple_cleanup = sub {
 my ($version) = @_;

 my $is_dev = $version =~ /_/;

 for ($version) {
  s/^v//;
  y/_-//d;
  s/^\.*//;
  s/\.*\z//;
  s/\.+/./g;
 }

 $version .= '_rc' if $is_dev;

 return $version;
};

my $simple_and_correct_suffixes = sub {
 my ($version) = @_;

 $version = $simple_cleanup->($version);
 $version =~ s/(?<!_)((?:alpha|beta|pre|rc|p)\d*)\b/_$1/g;

 return $version;
};

my $simple_and_strip_letters = sub {
 my ($version) = @_;

 $version = $simple_cleanup->($version);
 $version =~ s/(?<=\d)[a-z]+//g;

 return $version;
};

my $simple_and_letters_as_suffix = sub {
 my ($version) = @_;

 $version = $simple_cleanup->($version);
 $version =~ s/(?<=\d)b(?=\d)/_beta/g;

 return $version;
};

my %version_mismatch;

$version_mismatch{$_} = $default_but_ignore_v for qw<
 Net-DNS-Resolver-Programmable
>;

$version_mismatch{$_} = $default_but_no_strip_1 for qw<
 Crypt-RC4
 File-Grep
 MogileFS-Client-Async
 MogileFS-Network
>;

$version_mismatch{$_} = $default_but_no_strip_2 for qw<
 Net-IMAP-Simple
>;

$version_mismatch{$_} = sub { $insert_dot_every->($_[0], 1) } for qw<
 HTTP-Cookies
 HTTP-Negotiate
>;

$version_mismatch{$_} = sub { $insert_dot_every->($_[0], 3) } for qw<
 POE-Component-IKC
>;

$version_mismatch{$_} = $simple_cleanup for qw<
 Alien-SDL
 CGI-SpeedyCGI
 Class-ISA
 Data-Uniqid
 ExtUtils-Install
 File-Path
 Getopt-GUI-Long
 Gtk2-Notify
 HTML-Table
 I18N-LangTags
 IO
 IPC-System-Simple
 Lab-Measurement
 Log-TraceMessages
 MusicBrainz-DiscID
 Net-IRC
 Net-Ping
 SDL
 SOAP-WSDL
 TeX-Encode
 Tie-Simple
 Time-Piece
 WattsUp-Daemon
>;

$version_mismatch{$_} = $simple_and_correct_suffixes for qw<
 Gimp
 XML-Grove
>;

$version_mismatch{$_} = $simple_and_strip_letters for qw<
 DelimMatch
 SGMLSpm
>;

$version_mismatch{$_} = $simple_and_letters_as_suffix for qw<
 Frontier-RPC
>;

sub version_c2g {
 my ($n, $v) = @_;

 return unless defined $v;

 my $handler;
 $handler = $version_mismatch{$n} if defined $n;
 $handler = $default_mapping  unless defined $handler;

 return $handler->($v);
}

=head2 C<perl_version_c2g $version>

Converts a perl version number as you can find it in CPAN prerequisites to a Gentoo version number.

=cut

sub perl_version_c2g {
 my ($v) = @_;

 return unless defined $v and $v =~ /^[0-9\.]+$/;

 my @parts;
 if (my ($version, $subversion) = $v =~ /^([0-9]+)\.(0[^\.]+)$/) {
  my $len = length $subversion;
  if (my $pad = $len % 3) {
   $subversion .= '0' x (3 - $pad);
  }
  @parts = ($version, $subversion =~ /(.{1,3})/g);
 } else {
  @parts = split /\./, $v;
 }

 return join '.', map int, @parts;
}

=head2 C<get_portage_timestamp $portage>

Get the numerical timestamp associated with the portage tree located at C<$portage>.
Requires L<POSIX::strptime>, and returns C<undef> if it is not available.

=cut

sub get_portage_timestamp {
 my ($portage) = @_;

 {
  local $@;
  eval { require POSIX::strptime } or return;
 }

 my $file = File::Spec->catfile($portage, 'metadata', 'timestamp.chk');
 return unless -e $file;

 my $timestamp = do {
  open my $fh, '<', $file or return;
  local $/;
  <$fh>;
 };
 s/^\s*//, s/\s*$// for $timestamp;

 my $shift = 0;
 if ($timestamp =~ s/\s+([+-])([0-9]{2})([0-9]{2})$//) {
  $shift = ($2 * 60 + $3) * 60;
  $shift = -$shift if $1 eq '-';
 }

 my $old_lc_all = POSIX::setlocale(POSIX::LC_ALL());
 POSIX::setlocale(POSIX::LC_ALL(), 'C');
 $timestamp = POSIX::mktime(
  POSIX::strptime($timestamp, '%a, %d %b %Y %H:%M:%S')
 );
 POSIX::setlocale(POSIX::LC_ALL(), $old_lc_all);
 $timestamp += $shift;

 return $timestamp;
}

=head2 C<TIMESTAMP>

Numerical timestamp associated with the revision of the portage tree that was used for generating the corrections to the natural cpan-to-gentoo mapping listed in this module.

=cut

sub TIMESTAMP () { 1339737301 }

=head1 SEE ALSO

L<CPANPLUS::Dist::Gentoo>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-cpanplus-dist-gentoo at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPANPLUS-Dist-Gentoo>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CPANPLUS::Dist::Gentoo

=head1 COPYRIGHT & LICENSE

Copyright 2009,2010,2011,2012 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of CPANPLUS::Dist::Gentoo::Maps

__DATA__
AcePerl                 Ace
CGI-Simple              Cgi-Simple
CGI-SpeedyCGI           SpeedyCGI
CPAN-Mini-Phalanx100    CPAN-Mini-Phalanx
Cache-Mmap              cache-mmap
Class-Loader            class-loader
Class-ReturnValue       class-returnvalue
Config-General          config-general
Convert-ASCII-Armour    convert-ascii-armour
Convert-PEM             convert-pem
Crypt-CBC               crypt-cbc
Crypt-DES_EDE3          crypt-des-ede3
Crypt-DH                crypt-dh
Crypt-DSA               crypt-dsa
Crypt-IDEA              crypt-idea
Crypt-Primes            crypt-primes
Crypt-RSA               crypt-rsa
Crypt-Random            crypt-random
DBIx-SearchBuilder      dbix-searchbuilder
Data-Buffer             data-buffer
Date-Manip              DateManip
Digest                  digest-base
Digest-BubbleBabble     digest-bubblebabble
Digest-MD2              digest-md2
ExtUtils-Depends        extutils-depends
ExtUtils-PkgConfig      extutils-pkgconfig
Frontier-RPC            frontier-rpc
Gimp                    gimp-perl
Glib                    glib-perl
Gnome2                  gnome2-perl
Gnome2-Canvas           gnome2-canvas
Gnome2-GConf            gnome2-gconf
Gnome2-VFS              gnome2-vfs-perl
Gnome2-Wnck             gnome2-wnck
Gtk2                    gtk2-perl
Gtk2-Ex-FormFactory     gtk2-ex-formfactory
Gtk2-GladeXML           gtk2-gladexml
Gtk2-Spell              gtk2-spell
Gtk2-TrayIcon           gtk2-trayicon
Gtk2-TrayManager        gtk2-traymanager
Gtk2Fu                  gtk2-fu
I18N-LangTags           i18n-langtags
Image-Info              ImageInfo
Image-Size              ImageSize
Inline-Files            inline-files
Locale-Maketext         locale-maketext
Locale-Maketext-Fuzzy   locale-maketext-fuzzy
Locale-Maketext-Lexicon locale-maketext-lexicon
Log-Dispatch            log-dispatch
Math-Pari               math-pari
Module-Info             module-info
MogileFS-Server         mogilefs-server
NTLM                    Authen-NTLM
Net-Ping                net-ping
Net-SFTP                net-sftp
Net-SSH-Perl            net-ssh-perl
Net-Server              net-server
OLE-Storage_Lite        OLE-StorageLite
Ogg-Vorbis-Header       ogg-vorbis-header
PathTools               File-Spec
Perl-Tidy               perltidy
Pod-Parser              PodParser
Regexp-Common           regexp-common
Set-Scalar              set-scalar
String-CRC32            string-crc32
Template-Plugin-Latex   Template-Latex
Text-Autoformat         text-autoformat
Text-Reform             text-reform
Text-Template           text-template
Text-Wrapper            text-wrapper
Tie-EncryptedHash       tie-encryptedhash
Time-Period             Period
Tk                      perl-tk
Wx                      wxperl
XML-Sablotron           XML-Sablot
YAML                    yaml
gettext                 Locale-gettext
txt2html                TextToHTML
