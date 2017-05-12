package Alien::SFML;

use strict;
use warnings;

our $VERSION = 0.02;    #For SFML 2.0
$VERSION = eval $VERSION;

use parent 'Alien::Base';

1;

__END__

=head1 NAME

Alien::SFML - Alien library for SFML

=head1 SYNOPSIS

  use strict;
  
  use warnings;
  
  use Module::Build;
  
  use Alien::SFML;
  
  # Retrieve the Alien::SFML configuration:
  
  my $alien = Alien::SFML->new;
  
  # Create the build script:
  
  my $builder = Module::Build->new(
  
  	module_name => 'My::SFML::Wrapper',
  
  	extra_compiler_flags => $alien->cflags(),
  
  	extra_linker_flags => $alien->libs(),
  
  	configure_requires => {
  
  		'Alien::SFML' => 0,
  
  	}, );
  
  $builder->create_build_script;

=head1 DESCRIPTION

Alien::SFML provides a CPAN distribution for installing SFML. In other
words, it installs SFML in a non-system folder and provides you with
the details necessary to include in and link to your C/XS code.

If you actually want to be able to use SFML from your code, see the SFML module
which should install this for you.

=head1 AUTHOR

Jake Bott, E<lt>jake.anq@gmail.comE<gt>

=head1 BUGS

Please report bugs related to installing SFML here:

https://github.com/jakeanq/perl-alien-sfml/issues

Note that this is not for bugs in the SFML module or the SFML library.  For those,
see the module and library homepages:

https://github.com/jakeanq/perl-sfml/

http://www.sfml-dev.org/

Note that I do not maintain SFML itself, only Alien::SFML and the XS/perl bindings
for it, under the SFML module.

=head1 COPYRIGHT

 ############################
 # Copyright 2013 Jake Bott #
 #=>----------------------<=#
 #   All Rights Reserved.   #
 #   Part of Alien::SFML.   #
 #=>----------------------<=#
 #   See the LICENCE file   #
 ############################

=cut
