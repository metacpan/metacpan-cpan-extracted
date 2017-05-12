#
# BioStudio functions for Git interaction
#

=head1 NAME

Bio::BioStudio::Git - Git interaction

=head1 VERSION

Version 1.06

=head1 DESCRIPTION

BioStudio functions for GFF3

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>.

=cut

package Bio::BioStudio::Git;

require Exporter;
use URI::Escape;
use Carp;

use base qw(Exporter);

use strict;
use warnings;

our $VERSION = '1.06';

our @EXPORT_OK = qw(
  create_repo
  commit
  rollback
  $VERSION
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);
 
=head1 Functions

=head2 create_repo

=cut

sub create_repo
{

}

=head2 commit

=cut

sub commit
{

}

=head2 rollback

=cut

sub rollback
{

}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, BioStudio developers
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* Neither the name of the Johns Hopkins nor the names of the developers may be
used to endorse or promote products derived from this software without specific
prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE DEVELOPERS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
