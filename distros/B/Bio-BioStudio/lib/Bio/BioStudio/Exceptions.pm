#
# BioStudio exceptions
#

=head1 NAME

Bio::BioStudio::Exceptions

=head1 VERSION

Version 5.00

=head1 DESCRIPTION

=head1 AUTHOR

Sarah Richardson <SMRichardson@lbl.gov>

=cut

package Bio::BioStudio::Exceptions;

use strict;
use warnings;

our $VERSION = 2.10;

use Exception::Class
(

  "Bio::BioStudio::Exception::PreserveExsistingFeature" =>
  {
    description => 'Inserting a new feature would destroy an existing feature'
  },
  "Bio::BioStudio::Exception::PreserveUniqueNames" =>
  {
    description => 'Name of new feature already assigned to existing feature'
  },
  "Bio::BioStudio::Exception::DeleteFeature" =>
  {
    description => 'Failed to delete feature from database'
  },
  "Bio::BioStudio::Exception::AddFeature" =>
  {
    description => 'Failed to add feature to database'
  },
);

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, BioStudio developers
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* The names of Johns Hopkins, the Joint Genome Institute, the Joint BioEnergy 
Institute, the Lawrence Berkeley National Laboratory, the Department of Energy, 
and the BioStudio developers may not be used to endorse or promote products 
derived from this software without specific prior written permission.

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