=head1 NAME

Bio::BioStudio::DB

=head1 VERSION

Version 2.10

=head1 DESCRIPTION

BioStudio functions for database interaction.

=head1 AUTHOR

Sarah Richardson <SMRichardson@lbl.gov>.

=cut

package Bio::BioStudio::DB;
require Exporter;

use Bio::BioStudio::ConfigData;
use Bio::DB::SeqFeature::Store;
use DBI;
use English qw(-no_match_vars);
use Carp;

use base qw(Exporter);

use strict;
use warnings;

our $VERSION = '2.10';

our @EXPORT_OK = qw(
  fetch_database
  drop_database
);
our %EXPORT_TAGS = (BS => \@EXPORT_OK);

my $engine = Bio::BioStudio::ConfigData->config('db_engine');
my $module = "Bio::BioStudio::DB::$engine";
(my $require_name = $module . ".pm") =~ s{::}{/}xg;
my $req = eval
{
  require $require_name;
};
if (! $req)
{
   croak("Can't load $require_name");
}
  
=head1 DATABASE FUNCTIONS

=head2 fetch_database

Fetches a Bio::DB::SeqFeature::Store interface for a database containing
the annotations of the argument chromosome. An optional write flag sets whether
or not the interface will support adding, deleting, or modifying features.

  Returns: A L<Bio::DB::SeqFeature::Store> object.

=cut

sub fetch_database
{
  my ($chromosome, $refresh) = @_;
  $refresh = $refresh || 0;
  my $fetch = $module . "::_fetch_database";
  my $subfetch = \&$fetch;
  my $db = &$subfetch($chromosome, $refresh);

}

=head2 drop_database

=cut

sub drop_database
{
  my ($chromosome) = @_;
  my $drop = $module . "::_drop_database";
  my $subdrop = \&$drop;
  &$subdrop($chromosome);
  return 1;
}

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
