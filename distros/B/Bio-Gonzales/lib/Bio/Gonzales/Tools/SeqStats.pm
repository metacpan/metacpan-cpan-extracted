#Copyright (c) 2010 Joachim Bargsten <code at bargsten dot org>. All rights reserved.

package Bio::Gonzales::Tools::SeqStats;

use warnings;
use strict;
use Carp;

use Mouse;

use Bio::Gonzales::Util::Text qw/character_count/;
use MouseX::Foreign 'Bio::Root::Root';

with 'Bio::Gonzales::Role::BioPerl::Constructor';

use 5.010;
our $VERSION = '0.0546'; # VERSION

has seq => ( is => 'rw' );

sub count_residues {
    my ($self) = @_;
    
    return character_count($self->seq->seq);
}

1;

