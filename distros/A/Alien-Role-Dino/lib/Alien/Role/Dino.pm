package Alien::Role::Dino;

use strict;
use warnings;
use 5.008001;
use Role::Tiny;
use Role::Tiny::With ();

# ABSTRACT: Experimental support for dynamic share Alien install
our $VERSION = '0.03'; # VERSION


sub rpath
{
  my($self, @other) = @_;
  
  my @dir;
  
  foreach my $alien ($self, @other)
  {
    if($alien->can('runtime_prop') && defined $alien->runtime_prop->{rpath})
    {
      require Path::Tiny;
      foreach my $rpath (map { Path::Tiny->new($_)->absolute($alien->dist_dir)->stringify } @{ $alien->runtime_prop->{rpath} })
      {
        push @dir, $rpath;
      }
    }
  }
  
  @dir;
}


sub xs_load
{
  my($self, $package, $version, @rest) = @_;
  require XSLoader;
  XSLoader::load($package, $version);
}

around import => sub {
  return;
};

Role::Tiny::With::with("Alien::Role::Dino::$^O");

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Role::Dino - Experimental support for dynamic share Alien install

=head1 VERSION

version 0.03

=head1 SYNOPSIS

In your L<alienfile>:

 use alienfile;
 
 share {
   ...
   plugin 'Gather::Dino';
 }

Apply L<Alien::Role::Dino> to your L<Alien::Base> subclass:

 package Alien::libfoo;
 
 use base qw( Alien::Base );
 use Role::Tiny::With qw( with );
 
 with 'Alien::Role::Dino';
 
 1;

And finally from the .pm side of your XS module:

 package Foo::XS;
 
 use Alien::libfoo;
 
 our $VERSION = '1.00';
 
 # Note caveat: your Alien is now a run-time
 # dependency of your XS module.
 Alien::libfoo->xs_load(__PACKAGE__, $VERSION);
 
 1;

=head1 DESCRIPTION

Every now and then someone will ask me why thus and such L<Alien> thing 
doesn't work with a dynamic library error.  My usual response is can you 
make it work with static libraries?  The reason for this is that 
B<building> dynamic libraries for an L<Alien> B<share> install introduce 
a number of challenges, and honestly I don't see the point of using 
them, if you can avoid it.  So far I haven't actually seen a situation 
where it couldn't be avoided.  Just to be clear: dynamic libraries are 
fine for Alien, and in fact desirable when you are using the system 
provided libraries.  You get the patches and security fixes supplied by 
your operating system.

Okay, so why not build a dynamic library for a B<share> install?

For this discussion, say you have an alienized library C<Alien::libfoo> 
and an XS module that uses it called C<Foo::XS> (as illustrated in the 
synopsis above).

=over 4

=item Your Alien becomes a run-time dependency.

When you link your C<Foo::XS> module with a static library from 
C<Alien::libfoo> it gets added into the DLL or C<.so> file that the Perl 
toolchain produces.  That means when you later use it, it doesn't need 
anything else.  When you try to do the same thing with a dynamic 
library, you need that dynamic library, which is stored in a share 
directory of C<Alien::libfoo>.

For people who install out of CPAN this is probably not a big deal, but 
for operating system vendors (the people who integrate Perl modules into 
their operating system), it is a hassle because now you need this big 
build tool L<Alien::Build> and the alien C<Alien::libfoo> with extra 
dependencies during runtime.  Normally you wouldn't need those packages 
installed for end-user use.

=item Upgrades can and will break your XS module.

Again, when C<Alien::libfoo> builds a static library and it gets linked 
into a DLL or C<.so> for C<Foo::XS>, it doesn't need the original 
library anymore.  If you are using a dynamic library and you do the same 
thing it maybe works today, but say tomorrow you upgrade 
C<Alien::libfoo> and it replaces the DLL or C<.so> file with an 
incompatible API or ABI?  Now your C<Foo::XS> module has stopped 
working!

=item Dynamic libraries are not portable

Dynamic libraries are widely supported on most modern operating systems, 
but each system provides a different interface.  For example, Linux, 
Windows and OS X all have an environment variable that allows you to 
alter the search path for finding dynamic libraries, but all three have 
different extensions for dynamic libraries (OS X even has two!), the 
environment variables are called something different, and WHEN you can 
change them is different.

The Perl core has code for loading dynamic libraries as part of its XS 
system on all platforms where you can build XS extensions dynamically. 
Unfortunately that code isn't quite reusable for use by Alien.  Alien 
developers have limited time and access to many platforms, which means 
that many platforms will probably never get Alien support.

Static libraries on the other hand pretty much work the same on all 
platforms.  Even on Windows which likes to be different, static 
libraries are essentially the same as on Unix.

=back

So all that said, why have I written this module, which provides support 
for dynamic libraries?  Well, maybe I am wrong, maybe it isn't that 
hard.  Also, maybe you don't have a choice, maybe you have found a 
library that can ONLY be built using a dynamic library.

What about you?  Should you use this module?  It has the worked 
B<Experimental> in the description.  The experimental aspect of this 
module should not worry you, because in the situation that your Alien 
finds the library from the system, nothing is different from the core 
L<Alien::Build>.  The only place it is different is if you have to do a 
share install, and hopefully you are only using it because you really 
can't build a static library.  Thus you haven't really lost anything in 
stability, and at worst your Alien may work in places where it wouldn't 
otherwise.

So in summary, the experimental aspect shouldn't worry you, the caveats 
above should!

=head1 HOW

How does it work?  Use the bundled L<alienfile> plugin 
L<Alien::Build::Plugin::Gather::Dino>.  That will find any dynamic 
library paths in your share directory in case they are needed at 
runtime.  Then apply this role to you L<Alien::Base> subclass using
L<Role::Tiny::With>.  Instead of using L<XSLoader> or L<DynaLoader>
to load your XS module, use the C<xs_load> from your L<Alien>.
Hopefully the synopsis above makes it clear.

=head1 ETYMOLOGY

This module is named B<Dino> being short for Dinosaur.  I really like 
Dinosaurs (also friendly crocodiles and L<platypuses|FFI::Platypus> in 
case you hadn't noticed).  "Dino" also has a similar sound to "Dyna" 
which is frequently used as a short name or prefix meaning "dynamic".  I 
didn't want to call it "Dyna" or "Dynamic" since it is only building a 
dynamic library for share installs.  I didn't want to call it DynaShare 
because that was getting a bit wordy.  So Dino.

=head1 METHODS

=head2 rpath

 my @dirs = $alien->rpath;

Returns the list of directories that have non-system dynamic libraries
in them.  On some systems this is needed at compile time, on others
it is needed at run time.

=head2 xs_load

 $alien->xs_load($package, $version);
 $alien->xs_load($package, $version, @other_dino_aliens);

=head1 CAVEATS

Lots.  In summary:

=over 4

=item Your Alien is a run-time dependency and you will annoy system integrators

=item Your XS can be broken by upgrades to your Alien

=item Your platform may not be supported

=back

Also, this module should start with the caveat section and then go from 
there.  Most modules I write are not like that.

These platforms seem to work: Linux, OS X, Windows, Cygwin, FreeBSD, 
NetBSD, OpenBSD, Debian kFreeBSD.

Currently has L<Alien::Autotools> as a prerequisite.  I hope to remove that prereq
asap.

=head1 SEE ALSO

=over 4

=item L<alienfile>

=item L<Alien::Base>

=item L<Alien::Build>

=item L<Alien::Build::Plugin::Gather::Dino>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
