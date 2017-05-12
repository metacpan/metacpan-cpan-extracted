package App::Services::Remote::Container;
{
  $App::Services::Remote::Container::VERSION = '0.002';
}

use Moose;
use Bread::Board;

extends 'Bread::Board::Container';

sub BUILD {
	$_[0]->build_container;
}


has +name => (
	is      => 'rw',
	isa     => 'Str',
	default => 'plib_ssh_svc',
);

sub build_container {
	my $s = shift;

	return container $s => as {

		service 'ssh_conn' => (
			class        => 'App::Services::Services::SSH_Conn',
			dependencies => {
				log_svc   => depends_on('log_svc'),
				host_name => 'host_name',
			}
		);

		service 'ssh_exec' => (
			class        => 'App::Services::Services::SSH_Exec',
			dependencies => {
				log_svc  => depends_on('log_svc'),
				ssh_conn => depends_on('ssh_conn'),
			}
		);
	}
}

no Moose;

1;

__END__

=pod

=head1 NAME

App::Services::Remote::Container

=head1 VERSION

version 0.002

=head1 AUTHOR

Sean Blanton <sean@blanton.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Sean Blanton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
