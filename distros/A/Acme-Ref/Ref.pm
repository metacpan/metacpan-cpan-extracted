package Acme::Ref;

use strict;
use warnings;
use base 'Exporter';

our @EXPORT_OK = ( 'deref' );

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('Acme::Ref', $VERSION);

sub deref {
    my $str = shift;
    unless ($str) { return }
    $str =~ m/^(.*)\(0x(.*)\)$/;
    my ($cls,$ptr) = ($1,$2);
    $ptr = hex($ptr);
    _deref($ptr);
}

1;
__END__

=head1 NAME

Acme::Ref - unstringify a reference

=head1 SYNOPSIS

  use Acme::Ref qw/deref/;
  my $h = { yomomma => q!so fat! };
  print deref("$h")->{yomomma};

=head1 DESCRIPTION

  Allows Jaap to do twisted things.

  http://zoidberg.sf.net/

=head1 SEE ALSO

  man perlguts

=head1 AUTHOR

Raoul Zwart, E<lt>rlzwart@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Raoul Zwart

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
