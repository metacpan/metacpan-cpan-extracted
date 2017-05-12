package Apache::WinBitHack;

BEGIN {
  eval{ 
    require Win32::File;
    Win32::File->import(qw(READONLY ARCHIVE));
  };
}

use Apache::Constants qw(OK DECLINED OPT_INCLUDES DECLINE_CMD);
use Apache::File;
use Apache::ModuleConfig;

use DynaLoader;

use 5.006;

use strict;

our $VERSION = '0.01';
our @ISA = qw(DynaLoader);

__PACKAGE__->bootstrap($VERSION);

sub handler {
  # Implement XBitHack on Win32.
  # Usage: PerlModule Apache::WinBitHack
  #        PerlFixupHandler Apache::WinBitHack
  #        XBitHack On|Off|Full

  my $r = shift;

  my $cfg = Apache::ModuleConfig->get($r, __PACKAGE__);

  return DECLINED unless (
     $^O =~ m/Win32/                  &&    # we're on Win32
     -f $r->finfo                     &&    # the file exists
     $r->content_type eq 'text/html'  &&    # and is HTML
     $r->allow_options & OPT_INCLUDES &&    # and we have Options +Includes
     $cfg->{_state} ne 'OFF');              # and XBitHack On or Full

  # Gather the file attributes.
  my $attr;
  Win32::File::GetAttributes($r->filename, $attr);

  # Return DECLINED if the file has the ARCHIVE attribute set,
  # which is the usual case.
  return DECLINED if $attr & ARCHIVE();

  # Set the Last-Modified header unless the READONLY attribute is set.
  if ($cfg->{_state} eq 'FULL') {
    $r->set_last_modified((stat _)[9]) unless $attr & READONLY();
  }

  # Make sure mod_include picks it up.
  $r->handler('server-parsed');

  return OK;
}

sub DIR_CREATE {

  my $class = shift;
  my %self  = ();

  # XBitHack is disabled by default.
  $self{_state} = "OFF";

  return bless \%self, $class;
}

sub DIR_MERGE {

  my ($parent, $current) = @_;
  my %new = (%$parent, %$current);

  return bless \%new, ref($parent);
}

sub XBitHack ($$$) {

  my ($cfg, $parms, $arg) = @_;

  # Let mod_include do the Unix stuff - we only do Win32.
  return DECLINE_CMD unless $^O =~ m/Win32/;

  if ($arg =~ m/^(On|Off|Full)$/i) {
    $cfg->{_state} = uc($arg);
  }
  else {
    die "Invalid XBitHack $arg!";
  }
}
1;

__END__

=head1 NAME

Apache::WinBitHack - An Apache module to emulate XBitHack on Win32

=head1 SYNOPSIS

In Apache's F<httpd.conf>:

   PerlModule Apache::WinBitHack

   <Directory "/Apache/htdocs/some_dir">
      SetHandler perl-script
      PerlFixupHandler Apache::WinBitHack
      XBitHack Full
      Options MultiViews Indexes Includes
   </Directory>

=head1 DESCRIPTION

Apache contains a very useful directive C<XBitHack>, whereby a file
that has the user-execute bit set will be treated as a server-parsed 
html document. As well, the group-execute bit can be used to set
the Last-modified time of the returned file to be the last modified 
time of the file, which is useful in determining if a document is
to be cached or not. On Win32 the directive works in principle, but
in an inconvenient fashion - the execute bit is set on Win32 by the
file extension, which means that documents that are to take advantage
of C<XBitHack> must have an extension like C<exe> or C<bat>.

This module emulates C<XBitHack> on Win32 by, rather than using the
user and group execute bits, using instead the attributes
of the file to determine if the file is to be server-parsed by mod_include.
Attributes of a file on Win32, which you can see by running

    C:\> attrib file_name

include C<archive>, C<hidden>, C<read-only>, and C<system>. Normal
user files have just the C<archive> attribute set, which some back-up
programs use to determine if the file should be included in the next 
incremental backup (most backup programs now instead use the 
last-modified-time of the file for this purpose). By setting certain
attributes of the file and specifying directives as in the SYNOPSIS,
particularly the C<Includes> option, 
C<XBitHack> can be emulated in the following ways.

=head2 XBitHack Off

With this directive, no server-side parsing of the file
will be performed.

=head2 XBitHack On

This directive emulates setting the user-execute bit. With this
directive, a file will parsed by mod_include if the C<archive> 
attribute is B<unset>, which you can do by

   C:\> attrib -a file_name

Note that when a user's file is first created or when it is edited 
the C<archive> attribute will normally be set (and all others unset),
so you must intentionally unset the C<archive> attribute to enable 
server-parsing of the file.

=head2 XBitHack Full

This directive emulates the action of also setting the group-execute 
bit. With this directive, as with C<XBitHack On>, a file will be 
parsed by mod_include if the C<archive> attribute is unset. As well, 
a Last-modified header will be sent, equal to the last-modified time 
of the file, I<unless> the C<read-only> attribute of the file is B<set>, 
which you can do by

   C:\> attrib +r file_name

=head1 SEE ALSO

L<mod_perl>

The description of the C<XBitHack> directive in the Apache
manual (http://httpd.apache.org/docs/mod/directives.html).

=head1 AUTHORS

Randy Kobes <randy@modperlcookbook.org>

Geoffrey Young <geoff@modperlcookbook.org>

Paul Lindner <paul@modperlcookbook.org>

=head1 COPYRIGHT

Copyright (c) 2001, Geoffrey Young, Paul Lindner, Randy Kobes.  
All rights reserved.

This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=head1 HISTORY

This code is derived from the I<Cookbook::WinBitHack> module,
available as part of "The mod_perl Developer's Cookbook".

For more information, visit http://www.modperlcookbook.org/

=cut
