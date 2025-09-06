package ClarID::Tools;

use strict;
use warnings;
use File::ShareDir::ProjectDistDir qw(dist_dir);

# This turns ClarID::Tools into an App::Cmd “app”
use App::Cmd::Setup -app;

# Central version for your entire CLI suite
our $VERSION = '0.02';

# Share dir
our $share_dir = dist_dir('ClarID-Tools');

1;

=pod

=head1 NAME

ClarID::Tools - ClarID: A Human-Readable and Compact Identifier Specification for Biomedical Metadata Integration
  
=head1 DESCRIPTION

We recommend using the included L<command-line interface|https://metacpan.org/dist/ClarID-Tools/view/bin/clarid-tools>.

For a better description, please read the following documentation:

=over

=item General:

L<https://cnag-biomedical-informatics.github.io/clarid-tools>

=item Command-Line Interface:

L<https://github.com/CNAG-Biomedical-Informatics/clarid-tools#readme>

=back

=head1 CITATION

The author requests that any published work that utilizes C<ClarID-Tools> includes a cite to the following reference:

Manuel Rueda and Ivo G. Gut (2025). ClarID: A Human-Readable and Compact Identifier Specification for Biomedical Metadata Integration. I<Submitted>.


=head1 AUTHOR

Written by Manuel Rueda, PhD. Info about CNAG can be found at L<https://www.cnag.eu>.

=head1 COPYRIGHT

This PERL file is copyrighted. See the LICENSE file included in this distribution.

