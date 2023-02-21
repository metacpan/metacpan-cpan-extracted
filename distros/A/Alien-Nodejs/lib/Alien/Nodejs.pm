package Alien::Nodejs;
$Alien::Nodejs::VERSION = '0.01';
use strict;
use warnings;
use base qw( Alien::Base );
use 5.008004;

sub bin_dir {
  my ($class) = @_;
  if($class->install_type('share')) {
    my $dir = Path::Tiny->new($class->dist_dir);
    my $bin_dir = $dir->child('bin');
    if( -d $bin_dir ) {
      return ("$bin_dir");
    }
    return -d $dir ? ("$dir") : ();
  } else {
    return $class->SUPER::bin_dir(@_);
  }
}

1;

=head1 NAME

Alien::Nodejs - Find or build Node.js

=head1 SYNOPSIS

Command line tool:

 use Alien::Nodejs;
 use Env qw( @PATH );

 unshift @PATH, Alien::Nodejs->bin_dir;

=head1 DESCRIPTION

This distribution provides Node.js so that it can be used by other
Perl distributions that are on CPAN.  It does this by first trying to
detect an existing install of Node.js on your system.  If found it
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=head1 SEE ALSO

=over 4

=item L<Alien>

Documentation on the Alien concept itself.

=item L<Alien::Base>

The base class for this Alien.

=item L<Alien::Build::Manual::AlienUser>

Detailed manual for users of Alien classes.

=back

=cut
