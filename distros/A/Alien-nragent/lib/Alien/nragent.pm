package Alien::nragent;

use strict;
use warnings;
use 5.008001;
use FFI::Platypus::DL;
use List::Util qw( first );
use base qw( Alien::Base );

# ABSTRACT: Download and install the NewRelic agent
our $VERSION = '0.06'; # VERSION


{
  my $fn = first { /newrelic-common/ } __PACKAGE__->dynamic_libs;
  my $handle = dlopen($fn, RTLD_NOW | RTLD_GLOBAL )
    or die "error dlopen $fn @{[ dlerror ]}";
}

sub dynamic_libs
{
  my($class) = @_;
  
  if($class->install_type('system'))
  {
    return @{ $class->runtime_prop->{my_lib} };
  }
  else
  {
    return $class->SUPER::dynamic_libs;
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::nragent - Download and install the NewRelic agent

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 use FFI::Platypus;
 use Alien::nragent;
 
 my $ffi = FFI::Platypus->new;
 $ffi->lib(Alien::nragent->dynamic_libs);
 ...

=head1 DESCRIPTION

This Alien dist installs and makes available the NewRelic agent library.

If the NewRelic agent library is already in your library path, then they will be used.

If the NewRelic agent library is installed in C</opt/newrelic>, then that will be used.

Otherwise the NewRelic agent library will be downloaded, and installed.

=head1 CAVEATS

=head2 Platform Limitations

The SDK binaries provided by New Relic only work on Linux x86_64.  The binaries are labeled
as a "beta".  The most recent version available (as of this writing) is dated July 1, 2019.
However, I believe the New Relic Agent SDK is no longer being actively developed, and you
are encouraged to consider the New Relic C SDK instead.

I have found that previous versions worked on Ubuntu Precise and Xenial, but not Cent OS 7.
Your mileage my vary.

=head2 Not Fork Safe!

Bad things will happen if you call newrelic_init before forking.  So don't do that.

=head1 SEE ALSO

=over 4

=item L<NewRelic::Agent::FFI::Procedural>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
