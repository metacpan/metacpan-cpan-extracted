package Bio::KBase::IDServer::Service;

use Data::Dumper;
use Moose;

extends 'RPC::Any::Server::JSONRPC::PSGI';

has 'instance_dispatch' => (is => 'ro', isa => 'HashRef');
has 'user_auth' => (is => 'ro', isa => 'UserAuth');
has 'valid_methods' => (is => 'ro', isa => 'HashRef', lazy => 1,
			builder => '_build_valid_methods');

our $CallContext;

our %return_counts = (
        'kbase_ids_to_external_ids' => 1,
        'external_ids_to_kbase_ids' => 1,
        'register_ids' => 1,
        'allocate_id_range' => 1,
        'register_allocated_ids' => 0,
);

sub _build_valid_methods
{
    my($self) = @_;
    my $methods = {
        'kbase_ids_to_external_ids' => 1,
        'external_ids_to_kbase_ids' => 1,
        'register_ids' => 1,
        'allocate_id_range' => 1,
        'register_allocated_ids' => 1,
    };
    return $methods;
}

sub call_method {
    my ($self, $data, $method_info) = @_;
    my ($module, $method) = @$method_info{qw(module method)};
    
    my $ctx = Bio::KBase::IDServer::ServiceContext->new(client_ip => $self->_plack_req->address);
    
    my $args = $data->{arguments};
    if (@$args == 1 && ref($args->[0]) eq 'HASH')
    {
	my $actual_args = $args->[0]->{args};
	my $token = $args->[0]->{auth_token};
	$data->{arguments} = $actual_args;
	
	
        # Service IDServerAPI does not require authentication.
	
    }
    
    my $new_isa = $self->get_package_isa($module);
    no strict 'refs';
    local @{"${module}::ISA"} = @$new_isa;
    local $CallContext = $ctx;
    my @result = $module->$method(@{ $data->{arguments} });
    my $result;
    if ($return_counts{$method} == 1)
    {
        $result = [[$result[0]]];
    }
    else
    {
        $result = \@result;
    }
    return $result;
}


sub get_method
{
    my ($self, $data) = @_;
    
    my $full_name = $data->{method};
    
    $full_name =~ /^(\S+)\.([^\.]+)$/;
    my ($package, $method) = ($1, $2);
    
    if (!$package || !$method) {
	$self->exception('NoSuchMethod',
			 "'$full_name' is not a valid method. It must"
			 . " contain a package name, followed by a period,"
			 . " followed by a method name.");
    }

    if (!$self->valid_methods->{$method})
    {
	$self->exception('NoSuchMethod',
			 "'$method' is not a valid method in service IDServerAPI.");
    }
	
    my $inst = $self->instance_dispatch->{$package};
    my $module;
    if ($inst)
    {
	$module = $inst;
    }
    else
    {
	$module = $self->get_module($package);
	if (!$module) {
	    $self->exception('NoSuchMethod',
			     "There is no method package named '$package'.");
	}
	
	Class::MOP::load_class($module);
    }
    
    if (!$module->can($method)) {
	$self->exception('NoSuchMethod',
			 "There is no method named '$method' in the"
			 . " '$package' package.");
    }
    
    return { module => $module, method => $method };
}

package Bio::KBase::IDServer::ServiceContext;

use strict;

=head1 NAME

Bio::KBase::IDServer::ServiceContext

head1 DESCRIPTION

A KB RPC context contains information about the invoker of this
service. If it is an authenticated service the authenticated user
record is available via $context->user. The client IP address
is available via $context->client_ip.

=cut

use base 'Class::Accessor';

__PACKAGE__->mk_accessors(qw(user client_ip));

sub new
{
    my($class, %opts) = @_;
    
    my $self = {
	%opts,
    };
    return bless $self, $class;
}

1;
