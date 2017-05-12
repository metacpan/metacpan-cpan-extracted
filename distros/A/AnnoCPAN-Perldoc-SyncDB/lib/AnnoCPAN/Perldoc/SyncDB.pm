package AnnoCPAN::Perldoc::SyncDB;

use warnings;
use strict;
use LWP::UserAgent;
use File::Spec;
use Carp;

our $VERSION = '0.11';

# Default URL, can be overridden via package method
my $baseurl = 'http://annocpan.org/annopod.db';

=head1 NAME 

AnnoCPAN::Perldoc::SyncDB - Download the AnnoCPAN database

=head1 LICENSE

Copyright Clotho Advanced Media Inc.

This software is released by Clotho Advanced Media, Inc. under the same
terms as Perl itself.  That means that it is dual-licensed under the
Artistic license and the GPL, and that you can redistribute it and/or
modify it under the terms of either or both of those licenses.  See
the "LICENSE" file, or visit http://www.clotho.com/code/Perl

The definitive source of Clotho Advanced Media software is
http://www.clotho.com/code/

All of our software is also available under commercial license.  If
the Artisic license or the GPL does not meet the needs of your
project, please contact us at info@clotho.com or visit the above URL.

We release open source software to help the world.  We hope that you
will enjoy this software, and we also hope and that you will hire us.
As authors of this software, we are best able to help you integrate it
into your project and to assist you with any problems.

=head1 SYNOPSIS

    use AnnoCPAN::Perldoc::SyncDB;
    AnnoCPAN::Perldoc::SyncDB->run(
       dest => "$ENV{HOME}/.annopod.db",
       verbose => 1,
    );

=head1 DESCRIPTION

This module provides a simple interface to mirror the
L<http://annocpan.org/> content to a local machine.  In conjunction
with the L<AnnoCPAN::Perldoc> module, this allows one to get all the
benefits of the AnnoCPAN website in one's local C<perldoc> command.

Recommended usage: 1) Install this module and AnnoCPAN::Perldoc, 2)
set up a weekly process to run the C<syncannopod> command included in
this distribution, 3) Put the following in your shell configuration:
C<alias perldoc annopod>.

=head1 FUNCTIONS

=over

=item $pkg->baseurl()

=item $pkg->baseurl($newurl)

Returns the default URL for the annopod.db file.  If there is an
argument, it sets the default URL to that value before returning.

=cut

sub baseurl
{
   my $pkg = shift;
   if (@_ > 0)
   {
      $baseurl = shift;
   }
   return $baseurl;
}

=item $pkg->run([OPTS])

Mirrors the annopod.db file from the net.  The behavior can be altered
via hash-like options:

=over

=item dest => filename

Specifies the filename where the downloaded file should be stored.

Defaults to the same location used by AnnoCPAN::Perldoc, or if that fails C<$HOME/.annopod.db> (C<$HOME\annopod.db> on Windows).

=item src => url

Specifies the net resource that should be mirrored.

Defaults to the baseurl property of this module.

=item timeout => seconds

Specifies the LWP::UserAgent timeout.  Defaults to 30 seconds.

=item compress => flag

Specifies which version of the database to download.  The options are
C<bz2>, C<gz>, the empty string (i.e. no compression) or C<undef>,
which means autodetection.  The autodetect mode checks if you have
Compress::Bzip2 or Compress::Zlib installed before picking the best of
the other flag values.

Defaults to C<undef> (that is, autodetect mode).

=item verbose => boolean

Defaults to a false value.  If set to true, this method prints status messages to the output filehandle.

=back

=cut

sub run
{
   my $pkg = shift;
   if (@_ % 2)
   {
      croak("Error: odd number of arguments");
   }
   my %opts = @_;
   $opts{src} ||= $baseurl;
   $opts{timeout} ||= 30;

   if (!$opts{dest})
   {
      # This algorithm is duplicated from AnnoCPAN::Perldoc
      # Future versions should access that module's algorithm directly
      DIR: foreach my $dir (@ENV{qw(HOME USERPROFILE ALLUSERSPROFILE)},
                            '/var/annocpan')
      {
         if ($dir && -d $dir)
         {
            foreach my $file ('annopod.db', '.annopod.db')
            {
               my $path = File::Spec->catfile($dir, $file);
               if (-w $path)
               {
                  $opts{dest} = $path;
                  last DIR;
               }
            }
         }
      }
   }

   if (!$opts{dest} && $ENV{HOME})
   {
      $opts{dest} = File::Spec->catfile($ENV{HOME}, 
                                  ($^O eq 'MSWin32' ? '' : '.') .
                                  'annopod.db');
   }
   
   if (!$opts{dest})
   {
      croak('No destination file specified');
   }

   if (!defined $opts{compress})
   {
      $opts{compress} = '';
      local $SIG{__WARN__} = 'DEFAULT';
      local $SIG{__DIE__} = 'DEFAULT';
      eval 'use Compress::Bzip2';
      if (!$@)
      {
         $opts{compress} = 'bz2';
      }
      else
      {
         eval 'use Compress::Zlib';
         if (!$@)
         {
            $opts{compress} = 'gz';
         }
      }
   }

   my $ext = $opts{compress} ? ".$opts{compress}" : '';
   my $url = $opts{src}.$ext;
   my $dest = $opts{dest};

   print "Downloading $url --> $dest$ext\n" if ($opts{verbose});

   my $ua = LWP::UserAgent->new();
   $ua->timeout($opts{timeout});
   $ua->env_proxy;
   $ua->mirror($url, $dest.$ext)
       || croak("Failed to mirror $url");

   if ($opts{compress})
   {
      print "Uncompressing $dest$ext --> $dest\n" if ($opts{verbose});
      open(my $out, "> $dest")
          || croak("Failed to write to $dest");
      my $buf;
      if ($opts{compress} eq 'bz2')
      {
         my $bz = Compress::Bzip2->new();
         $bz->bzopen($dest.$ext, "r");
         while ($bz->bzread($buf) > 0)
         {
            print $out $buf;
         }
         $bz->bzclose();
      }
      elsif ($opts{compress} eq 'gz')
      {
         my $gz = Compress::Zlib::gzopen($dest.$ext, "r");
         while ($gz->gzread($buf) > 0)
         {
            print $out $buf;
         }
         $gz->gzclose();
      }
      else
      {
         carp('Compression option not understood.  Skipping uncompress step.');
      }
      close $out;
   }
   print "Done\n" if ($opts{verbose});
}

1;
__END__

=back

=head1 SEE ALSO

L<AnnoCPAN::Perldoc>

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan
