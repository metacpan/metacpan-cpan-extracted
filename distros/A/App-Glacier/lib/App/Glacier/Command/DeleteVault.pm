package App::Glacier::Command::DeleteVault;

use strict;
use warnings;
use App::Glacier::Core;
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

    $self->abend(EX_USAGE, "one argument expected")
	unless $self->command_line == 1;
    my $vault_name = ($self->command_line)[0];
    $self->glacier->Delete_vault($vault_name);
    if ($self->glacier->lasterr) {
	$self->abend(EX_FAILURE, "can't delete: ",
		     $self->glacier->last_error_message);
    } else {
	my $dir = $self->directory($vault_name);
	$dir->drop
    }
}

1;
