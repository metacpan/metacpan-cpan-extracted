package CCfnX::DeployerResourceTypeHandler {

	use MooseX::Role::Parameterized;

	parameter resource_type_prefixes => (
		is=>'ro',
		isa=>'ArrayRef[Str]'
	);

	role {
		my $parameters = shift;

		my $resource_type_prefixes = $parameters->resource_type_prefixes;

		method 'can_handle_stack' => sub {
			my ($self,$stack_resources) = @_;

			my $can_handle_stack_result = 1;
      while(my ($resource_name,$resource) = each(%$stack_resources)){
        if(not $self->can_handle_resource($resource)) {
					$can_handle_stack_result = 0;
					last;
				}
      }

			return $can_handle_stack_result;
		};

		method 'can_handle_resource' => sub {
			my ($self,$resource) = @_;

			my $can_handle_resource_result = 0;

			for my $resource_type_prefix (@{$resource_type_prefixes}) {
				if($resource->Type =~ /^${resource_type_prefix}/) {
					$can_handle_resource_result = 1;
					last;
				}
			}

			return $can_handle_resource_result;
		};

	};
}

return 1;

=head1 NAME

CCfnX::DeployerResourceTypeHandler

=head1 DESCRIPTION

This role is to be applied to Deployers as a security mechanism to prevent deployers from trying to deploy resources they cannot
handle. While they may fail immediately, they can cause difficult to debug and repair half-complete states.

The philosophy is that a Deployer should get to act on a Stack if it can deploy all of its resources.

Remember that a deployer does not need to deploy itself the resources it handles, but can delegate to other deployers if needed. 
This role exists as a bridge between the old way of doing deployers and the new C<DeploymentEngine> that will dispatch resources to
deployment engines. Thus, the deployment engine deployer will handle of type of resources except for AWS CloudFormation resources
which are still handled by the C<CloudFormationDeployer> until the C<CloudFormationDeployer> is transformed to a C<DeploymentEngine> C<Engine>.

=head1 USAGE

	package SomeSystemDeployer {
		use Moose;

		with 'CCfnX::DeployerResourceTypeHandler' => {
			resource_type_prefixes => [
				'Monitoring',
				'Azure'
			]
		};

		before 'deploy' => sub {
			#do something
		};
	}

=head1 PARAMETERS

=head2 resource_type_prefixes 

Defines what type of resources this deployer can handle. The prefixes of the package names of the resources it can handle.
For example, if it can handle AWS::* and Azure::* resources, the prefixes would be [ 'AWS', 'Azure' ].

=head1 METHODS

=head2 can_handle_stack 

For a given set of resources, this method returns whether this deployer can handle all resources from this stack.
A resource is an object that extends C<Cfn::Resource>.

=head3 arguments

=head4 stack_resources

An ArrayRef of C<Cfn:Resource>

=head2 can_handle_resource

For a given resource, this method returns whether this deployer can handle it.
A resource is an object that extends C<Cfn::Resource>.

=head3 arguments

=head4 resource

A C<Cfn:Resource>

