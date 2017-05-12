package CommitBit::Action::CreateProjectMember;
use warnings;
use strict;

use base qw/Jifty::Action::Record::Create/;

sub record_class {'CommitBit::Model::ProjectMember'}

sub arguments {
    my $self = shift;
    my $args = $self->SUPER::arguments();
    delete $args->{'person'}{valid_values}; 
    $args->{'person'}{'render_as'} = 'Text';
    $args->{'person'}{'hints'} = _('Please enter an email address. CommitBit will take care of the rest');
    
    return $args;
}

1;
