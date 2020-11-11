package Ansible::Util::Roles::Constants;
$Ansible::Util::Roles::Constants::VERSION = '0.001';
use Modern::Perl;
use Moose::Role;

=head1 NAME

Ansible::Util::Roles::Constants

=head1 VERSION

version 0.001

=cut

use constant {
	ARGS_VAULT_PASS_FILE      => '--vault-password-file',
	CACHE_NS_VARS             => 'ansible-vars',
	CACHE_KEY                 => 'default',
	CMD_ANSIBLE_PLAYBOOK      => 'ansible-playbook',
	DEFAULT_CACHE_EXPIRE_SECS => 60 * 10, # 10 mins
};

1;
