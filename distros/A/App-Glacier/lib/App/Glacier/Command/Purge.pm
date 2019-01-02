package App::Glacier::Command::Purge;

use strict;
use warnings;
use App::Glacier::Command::ListVault;
use parent qw(App::Glacier::Command::ListVault);
use App::Glacier::Core;

=head1 NAME

glacier purge - remove all archive from the vault

=head1 SYNOPSIS

B<glacier purge>
[B<-fi>]
[B<--force>]    
[B<--interactive>]    
I<VAULT>

=head1 DESCRIPTION

Removes all archives from the vault.

=head1 OPTIONS

=over 4

=item B<-f>, B<--force>

Remove all without asking.

=item B<-i>, B<--interactive>

Ask for confirmation before proceeding.  This is the default.

=back
    
=head1 SEE ALSO

B<glacier>(1).    
    
=cut

sub new {
    my ($class, $argref, %opts) = @_;
    my $self = $class->SUPER::new(
	$argref,
	optmap => {
	    'interactive|i' => 'interactive',
	    'force|f' => sub { $_[0]->{_options}{interactive} = 0 }
	},
	%opts);
    $self->{_options}{interactive} //= 1;
    $self
}	
    
sub run {
    my $self = shift;

    $self->abend(EX_USAGE, "exactly one argument expected")
	unless $self->command_line == 1;
    my $vault_name = ($self->command_line)[0];
    my $dir = $self->directory($vault_name);
    if ($self->{_options}{interactive}) {
	unless ($self->getyn("delete all files in $vault_name")) {
	    $self->error("cancelled");
	    return;
	}
    }
    my $error = 0;
    $dir->foreach(sub {
	my ($file, $info) = @_;
	my $ver = 1;
	foreach my $arch (@{$info}) {
	    $self->debug(1, "deleting $file;$ver");
	    return if $self->dry_run;
	    $self->glacier->Delete_archive($vault_name, $arch->{ArchiveId});
	    if ($self->glacier->lasterr) {
		$self->error(EX_FAILURE, "can't remove file \"$file;$ver\":",
			     $self->glacier->last_error_message);
		$error++;
	    } else {
		$dir->delete_version($file, $ver);
	    }
	}
		  });
    exit(EX_UNAVAILABLE) if $error;
}

1;
