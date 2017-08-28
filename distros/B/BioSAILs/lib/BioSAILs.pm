package BioSAILs;

use strict;
use 5.008_005;
our $VERSION = '0.02';

1;
__END__

=encoding utf-8

=head1 NAME

BioSAIL(s) - Standard(ized) Analysis Information Layers

=head1 SYNOPSIS

with 'BioSAILs::Utils::LoadConfigs';
with 'BioSAILs::Integrations::Github';
...
with 'BioSAILs::SomeOtherRole';

=head1 DESCRIPTION

BioSAILs is a set of roles for shared functionlity between
L<HPC::Runner::Command> and L<BioX::Workflow::Command>. It is not meant to be
used on its own (yet).

=head1 AUTHOR

Jillian Rowe E<lt>jillian.e.rowe@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2017- Jillian Rowe

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HPC::Runner::Command>
L<BioX::Workflow::Command>
L<https://snakemake.readthedocs.io/en/stable/>
L<http://bcbio-nextgen.readthedocs.io/en/latest/>
L<https://www.nextflow.io/>

=cut
