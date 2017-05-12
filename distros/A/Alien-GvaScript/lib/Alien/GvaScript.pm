package Alien::GvaScript;
use strict;
use warnings;

use File::Copy qw(copy);
use File::Path qw(mkpath);

our $VERSION = '1.44';

sub path {
  (my $path = __FILE__) =~ s[\.pm$][/lib];
  return $path;
}

sub html {
  (my $html_path = __FILE__) =~ s[\.pm$][/html];
  return $html_path;
}

sub install {
    my ($class, $destdir) = @_;
    if (!-d $destdir) {
        mkpath( $destdir ) 
          or die "can't create '$destdir'; $!";
    }

    my $path = $class->path();
    my @files = grep { -f $_ } glob "$path/*";
    foreach my $file (@files) {
        copy( $file, $destdir ) 
          or die "can't copy '$file' to '$destdir'; $!";
    }
}

1;

__END__

=encoding ISO8859-1

=head1 NAME

Alien::GvaScript - Gva extension to the prototype javascript framework

=head1 SYNOPSIS

  use Alien::GvaScript;
  ...
  $path    = Alien::GvaScript->path();
  ...
  Alien::GvaScript->install( $my_destination_directory );

=head1 DESCRIPTION

GvaScript (pronounce "gee-vascript") is a javascript framework 
born in Geneva, Switzerland (C<GVA> is the IATA code for 
Geneva Cointrin International Airport). 

It is built on top of the B<prototype>
object-oriented javascript framework (L<http://www.prototypejs.org>)
and offers a number of extensions and widgets, such as 
keymap handling, application-specific events, 
autocompletion on input field, tree navigation, and
forms with autofocus and repeated sections.
These functionalities are described in separate
documentation pages (see L<Alien::GvaScript::Intro>).

GvaScript is distributed using Perl tools, but the actual
content of the library is pure javascript; hence its 
location in the Alien namespace (see the L<Alien> manifesto).

GvaScript runtime library does not need Perl; you can integrate
it in any other Web programming framework. Perl is only needed for
developers who want to modify GvaScript sources and recreate a 
distribution package.



=head1 INSTALLATION

=head2 With usual Perl CPAN tools

Install C<Alien::GvaScript> just as any other CPAN module. Then you can 
write

  perl -MAlien::GvaScript -e "Alien::GvaScript->install('/my/web/directory')"

to copy the dthml files to your Web server.


=head2 Without Perl tools

Unzip and untar this distribution, then grab the 
files in F<lib/Alien/GvaScript/lib> subdirectory
and copy them to your Web server. 


=head2 Note about the documentation

The documentation sources are written in Perl's "POD" format.
An HTML version is automatically generated and included
in this distribution, under the F<lib/Alien/GvaScript/html> directory;
this documentation uses GvaScript's I<treeNavigator> widget 
for easier browsing.

If this distribution is installed as a CPAN module, then
another HTML version will probably be generated automatically
by your CPAN tool (but without the I<treeNavigator> widget).


=head1 METHODS

=head2 path

Returns the directory where GvaScript files are stored.

=head2 html

Returns the directory where GvaScript documentation
is stored.

=head2 install

Copies GvaScript files into the directory supplied as argument


=head1 AUTHORS

Laurent Dami, C<< <laurent.d...@etat.ge.ch> >>

Mona Remlawi, C<< <mona.r...@etat.ge.ch> >>

Jean_Christophe Durand

Sébastien Cuendet

=head1 BUGS

Please report any bugs or feature requests to
C<bug-alien-gvascript at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Alien-GvaScript>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Alien::GvaScript

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Alien-GvaScript>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Alien-GvaScript>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-GvaScript>

=item * Search CPAN

L<http://search.cpan.org/dist/Alien-GvaScript>

=back

=head1 ACKNOWLEDGEMENTS

The packaging as an C<Alien> module was heavily inspired from
L<Alien::scriptaculous> by Graham TerMarsch.

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008, 2009, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Alien::GvaScript
