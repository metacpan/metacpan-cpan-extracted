package Alien::OpenSSL;

use strict;
use warnings;

our $VERSION = '0.09';

use parent 'Alien::Base';

1;

__END__

=head1 NAME

Alien::OpenSSL - Alien wrapper for OpenSSL

=head1 SYNOPSIS

  use strict;
  use warnings;

  use Module::Build;
  use Alien::OpenSSL;

  my $cflags = Alien::OpenSSL->cflags;
  my $ldflags = Alien::OpenSSL->libs;

  my $builder = Module::Build->new(
  	module_name => 'my_lib',
	extra_compiler_flags => $cflags,
	extra_linker_flags => $ldflags,
	configure_requires => {
		'Alien::OpenSSL => 0
		},
  );

  $builder->create_build_script;

=head1 ABSTRACT

Alien wrapper for OpenSSL

=head1 DESCRIPTION

This library provides an alien wrapper for OpenSSL.

=head1 SEE ALSO

OpenSSL(1), Crypt::OpenSSL::X509, Alien::Base

