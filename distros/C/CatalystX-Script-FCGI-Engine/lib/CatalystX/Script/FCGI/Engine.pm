package CatalystX::Script::FCGI::Engine;
use Moose;
use FCGI::Engine;
use namespace::autoclean;

our $VERSION = '0.003';

extends 'Catalyst::Script::FastCGI';

has '+manager' => (
    default => 'FCGI::Engine::ProcManager',
);

sub _run_application {
    my $self = shift;
    my ($listen, $args) = $self->_application_args;
    Class::MOP::load_class($self->application_name);
    my @detach = delete($args->{detach}) ? ( detach => 1 ) : ();
    my @listen = $listen ? (listen => $listen, use_manager => 1) : ();
    $args->{nproc} ||= 5;
    delete($args->{pidfile}) unless $args->{pidfile};
    FCGI::Engine->new(
        handler_class => $self->application_name,
        handler_method => 'handle_request',
        pre_fork_init => sub {},
        handler_args_builder => sub {},
        @listen,
        @detach,
        %$args,
    )->run;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

CatalystX::Script::FCGI::Engine - FCGI::Engine script for Catalyst

=head1 SYNOPSIS

    package MyApp::Script::FastCGI;
    use Moose;
    
    extends 'CatalystX::Script::FCGI::Engine';
    
    no Moose;
    1;

=head1 DESCRIPTION

Replacement FastCGI script which overrides Catalyst's use of L<FCGI::ProcManager>
with L<FCGI::Engine>, and process management with L<FCGI::Engine::ProcManager>.

=head1 AUTHOR

Tomas Doran (t0m) C<< <bobtfish@bobtfish.net> >>.

=head1 COPYRIGHT & LICENSE

Copyright 2011 the above author(s).

This sofware is free software, and is licensed under the same terms as perl itself.

=cut

