package Alien::Build::Plugin::Core::Setup;

use strict;
use warnings;
use Alien::Build::Plugin;
use Config;

# ABSTRACT: Core setup plugin
our $VERSION = '0.41'; # VERSION

sub init
{
  my($self, $meta) = @_;
  
  if($^O eq 'MSWin32' && $Config{ccname} eq 'cl')
  {
    $meta->prop->{platform}->{compiler_type} = 'microsoft';
  }
  else
  {
    $meta->prop->{platform}->{compiler_type} = 'unix';
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Plugin::Core::Setup - Core setup plugin

=head1 VERSION

version 0.41

=head1 SYNOPSIS

 use alienfile;
 # already loaded

=head1 DESCRIPTION

This plugin does some core setup for you.

=head1 SEE ALSO

L<Alien::Build>, L<Alien::Base::ModuleBuild>

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Diab Jerius (DJERIUS)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
