package App::Glacier::Command::CreateVault;

use strict;
use warnings;
use App::Glacier::Core;
use parent qw(App::Glacier::Command);
use App::Glacier::HttpCatch;

=head1 NAME

glacier mkvault - create a Glacier vault

=head1 SYNOPSIS

B<glacier mkvault> I<NAME>

=head1 DESCRIPTION

Creates a vault with the given I<NAME>.

=head1 SEE ALSO

B<glacier>(1).    
    
=cut    

sub run {
    my $self = shift;

    $self->abend(EX_USAGE, "only one argument expected")
	unless $self->command_line == 1;
    my $vault_name = ($self->command_line)[0];
    $self->glacier->Create_vault($vault_name);
    if ($self->glacier->lasterr) {
	$self->abend(EX_FAILURE, "can't create: ",
		     $self->glacier->last_error_message);
    }
}

1;

