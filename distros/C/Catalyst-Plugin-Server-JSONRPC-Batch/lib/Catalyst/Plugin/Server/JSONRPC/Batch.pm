package Catalyst::Plugin::Server::JSONRPC::Batch;

use strict;
use warnings;

use Class::Load ();
use HTTP::Body ();


our $VERSION = '0.02';

our $Method = 'system.handle_batch';


BEGIN {
	my $class = 'JSON::RPC::Common::Procedure::Call';

	Class::Load::load_class($class);

	my $meta = $class->meta;

	$meta->make_mutable();
	$meta->add_around_method_modifier(
		'inflate',
		sub {
			my ($meth, $class, @args) = @_;

			if (@args == 1 && ref($args[0]) eq 'ARRAY') {
				return $class->new_from_data(
					jsonrpc => '2.0',
					id      => scalar(time()),
					method  => $Catalyst::Plugin::Server::JSONRPC::Batch::Method,
					params  => $args[0]
				);
			}
			else {
				return $meth->($class, @args);
			}
		}
	);
	$meta->make_immutable();
}


sub setup_engine {
	my $app = shift();

	$app->server->jsonrpc->add_private_method(
		$Method => sub {
			my ($c, @args) = @_;

			my $config = $c->server->jsonrpc->config;
			my $req    = $c->req;
			my $res    = $c->res;
			my $stash  = $c->stash;
			my $parser = $req->jsonrpc->_jsonrpc_parser;
			my @results;

			# HACK: Store values.
			my $body = $req->_body;
			my $path = $config->path;

			foreach (map { $parser->encode($_) } @{$req->args}) {
				$config->path('');
				$stash->{jsonrpc_generated} = 0;
				$req->_body(HTTP::Body->new($req->content_type, length($_)));
				$req->_body->add($_);
				$res->body('');

				$c->prepare_action();
				$c->dispatch();
				$stash->{current_view_instance}->process($c)
						unless $stash->{jsonrpc_generated};

				push(@results, $res->body);
			}

			# Restore values.
			$req->_body($body);
			$config->path($path);

			my $result = '[' . join(',', @results) . ']';

			$res->content_length(length($result));
			$res->body($result);
		}
	);

	$app->next::method(@_);
}


1;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Server::JSONRPC::Batch - batch requests implementation for
Catalyst JSON-RPC server plugin.

=head1 SYNOPSIS

    use Catalyst qw/
        Server
        Server::JSONRPC
        Server::JSONRPC::Batch
    /;

=head1 DESCRIPTION

Catalyst::Plugin::Server::JSONRPC::Batch implements batch JSON-RPC requests as
its described in specification version 2.0.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::Server::JSONRPC>.

L<JSON-RPC 2.0 Specification|http://www.jsonrpc.org/specification>.

=head1 SUPPORT

=over 4

=item Repository

L<http://github.com/dionys/catalyst-plugin-server-jsonrpc-batch>

=item Bug tracker

L<http://github.com/dionys/catalyst-plugin-server-jsonrpc-batch/issues>

=back

=head1 AUTHOR

Denis Ibaev, C<dionys@cpan.org>.

=head1 THANKS TO

Ivan Fomichev (IFOMICHEV), Sergey Romanov.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Denis Ibaev.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See L<http://dev.perl.org/licenses/> for more information.

=cut
