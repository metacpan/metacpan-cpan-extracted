package App::Glacier::Command::DeleteFile;

use strict;
use warnings;
use App::Glacier::Command::ListVault;
use parent qw(App::Glacier::Command::ListVault);
use App::Glacier::Core;
use App::Glacier::HttpCatch;

=head1 NAME

glacier rm - remove file from a vault

=head1 SYNOPSIS

B<glacier rm>
I<VAULT>
I<FILE>...    

=head1 DESCRIPTION

Removes listed files from the vault.  I<FILE> can contain version numbers
(I<file;num>), to select particular version of the file.  Globbing patterns
are also allowed. See B<glacier>(1), section B<On file versioning>, for the
information about file versioning scheme.   

=head1 SEE ALSO

B<glacier>(1).    
    
=cut

sub run {
    my $self = shift;
    my @argv = $self->command_line;
    $self->abend(EX_USAGE, "at least two arguments expected")
	unless @argv >= 2;
    my $vault_name = shift @argv;
    my $dir = $self->directory($vault_name);
    my $error = 0;
    my $success = 0;
    foreach my $ref (@{$self->get_vault_inventory($vault_name, @argv)}) {
	$self->glacier->Delete_archive($vault_name, $ref->{ArchiveId});
	if ($self->glacier->lasterr) {
	    $self->error(EX_FAILURE,
		  "can't remove file \"$ref->{FileName};$ref->FileVersion}\":",
			 $self->glacier->last_error_message);
	    $error++;
	} else {
	    $dir->delete_version($ref->{FileName}, $ref->{FileVersion});
	    $success++;
	}
    }
    exit(EX_TEMPFAIL) if $error;
}
	
1;
    
