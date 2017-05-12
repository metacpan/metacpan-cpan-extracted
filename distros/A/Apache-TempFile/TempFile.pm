# Apache::TempFile.pm
#
# Copyright (c) 1998-2002 Tom Hughes <tom@compton.nu>.
# All rights reserved. This program is free software; you can redistribute
# it and/or modify it under the same terms as Perl itself.
#
# $Id: TempFile.pm,v 1.4 2002/08/17 22:33:39 tom Exp $

package Apache::TempFile;

use strict;

use Apache;
use Carp;
use Exporter;

$Apache::TempFile::VERSION = '0.05';
@Apache::TempFile::ISA = qw(Exporter);
@Apache::TempFile::EXPORT_OK = qw(tempfile tempname);
%Apache::TempFile::EXPORT_TAGS = ( all => \@Apache::TempFile::EXPORT_OK );

@Apache::TempFile::names = ();

sub cleanup
{
  foreach my $name (@Apache::TempFile::names)
  {
    unlink($name);
  }

  @Apache::TempFile::names = ();

  return;
}

sub tempname
{
  croak 'usage: Apache::TempFile::tempname([EXTENSION])' unless @_ <= 1;

  my($directory) = $ENV{TMPDIR} || '/tmp';
  my($extension) = shift;
  my($sequence) = scalar(@Apache::TempFile::names);
  my($name) = "$directory/httpd.$$.$sequence";

  $name = "$name.$extension" if defined($extension);

  if ($ENV{MOD_PERL} && @Apache::TempFile::names == 0)
  {
      Apache->request->register_cleanup(\&cleanup);
  }

  push(@Apache::TempFile::names, $name);

  return $name;
}

END { cleanup(); }

1;

__END__

=head1 NAME

Apache::TempFile - Allocate temporary filenames for the duration of a request

=head1 SYNOPSIS

  use Apache::TempFile qw(tempname)
  my($name) = tempname();
  open(FILE,">$name");
  print FILE "Testing\n";
  close(FILE);

=head1 DESCRIPTION

This module provides names for temporary files and ensures that they are
removed when the current request is completed.

=head1 FUNCTIONS

=over 4

=item tempname

This routine returns a unique temporary filename and arranges for that
file to be removed when the current request is completed. If an extension
is supplied as an argument that it will be appended to the filename which
is generated.

  my($name) = Apache::TempFile::tempname();
  my($name) = Apache::TempFile::tempname("html");

=back

=head1 AUTHOR

Tom Hughes, tom@compton.nu

=head1 SEE ALSO

Apache(3), mod_perl(3)

=cut
