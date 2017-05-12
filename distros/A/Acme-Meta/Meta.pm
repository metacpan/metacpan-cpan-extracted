package Acme::Meta;

use 5.004;
use strict;

require Exporter;
use vars qw($VERSION);

BEGIN {
  *Meta::Meta:: = *main::Meta::;
  *Acme::Meta::Meta:: = *main::Meta::;
  $^W = 1;
}

$VERSION = '0.02';

1;
__END__

=head1 NAME

Acme::Meta - Enhances the Meta package

=head1 SYNOPSIS

  use Acme::Meta; # before using Meta

=head1 DESCRIPTION

Enhances the Meta package.

=head1 SEE ALSO

The Meta:: meta-package

=head1 AUTHOR

Nicholas Clark, E<lt>nick@ccl4.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003, 2006 by Nicholas Clark

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
