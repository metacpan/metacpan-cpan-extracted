package BioSAILs::Command;

use v5.10;
use strict;
our $VERSION = '1.0';


use MooseX::App 1.39 qw(Color);

app_strict 0;

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=encoding utf-8

=head1 NAME

BioSAILs::Command - Command line wrapper for the BioX-Workflow-Command and HPC-Runner-Command libraries.

=head1 SYNOPSIS

BioSAILs stands for Bioinformatic Standardized Analysis Information Layers, and it incorporates the following completely decoupled systems,

    1. BioX – Which is the analysis templating system.
    2. HPC-Runner – The workflow submission system.
    3. Bioinformatics software management system based on BioConda.

Please check out the website BioSAILs :  https://biosails.abudhabi.nyu.edu/biosails

=head1 DESCRIPTION

BioSAILs has been developed by a small Core Bioinformatics team that is focused on managing and analyzing substantial amounts of high throughput sequencing data.

For our in house workflows please see the Workflows menu at : https://biosails.abudhabi.nyu.edu/biosails/

Edit any workflow using our in house workflow editor by clicking 'View/Edit'.


=head2 Get Help

For additional help please see visit the Forums https://biosails.abudhabi.nyu.edu/biosails/index.php/forums

For issues please run

    biosails version

And attach the output to any issues or concerns on https://github.com/biosails/BioSAILs-Command/issues.

=head1 AUTHOR

Jillian Rowe E<lt>jillian.e.rowe@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2018- Jillian Rowe

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
