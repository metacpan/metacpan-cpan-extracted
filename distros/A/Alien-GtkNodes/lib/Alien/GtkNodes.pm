use strict;
use warnings;
package Alien::GtkNodes;

# ABSTRACT: Find or install GtkNodes

our $VERSION = '0.003';

use parent qw/ Alien::Base /;
use Role::Tiny::With qw/ with /;
use Env qw/ @GI_TYPELIB_PATH /;
use DynaLoader;
use File::Spec;

with 'Alien::Role::Dino';

# h/t: ZMUGHAL/Alien-Graphene
sub gi_typelib_path {
    my $c = shift;
    $c->install_type eq 'share'
        ? ( File::Spec->catfile( $c->dist_dir, qw/ lib girepository-1.0 / ) )
        : ();
}

sub init {
    my $c = shift;
    unshift @GI_TYPELIB_PATH, $c->gi_typelib_path;
    push @DynaLoader::dl_library_path, $c->rpath;
    my @files = DynaLoader::dl_findfile( '-lgtknodes-0.1' );
    DynaLoader::dl_load_file($files[0]) if @files;
}











1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::GtkNodes - Find or install GtkNodes

=head1 VERSION

version 0.003

=head1 SYNOPSIS

In your Makefile.PL:

 use ExtUtils::MakeMaker;
 use Alien::Base::Wrapper ();

 WriteMakefile(
   Alien::Base::Wrapper->new('Alien::GtkNodes')->mm_args2(
     # MakeMaker args
     NAME => 'My::XS',
     ...
   ),
 );

In your Build.PL:

 use Module::Build;
 use Alien::Base::Wrapper qw( Alien::GtkNodes !export );

 my $builder = Module::Build->new(
   ...
   configure_requires => {
     'Alien::GtkNodes' => '0',
     ...
   },
   Alien::Base::Wrapper->mb_args,
   ...
 );

 $build->create_build_script;

=head1 DESCRIPTION

This distribution provides GtkNodes so that it can be used by other
Perl distributions that are on CPAN.  It does this by first trying to
detect an existing install of GtkNodes on your system.  If found it
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=head1 METHODS

=head2 init

Sets Typelib path and loads shared library, for use with
L<Glib::Object::Introspection>

    use Alien::GtkNodes;
    
    BEGIN {
        Alien::GtkNodes->init;
    }

    use Gtk3;
    use Glib::Object::Introspection;
    
    Glib::Object::Introspection->setup(
        basename => 'GtkNodes',
        version => '0.1',
        package => 'GtkNodes',
    );

=head1 SEE ALSO

L<Alien>, L<Alien::Base>, L<Alien::Build::Manual::AlienUser>

L<GtkNodes|https://github.com/aluntzer/gtknodes/>

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
