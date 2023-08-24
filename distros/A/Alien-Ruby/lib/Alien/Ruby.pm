#
# This file is part of Alien-Ruby
#
# This software is copyright (c) 2023 by Auto-Parallel Technologies, Inc.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

package Alien::Ruby;

use strict;
use warnings;
use base qw( Alien::Base );

our $VERSION = '0.01';
 
sub alien_helper {
  my($class) = @_;
  return {
    ruby => sub { $class->ruby_exe },
    gem  => sub { $class->gem_exe  },
  };
}

sub ruby_exe {
    'ruby';
}

sub gem_exe {
    'gem';
}

1;

__END__

=head1 NAME
 
Alien::Ruby - Find or install Ruby
 
=head1 SYNOPSIS
 
 use Alien::Ruby;

 use Env qw( @PATH );
 
 unshift @PATH, Alien::Ruby->bin_dir;

 system(q(ruby -e 'puts "Hello from Ruby!"'));

 system('gem install pry');
 
=head1 DESCRIPTION
 
This distribution provides the Ruby programming language so that it can be used
by other Perl distributions. It does this by first trying to detect an existing
install of Ruby on your system. If found it will use that. If it cannot be
found, the Ruby source code will be downloaded from the internet and it will be
compiled and installed to a private share location for the use of other Perl
modules.

=head1 GEM

Because RubyGems is included with Ruby, and the C<gem> executable is installed
into the same directory as the <ruby> executable, you can use Alien::Ruby as if
it were Alien::Gem.

Please be mindful of the C<$ENV{GEM_HOME}> and C<$ENV{GEM_PATH}> environment
variables. These variables will change the default locations where Gem's can be
found, and where Gem's will be installed.

=head1 SPECIFY RUBY VERSION

To specify the version of Ruby you want, set the C<ALIEN_RUBY_VERSION>
environment variable before installing Alien::Ruby:

  $ ALIEN_RUBY_VERSION=2.7.7 cpanm Alien::Ruby

The minimum supported Ruby version is 2.1.0.

=head1 WINDOWS

Windows is not currently supported. Patches welcome.

=head1 SEE ALSO
 
=over 4
 
=item L<Alien>
 
Documentation on the Alien concept itself.
 
=item L<Alien::Base>
 
The base class for this Alien.
 
=item L<Alien::Build::Manual::AlienUser>
 
Detailed manual for users of Alien classes.
 
=back

=head1 AUTHOR

Nicholas Hubbard <nicholashubbard@posteo.net>

=head1 CONTRIBUTORS

=over 4

=item * William N. Braswell, Jr.

=item * Zakariyya Mughal

=back
 
=cut
