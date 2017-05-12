package Acme::Win32::PEPM;
package Win32::PEPM;

use strict;
use warnings;
use DynaLoader;

our $VERSION = '0.02';

#stolen from XSLoader, unneeded on Win32 fluff removed
sub load {
    #we only load the caller .pm, this is not negotiable
    my $module = (caller())[0];
    my $bootname = "boot_$module";
    $bootname =~ s/\W/_/g;
    my $file = shift;
    my $libref = DynaLoader::dl_load_file($file, 0) or do { 
        require Carp;
        Carp::croak("Can't load '$file' for module $module: " . DynaLoader::dl_error());
    };
    push(@DynaLoader::dl_librefs,$libref);  # record loaded object
    push(@DynaLoader::dl_modules, $module); # record loaded module

    my $boot_symbol_ref = DynaLoader::dl_find_symbol($libref, $bootname) or do {
        require Carp;
        Carp::croak("Can't find '$bootname' symbol in $file\n");
    };
  boot:
    my $xs = DynaLoader::dl_install_xsub("$module\::bootstrap", $boot_symbol_ref, $file);

    # See comment block above
    push(@DynaLoader::dl_shared_objects, $file); # record files loaded
    return &$xs(@_);
}

1;
__END__
=head1 NAME

Acme::Win32::PEPM - turn your separate XS .dll+.pm into being both a .pm and .dll

=head1 SYNOPSIS

  #in your Makefile.PL
  use Win32::PEPM::Build;
  my %config = {
    NAME              => 'Foo::Bar',
    AUTHOR            => 'A. U. Thor <a.u.thor@a.galaxy.far.far.away>',
  ...
  Win32::PEPM::Build::WMHash(\%config);
  WriteMakefile(%config;)

  #in your .pm
  use Win32::PEPM;
  Win32::PEPM::load(__FILE__, $VERSION);
  1;
  __END__ #you must have this
  
  #optional, suggested if you have pod.t
  =encoding latin1

=head1 DESCRIPTION

This module is a packager that allows you to build a .pm that is simultaneously
a .pm that can be C<do>, C<require>d, or C<use>d, and the same .pm is a 100%
real DLL containing XS code. The generated file meets the file format standards
of both a .pm and a PE (Portable Executable) DLL and uses no temp files.
The author of this module sees this module as a joke since with this
"packager", the .pm text is stored uncompressed in the .dll, and there is no
sane reason to keep .pm text memory mapped into a process since after
parsing/compiling .pm, the .pm text is never referenced again, yet with this
"packager", if the XS DLL is loaded, so is the .pm text, into the process.

The resulting .pm that is built can not be edited even though it mostly looks
like plain text. If it is edited, the DLL will be corrupt. The resulting .pm,
although superficially looking like pure perl can not be moved between perl
installations/versions except for maint versions, since the XS DLL inside the
.pm, like all XS DLLs/SOs is bound to a particular perl installation and version
number.

=head1 FUNCTIONS

=head2 load

    Win32::PEPM::load(__FILE__, $VERSION);

Similar to L<XSLoader|XSLoader's> C<load> sub except takes a filename as first
arg. This file name must be the C<__FILE__> token.

=head1 KNOWN ISSUES

=over 4

=item *

Mingw/GCC support not implemented. Patches welcome. The author has no clue
what VC's C<-stub> is with C<ld>.

=back

=head1 AUTHOR

Daniel Dragan, E<lt>bulkdd@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Daniel Dragan, E<lt>bulkdd@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.21.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
