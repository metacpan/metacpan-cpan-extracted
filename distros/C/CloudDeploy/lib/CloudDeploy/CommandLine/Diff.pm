package CloudDeploy::CommandLine::Diff {
  use Cfn;
  use Cfn::Diff;
  use Paws;
  use File::Slurp;
  use MooseX::App;  
  use CloudDeploy::Utils;
  use CloudDeploy::DeploymentCollection;
  use JSON;
  use String::Diff;
  use Term::ANSIColor qw/:constants/;
  use Scalar::Util;

  parameter left => (
    is            => 'rw',
    isa           => 'Str',
    documentation => q[cfn:<REGION>:<NAME>|deploy:<NAME>|file:<JSON_FILE>],
    required      => 1,
  ); 

  parameter right => (
    is            => 'rw',
    isa           => 'Str',
    documentation => q[cfn:<REGION>:<NAME>|deploy:<NAME>|file:<JSON_FILE>],
    required      => 1,
  );

  option pretty => (
    is            => 'ro',
    isa           => 'Bool',
    documentation => 'Pretty print the changes in JSON',
    default       => 0
  );

  has _left_cfn => (
    is => 'ro',
    isa => 'Cfn',
    lazy => 1,
    default => sub { shift->_get_cfn('left') }
  );

  has _right_cfn => (
    is => 'ro',
    isa => 'Cfn',
    lazy => 1,
    default => sub { shift->_get_cfn('right') }
  );


  sub _get_cfn {
    my ($self, $side) = @_;
    if (my ($region, $stack_name) = ($self->$side =~ m/^cfn\:(.*?)\:(.*)$/)) {
      return Cfn->from_json(Paws->service('CloudFormation', region => $region)->GetTemplate(StackName => $stack_name)->TemplateBody);
    } elsif (my ($file) = ($self->$side =~ m/^file\:(.*)$/)) {
      # read_file needs to be in scalar context to return all lines as one string
      return Cfn->from_json(scalar(read_file($file))); 
    } elsif (my ($deploy_name) = ($self->$side =~ m/^deploy\:(.*)$/)) {
      my $deployments = CloudDeploy::DeploymentCollection->new(account => $ENV{'CPSD_AWS_ACCOUNT'});
      my $deploy      = $deployments->get_deployment($deploy_name);

      my $module = load_class($deploy->type);

      my @attached =
        map { $_->name }
        grep { $_->does('Attached') }
        $module->{params_class}->meta->get_all_attributes;

      my $params = $deploy->params;
      delete $params->{ $_ } for (@attached);

      my $merged_params = $module->{params_class}->new_with_options(%{ $params }, argv => $self->extra_argv);
      my $obj = $module->{class}->new(params => $merged_params);
      return Cfn->from_hashref($obj->as_hashref);
    } else {
      die "Unknown format for side $side";
    }
  }
 
  has differences => (is => 'ro', isa => 'Cfn::Diff', lazy => 1, default => sub {
    my $self = shift;
    return Cfn::Diff->new(left => $self->_left_cfn, right => $self->_right_cfn);
  });

  sub _is_dynamic {
    my ($self, $element) = @_;
    return (blessed($element) and $element->isa('CCfnX::DynamicValue'));
  }

  sub run {
    my $self = shift;

    printf "Comparing %s to %s\n", $self->left, $self->right;
    $self->differences->diff;

    if (@{ $self->differences->changes } == 0) {
      print "No changes detected\n";
      return;
    }

    foreach my $change (@{ $self->differences->changes }) {
      my $compare_from = $change->from;
      my $compare_to   = $change->to;

      # We'll always compare the textual form that cloudformation would recieve, since the diff will return
      # changes in properties that have DynamicValues in them, that can render the result equal or different

      $compare_from = $self->_print_element($change->from, $self->_left_cfn);
      $compare_to   = $self->_print_element($change->to, $self->_right_cfn);

      printf "%s %s\n", $change->path, $change->change;
      if (defined $compare_from and defined $compare_to and $compare_from ne $compare_to) {
        my $diff = String::Diff::diff($compare_from, $compare_to,
          remove_open => RED . DARK . BOLD,
          remove_close => CLEAR,
          append_open => GREEN . DARK . BOLD,
          append_close => CLEAR,
        );
        printf "\tfrom: %s\n", $diff->[0];
        printf "\t  to: %s\n", $diff->[1];
      } elsif (not defined $compare_from) {
        printf "\tfrom:\n";
        printf "\t  to: %s%s%s\n", GREEN . DARK . BOLD, $compare_to, CLEAR;
      } elsif (not defined $compare_to) {
        printf "\tfrom: %s%s%s\n", RED . DARK . BOLD, $compare_from, CLEAR;
        printf "\t  to:\n";
      }
      printf "----------------------\n";
    }
  }

  sub _print_element {
    my ($self, $element, $c) = @_;

    if (blessed($element)) {
      if ($element->isa('Cfn::Value::Primitive')){
        return $element->Value;
      } elsif ($element->isa('CCfnX::DynamicValue')) {
        # A dynamic value has to be converted to a normal value, and then be "printed"
        return $self->_print_element($element->to_value($c), $c);
      } else {
        if ($self->pretty) {
          return JSON->new->canonical->pretty->encode($element->as_hashref($c));
        } else {
          return JSON->new->canonical->encode($element->as_hashref($c));
        }
      }
    } else {
      if (ref($element) eq 'HASH') {
        my %jsondocs;

        foreach my $key (keys(%{$element})) {
          my $value = $self->_print_element($element->{$key});

          if ($value =~ /^\{/) {
            $jsondocs{$key} = JSON->new->decode($value);
          }
          else {
            $jsondocs{$key} = $value;
          }
        }

        if ($self->pretty) {
          return JSON->new->canonical->pretty->encode(\%jsondocs);
        } else {
          return JSON->new->canonical->encode(\%jsondocs);
        }
      }
      else {
        return $element;
      }
    }
  }

}

1;
