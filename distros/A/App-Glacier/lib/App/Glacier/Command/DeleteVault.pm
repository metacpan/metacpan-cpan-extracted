package App::Glacier::Command::DeleteVault;

use strict;
use warnings;
use App::Glacier::Command;
use parent qw(App::Glacier::Command);
use App::Glacier::HttpCatch;

=head1 NAME

glacier rmvault - delete a Glacier vault

=head1 SYNOPSIS

B<glacier rmvault> I<NAME>

=head1 DESCRIPTION

Deletes the vault with the given I<NAME>.

=head1 SEE ALSO

B<glacier>(1).    
    
=cut    

sub run {
    my $self = shift;

    $self->abend(EX_USAGE, "one argument expected") unless $#_ == 0;
    my $vault_name = shift;
    $self->glacier_eval('delete_vault', $vault_name);
    if ($self->lasterr) {
	$self->abend(EX_FAILURE, "can't create: ", $self->last_error_message);
    } else {
	my $dir = $self->directory($vault_name);
	$dir->drop
    }
}

1;
