package Ansible::Util::Roles::Attr::VaultPasswordFiles;
$Ansible::Util::Roles::Attr::VaultPasswordFiles::VERSION = '0.001';
use Modern::Perl;
use Moose::Role;

=head1 NAME

Ansible::Util::Roles::VaultPasswordFiles

=head1 VERSION

version 0.001

=cut

has vaultPasswordFiles => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);


1;
