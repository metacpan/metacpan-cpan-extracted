package CCfnX::CloudFormationDeployer {
	use Moose::Role;
	use Paws;
	use JSON;

	requires 'origin';
	has region  => (is => 'rw', isa => 'Str', required => 1, lazy => 1, default => sub { $_[0]->origin->params->region });

	with 'CCfnX::DeployerResourceTypeHandler' => {
		resource_type_prefixes=> [ 'AWS' ]
	};

	has cfn => (is => 'ro',
		isa => 'Paws::CloudFormation',
		lazy => 1,
		default => sub {
			Paws->service('CloudFormation',
				region => $_[0]->region,
			)
		}
	);

	before undeploy => sub {
		my $self = shift;

		eval {
			$self->cfn->DeleteStack(StackName => $self->name);
		};
		if ($@){
			warn "CloudFormation threw an error trying to delete the stack: $@\n\nPlease review that the stack was correctly deleted, because we're going to deregister it";
		}

		my $start_time = time();
		print "Undeploying stack\n";

		# WaitForStack has a problem: when a stack disappears, the API will return an Error: Stack doesn't exist and die
		#  Tried to look at other API calls to detect if a stack doesn't exist anymore...
		my $result;
		eval {
			$result = $self->WaitForStack;
		};

		my $end_time = time();
		my $elapsed_time = $end_time - $start_time;
		if (not defined $result) {
			print "Stack undeployed\n";
			print "Undeployed in $elapsed_time seconds.\n";
		} else {
			die "Stack wasn't completely deleted. Now in state: " . $result->StackStatus;
		}
	};

	before redeploy => sub {
		my $self = shift;

		$self->get_from_mongo;
		$self->deploy_to_cloudformation;
	};

	before deploy => sub {
		my $self = shift;

		unless (defined $self->origin->params->{onlysnapshot} and $self->origin->params->onlysnapshot) {
			$self->deploy_to_cloudformation;
		}
	};

	sub deploy_to_cloudformation {
		my $self = shift;
		my $result;
		my $origin = $self->origin;

		$origin->addResource('ForceUpdate', 'AWS::IAM::User') if ($ENV{CLOUDDEPLOY_FORCE_UPDATE});

		my $parameters_for_cfn = [];
		foreach my $atto ($origin->params->meta->get_all_attributes) {
			my $att = $atto->name;
			if ($origin->params->meta->find_attribute_by_name($att)->does('CCfnX::Meta::Attribute::Trait::StackParameter')) {
				my $val = $origin->params->$att;
				$val = '' if (not defined $val);
				push @$parameters_for_cfn, { ParameterKey => $att, ParameterValue => $val };
			}
		}

		my $cfn_method = $origin->params->update ? 'UpdateStack' : 'CreateStack';

		$result = $self->cfn->$cfn_method(StackName => $self->name,
			Capabilities => [ 'CAPABILITY_IAM' ],
			TemplateBody => $origin->as_json,
			Parameters => $parameters_for_cfn,
		);

		my $start_time = time();
		print "Polling cfn for stack status\n";

		$result = $self->WaitForStack;

		my $end_time = time();
		my $elapsed_time = $end_time - $start_time;
		if ($result->StackStatus eq 'CREATE_COMPLETE' or $result->StackStatus eq 'UPDATE_COMPLETE') {
			print "Stack Complete\n";
			print "Deployed in $elapsed_time seconds.\n";
			$self->outputs($self->get_stack_outputs);
		} else {
			die "Can't continue: Stack status is: " . $result->StackStatus ;
		}
	}

	sub get_stack_outputs {
		my $self = shift;
		my $result  = $self->cfn->DescribeStacks(StackName => $self->name);
		my $outputs =  $result->Stacks->[0]->Outputs;
		my $mappings = $self->origin->output_mappings;
		return if (not $outputs);

		# Get outputs from cloudfront
		my $out = {};
		foreach my $output (@$outputs) {
			my $real_key = $mappings->{$output->OutputKey};
			if ($real_key) {
				$out->{$real_key} = $output->OutputValue;
			} else {
				$out->{$output->OutputKey} = $output->OutputValue;
			}
		}

		my $origin = $self->origin;
		foreach my $atto ($origin->meta->get_all_attributes) {
			my $att = $atto->name;
			if ($origin->meta->find_attribute_by_name($att)->does('CCfnX::Meta::Attribute::Trait::PostOutput')) {
				my $stack_res = $self->cfn->DescribeStackResources(PhysicalResourceId => $out->{$att});
				my ($resource) = grep { $_->PhysicalResourceId eq $out->{$att} } @{ $stack_res->StackResources };
				my $params = {
					StackName => $self->name,
					LogicalResourceId => $resource->LogicalResourceId
				};
				my $res = $self->cfn->DescribeStackResource(%$params);
				$out->{ $att } = from_json($res->StackResourceDetail->Metadata);
			}
		}

		return $out;
	}

	sub WaitForStack {
		my $self = shift;
		my $stackname = $self->name;
		my $result = $self->cfn->DescribeStacks(StackName => $stackname);
		my $stack_status = $result->Stacks->[0]->StackStatus;
		print "Stack Status: $stack_status\n";

		while ($stack_status =~ m/IN_PROGRESS$/){
			$result = $self->cfn->DescribeStacks(StackName => $stackname);
			$stack_status = $result->Stacks->[0]->StackStatus;
			print "Stack Status: $stack_status\n";
			sleep 15;
		}
		return $result->Stacks->[0];
	}

    sub assert_stack_version_ok {
      my $self = shift;
      my $cfn = Cfn->from_json($self->cfn->GetTemplate(StackName => $self->name)->TemplateBody);

      die "No stack version found in deployment class. 'stack_version' statement is required!\n" unless ($self->origin->can('StackVersion'));

      if ($cfn->MetadataItem('StackVersion')) {
        if ($self->origin->StackVersion->Value < $cfn->MetadataItem('StackVersion')->Value) {
          die "Your stack looks outdated! Are you using a version that is older than what is deployed to production?\nHas someone deployed a new version while you were working?\n";
        }

        if ($self->origin->StackVersion->Value == $cfn->MetadataItem('StackVersion')->Value) {
          die "You're almost done! But have not updated stack_version. Increase the version number and try again.\n";
        }

        my $recommended = $cfn->MetadataItem('StackVersion')->Value + 1;

        if ($self->origin->StackVersion->Value > $recommended) {
          die "Ooops! stack_version is too ahead in the future. You should be using: " . $recommended  . "\n";  
        }
      }
      else {
        die "Ooops! stack_version is too ahead in the future. You should be using: 1\n" if ($self->origin->StackVersion->Value != 1);  
      }
    }

    sub reset_stack_version {
      my $self = shift;

      if ($self->origin->can('StackVersion')) {
        $self->origin->meta->remove_attribute('StackVersion');
        delete $self->origin->Metadata->{StackVersion};
      }
    }
}

1;

