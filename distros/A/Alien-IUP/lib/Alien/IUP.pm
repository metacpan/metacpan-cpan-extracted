package Alien::IUP;

use warnings;
use strict;

use Alien::IUP::ConfigData;
use File::ShareDir qw(dist_dir);
use File::Spec::Functions qw(catdir catfile rel2abs);

=head1 NAME

Alien::IUP - Building, finding and using iup + related libraries - L<http://www.tecgraf.puc-rio.br/iup/>

=cut

our $VERSION = "0.710";

=head1 VERSION

=over

=item * I<iup> library 3.19.1 - see L<http://www.tecgraf.puc-rio.br/iup/>

=item * I<im> library 3.11 - see L<http://www.tecgraf.puc-rio.br/im/>

=item * I<cd> library 5.10 - see L<http://www.tecgraf.puc-rio.br/cd/>

=back

=head1 SYNOPSIS

B<IMPORTANT:> This module is not a perl binding for I<iup + related> libraries; it is just
a helper module. The real perl binding is implemented by L<IUP|IUP> module,
which is using Alien::IUP to locate I<iup + related> libraries on your system (or build it from source codes).

Alien::IUP installation comprise of:

=over

=item * Downloading I<iup> & co. source code tarballs

=item * Building I<iup> & co. binaries from source codes (note: static libraries are build)

=item * Installing libs and dev files (*.h, *.a) into I<share> directory of Alien::IUP
distribution - I<share> directory is usually something like this: /usr/lib/perl5/site_perl/5.18/auto/share/dist/Alien-IUP

=back

Later on you can use Alien::IUP in your module that needs to link with
I<iup> and/or related libs like this:

 # Sample Makefile.pl
 use ExtUtils::MakeMaker;
 use Alien::IUP;
 
 WriteMakefile(
   NAME         => 'Any::IUP::Module',
   VERSION_FROM => 'lib/Any/IUP/Module.pm',
   LIBS         => Alien::IUP->config('LIBS'),
   INC          => Alien::IUP->config('INC'),
   # + additional params
 );

B<IMPORTANT:> As Alien::IUP builds static libraries the modules using Alien::IUP (e.g. L<IUP|IUP>)
need to have Alien::IUP just for building, not for later use. In other words Alien:IUP is just
"build dependency" not "run-time dependency".

=head1 METHODS

=head2 config()

This function is the main public interface to this module.

 Alien::IUP->config('LIBS');

Returns a string like: '-L/path/to/iupdir/lib -liup -lim -lcd'

 Alien::IUP->config('INC');

Returns a string like: '-I/path/to/iupdir/include'

 Alien::IUP->config('PREFIX');

Returns a string like: '/path/to/iupdir' (note: if using the already installed
I<iup> config('PREFIX') returns undef)

=head2 havelib()

Checks the presence of given iup related libraries.

 Alien::IUP->havelib('iupim');
 #or
 Alien::IUP->havelib('iupim', 'iupcd', 'iupcontrols');

Parameter(s): One or more iup related lib names - e.g. iup, cd, im, iupcd, iupim, iupcontrols, iup_pplot, iupimglib, iupgl, iupole.

Returns: 1 if all libs specified as a param are available; 0 otherwise.

=head1 AUTHOR

KMX, E<lt>kmx at cpan.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-alien-iup at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-IUP>.

=head1 LICENSE AND COPYRIGHT

Libraries I<iup>, I<im> and I<cd>: Copyright (C) 1994-2015 Tecgraf, PUC-Rio.
L<http://www.tecgraf.puc-rio.br>

Alien::IUP module: Copyright (C) 2015 KMX.

This program is distributed under the MIT License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

sub config {
  my ($package, $param) = @_;
  return unless ($param =~ /[a-z0-9_]*/i);
  my $subdir = Alien::IUP::ConfigData->config('share_subdir');
  unless ($subdir) {
    #we are using lib already installed on your system not compiled by Alien
    #therefore no additional magic needed
    return Alien::IUP::ConfigData->config('config')->{$param};
  }
  my $share_dir = dist_dir('Alien-IUP');
  my $real_prefix = catdir($share_dir, $subdir);
  my $val = Alien::IUP::ConfigData->config('config')->{$param};
  return unless $val;
  $val =~ s/\@PrEfIx\@/$real_prefix/g; # handle @PrEfIx@ replacement
  return $val;
}

sub havelib {
  my ($package, @libs) = @_;
  my $iuplibs = my $subdir = Alien::IUP::ConfigData->config('iup_libs');
  return 0 unless defined $iuplibs;
  for (@libs) {
    return 0 unless defined $iuplibs->{$_} && $iuplibs->{$_} == 1;
  }
  return 1;
}

1; # End of Alien::IUP
