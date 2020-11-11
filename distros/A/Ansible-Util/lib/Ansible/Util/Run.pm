package Ansible::Util::Run;
$Ansible::Util::Run::VERSION = '0.001';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka 'method';
use Data::Printer alias => 'pdump';

=head1 NAME

Ansible::Util::Run

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  $run = Ansible::Util::Run->new;
  ( $stdout, $stderr, $exit ) = $run->ansiblePlaybook(playbook => $playbook);

  $run = Ansible::Util::Run->new(
      vaultPasswordFiles => ['secret1', 'secret2']
  );
  ( $stdout, $stderr, $exit ) = $run->ansiblePlaybook(playbook => $playbook);
    
=head1 DESCRIPTION

A thin wrapper around the Ansible CLI tools.
 
=cut

with 'Ansible::Util::Roles::Constants';

##############################################################################
# PUBLIC ATTRIBUTES
##############################################################################

=head1 ATTRIBUTES

=head2 vaultPasswordFiles

A list of vault-password-files to pass to the command line.

=over

=item type: ArrayRef[Str]

=item required: no

=back

=cut

with
  'Ansible::Util::Roles::Attr::VaultPasswordFiles',
  'Util::Medley::Roles::Attributes::Spawn';

##############################################################################
# PRIVATE_ATTRIBUTES
##############################################################################

##############################################################################
# CONSTRUCTOR
##############################################################################

##############################################################################
# PUBLIC METHODS
##############################################################################

=head1 METHODS

All methods confess on error unless otherwise specified.

=head2 ansiblePlaybook()

Invokes the ansible-playbook command with the specified args.

=head3 usage:

  ($stdout, $stderr, $exit) = 
    $run->ansiblePlaybook(playbook        => $file,
                          [extraArgs      => $aref],
                          [confessOnError => $bool],
                          [wantArrayRefs  => $bool]);

=head3 returns:

An array containing the stdout, stderr, and exit status from the 
ansible-playbook command.
                        
=head3 args:

=over

=item playbook

The name of the playbook file.

=over

=item type: Str

=item required: yes

=back

=back

=over

=item extraArgs

Any additional args you want to pass to the command line.

=over

=item type: ArrayRef[Str]

=item required: no

=back

=back

=over

=item confessOnError

If the command exits with an error, the call will simply confess with the
output from stderr.

=over

=item type: Bool

=item required: no

=item default: 1

=back

=back

=over

=item wantArrayRefs

The stdout and stderr are returned as array refs split across newlines.

=over

=item type: Bool

=item required: no

=item default: 0

=back

=back

=cut

method ansiblePlaybook (Str           :$playbook,
                        ArrayRef[Str] :$extraArgs,
                        Bool          :$confessOnError = 1,
                        Bool          :$wantArrayRefs = 0) {

	my @cmd;
	push @cmd, CMD_ANSIBLE_PLAYBOOK();
	push @cmd, $self->_getVaultPasswordArgs;
	push @cmd, @$extraArgs if $extraArgs;
	push @cmd, $playbook if $playbook;

    $self->Spawn->confessOnError($confessOnError);
    
	my ( $stdout, $stderr, $exit ) =
	  $self->Spawn->capture( cmd => \@cmd, wantArrayRefs => $wantArrayRefs);

	return ( $stdout, $stderr, $exit );
}

##############################################################################
# PRIVATE METHODS
##############################################################################

method _getVaultPasswordArgs {

	my @args;
	foreach my $file ( @{ $self->vaultPasswordFiles } ) {
		push @args, ARGS_VAULT_PASS_FILE(), $file;
	}

	return @args;
}

1;
