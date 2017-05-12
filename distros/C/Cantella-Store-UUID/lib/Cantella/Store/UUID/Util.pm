package Cantella::Store::UUID::Util;

use strict;
use warnings;

use Sub::Exporter -setup => { exports => [ '_mkdirs' ] };

our $VERSION = '0.003003';

sub _mkdirs {
  my $dir = shift;
  my $levels = shift;

  --$levels;
  for my $node ( (0..9), qw(A B C D E F) ){
    my $subdir = $dir->subdir($node);
    if( -f $subdir ){
      die("Can't create dir '${subdir}': a file with a conflicting name exists");
    }
    if( ! $subdir->mkpath ){
      die("Can't create dir '${subdir}': $!");
    }

    _mkdirs($subdir, $levels) if $levels > 0;
  }
}

1;

__END__;

=head1 NAME

Cantella::Store::UUID::Util - Useful things that didn't belong in the objects

=head1 SUBROUTINES

=head2 _mkdirs $dir, $levels

Will recursively make a directory hioerarchy C<$levels> deep using
C<$dir> as the root. C<$dir> will not be created.

=head1 SEE ALSO

L<Cantella::Store::UUID>, L<Cantella::Store::UUID::File>

=head1 AUTHOR

Guillermo Roditi (groditi) E<lt>groditi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Guillermo Roditi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
