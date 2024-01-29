package Alien::PlantUML;
$Alien::PlantUML::VERSION = '0.01';
use strict;
use warnings;
use base qw( Alien::Base );
use 5.008004;

use File::Spec;

sub jar_file {
  my ($class) = @_;
  if( $class->install_type eq 'share' ) {
    return File::Spec->catfile( $class->dist_dir, $class->runtime_prop->{jar_file});
  }
  return $class->runtime_prop->{jar_file};
}

1;

=head1 NAME

Alien::PlantUML - Find or build PlantUML diagram generator

=head1 SYNOPSIS

Command line tool:

 use Alien::PlantUML;
 use Env qw( @PATH );

 unshift @PATH, Alien::PlantUML->bin_dir;

=head1 DESCRIPTION

This distribution provides PlantUML so that it can be used by other
Perl distributions that are on CPAN.  It does this by first trying to
detect an existing install of PlantUML on your system.  If found it
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=head1 CLASS METHODS

=head2 jar_file

Returns the path to the JAR file for PlantUML:

  system(qw(java), '-jar', Alien::PlantUML->jar_file, '-version');

=head1 SEE ALSO

=over 4

=item L<PlantUML|https://plantuml.com/>

PlantUML homepage

=item L<Alien>

Documentation on the Alien concept itself.

=item L<Alien::Base>

The base class for this Alien.

=item L<Alien::Build::Manual::AlienUser>

Detailed manual for users of Alien classes.

=back

=cut
