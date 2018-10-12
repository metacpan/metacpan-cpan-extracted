package App::CpanfileSlipstop;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";

1;

__END__

=encoding utf-8

=head1 NAME

cpanfile-slipstop - write installed module versions back to cpanfile

=head1 SYNOPSIS

  # update moduels & write versions from cpanfile.snapshot to cpanfile
  > carton update
  > cpanfile-slipstop

  # write module versions as 'minimum'
  > cpanfile-slipstop --stopper=minimum

  # only see versions to write
  > cpanfile-slipstop --dry-run

  # remove current version specification from cpanfile
  > cpanfile-slipstop --remove

=head1 OPTIONS

  --stopper=identifier (default: exact)
      type of version constraint
          exact   : '== 1.00'
          minimum : '1.00' (same as >= 1.00)
          maximum : '<= 1.00'
  --dry-run
      do not save to cpanfile
  --with-core
      write core module versions
  --silent
      stop to output versions
  --cpanfile=path (default: ./cpanfile)
  --snapshot=path (default: ./cpanfile.snapshot)
      specify cpanfile and cpanfile.snapshot location
  --remove
      delete all version specifications from cpanfile
  -h, --help
      show this help

=head1 DESCRIPTION

C<cpanfile-slipstop> is a support tool for more definite and safety version bundling on L<cpanfile> and L<Carton>.

The C<carton install> command checks only to satisfy version specifications in cpanfile and C<local/>. Even if some module versions are updated in cpanfile.snapshot, the saved versions are not referred until you need to install it. This sometimes causes confusion and version discrepancy between development environment and production. This tool writes versions snapshot to cpanfile to fix module versions.

=head1 SEE ALSO

L<Carton>, L<Module::CPANfile>, L<CPAN::Meta::Requirements>

=head1 LICENSE

Copyright (C) pokutuna.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

pokutuna E<lt>popopopopokutuna@gmail.comE<gt>

=cut
