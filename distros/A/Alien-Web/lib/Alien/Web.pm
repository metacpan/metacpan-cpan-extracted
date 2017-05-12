package Alien::Web;

use strict;
use warnings;

# ABSTRACT: Base class/namespace static web asset distributions on CPAN
our $VERSION = 1.1;

use File::ShareDir qw(dist_dir);
require Path::Class;

sub dir {
  my $class = shift or die "dir() must be called as a class method";
  
  my $dist_dir = $class->path;
  
  $dist_dir ? Path::Class::dir($dist_dir) : undef
}


sub path {
  my $class = shift or die "dir() must be called as a class method";
  
  die "Alien::Web is a base class and is not meant to be called directly"
    if($class eq 'Alien::Web');
  
  my $dist = $class;
  $dist =~ s/\:\:/\-/g;
  
  dist_dir($dist)
}

1;

__END__

=pod

=head1 NAME

Alien::Web - Base class/namespace for static web asset distributions on CPAN

=head1 SYNOPSIS

  package Alien::Web::Something;
  use parent 'Alien::Web';
  
  1;


=head1 DESCRIPTION

This is the base class/namespace for distributing static web assets, such as JavaScript libraries,
via CPAN using Perl's ShareDir functionality. 

This class is very simple and exists mainly for the purposes of grouping and defining a common 
API for these distributions to follow. See L<Alien::Web::ExtJS::V3> for a working example.

=head1 METHODS

=head2 dir

Returns the distribution share directory as a L<Path::Class::Dir> object.

=head2 path

Returns the raw distribution share directory (as returned by C<File::ShareDir::dist_dir>).

=head1 SEE ALSO

=over 4

=item * L<Alien::Web::ExtJS::V3>

=item * L<File::ShareDir>


=back

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by IntelliTree Solutions llc. 

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

