package Alien::Build::Plugin::Core::FFI;

use strict;
use warnings;
use Alien::Build::Plugin;

# ABSTRACT: Core FFI plugin
our $VERSION = '0.55'; # VERSION


sub init
{
  my($self, $meta) = @_;

  $meta->default_hook(
    $_ => sub {},
  ) for qw( build_ffi gather_ffi );

  $meta->prop->{destdir_ffi_filter} = '^dynamic';

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Plugin::Core::FFI - Core FFI plugin

=head1 VERSION

version 0.55

=head1 SYNOPSIS

 use alienfile;
 # already loaded

=head1 DESCRIPTION

This plugin helps make the build_ffi work.  You should not
need to interact with it directly.

=head1 SEE ALSO

L<Alien::Build>, L<Alien::Base::ModuleBuild>

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Diab Jerius (DJERIUS)

Roy Storey

Ilya Pavlov

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
