package FFI::Library;

use strict;
use warnings;
use Carp ();
use FFI;
use constant _is_win => $^O =~ /^(MSWin32|cygwin|msys2?)$/;

# ABSTRACT: Perl Access to Dynamically Loaded Libraries
our $VERSION = '0.02'; # VERSION

sub new
{
  my $class = shift;
  my $libname = shift;
  scalar(@_) <= 1
    or Carp::croak('Usage: $lib = FFI::Library->new($filename, [, $flags ])');
  my $lib;
  if (_is_win)
  {
    require Win32;
    $lib = Win32::LoadLibrary($libname) or return undef;
  }
  else
  {
    require DynaLoader;
    my $so = $libname;
    -e $so or $so = DynaLoader::dl_findfile($libname) || $libname;
    $lib = DynaLoader::dl_load_file($so, @_)
      or return undef;
  }
  bless \$lib, $class;
}

sub function
{
  my($self, $name, $sig) = @_;
  my $addr = shift;
  if(_is_win)
  {
    $addr = Win32::GetProcAddress($$self, $name);
  }
  else
  {
    $addr = DynaLoader::dl_find_symbol($$self, $name);
  }
  Carp::croak("Unknown function $name") unless defined $addr;
  
  sub { FFI::call($addr, $sig, @_) };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Library - Perl Access to Dynamically Loaded Libraries

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use FFI::Library;
    $lib = FFI::Library->new("mylib");
    $fn = $lib->function("fn", "signature");
    $ret = $fn->(...);

=head1 DESCRIPTION

This module provides access from Perl to functions exported from dynamically
linked libraries. Functions are described by C<signatures>, for details of
which see the L<FFI> module's documentation.

Newer and better maintained FFI modules such as L<FFI::Platypus> provide more
functionality and should probably be considered for new projects.

=head1 CONSTRUCTOR

=head2 new

 my $lib = FFI::Library->new($libname);

Creates an instance of C<FFI::Library>.

=head1 FUNCTIONS

=head2 function

 my $sub = $lib->function($function_name, $signature");

Creates a code-reference like object which you can call.

=head1 EXAMPLES

    $clib_file = ($^O eq "MSWin32") ? "MSVCRT40.DLL" : "-lc";
    $clib = FFI::Library->new($clib_file);
    $strlen = $clib->function("strlen", "cIp");
    $n = $strlen->($my_string);

=head1 SUPPORT

Please open any support tickets with this project's GitHub repository 
here:

L<https://github.com/plicease/FFI/issues>

=head1 SEE ALSO

=over 4

=item L<FFI>

Low level interface to ffcall that this module is based on

=item L<FFI::CheckLib>

Portable functions for finding libraries.

=item L<FFI::Platypus>

Platypus is another FFI interface based on libffi.  It has a more
extensive feature set, and libffi has a less restrictive license.

=item L<FFI::Raw>

Another FFI interface based on libffi.

=item L<Win32::API>

An FFI interface for Perl on Microsoft Windows.

=back

=head1 AUTHOR

Paul Moore, C<< <gustav@morpheus.demon.co.uk> >> is the original author
of L<FFI>.

Mitchell Charity C<< <mcharity@vendian.org> >> contributed fixes.

Anatoly Vorobey C<< <avorobey@pobox.com> >> and Gaal Yahas C<<
<gaal@forum2.org> >> are the current maintainers.

Graham Ollis C<< <plicease@cpan.org >> is the current maintainer

=head1 LICENSE

This software is copyright (c) 1999 by Paul Moore.

This is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
