package CCfnX::Deployment {
  use Moose;
  use Module::Runtime qw/use_module/;

  has origin  => (is => 'rw', isa => 'CCfn');
  has name    => (is => 'rw', isa => 'Str', required => 1, lazy => 1, default => sub { $_[0]->origin->params->name });
  has type    => (
    is => 'rw', 
    isa => 'Str', 
    required => 1, 
    lazy => 1,
    clearer => 'clear_type',
    default => sub { $_[0]->origin->meta->name }
  );
  has account => (is => 'rw', isa => 'Str', required => 1, lazy => 1, default => sub { (defined $_[0]->origin)?$_[0]->origin->params->account:$ENV{CPSD_AWS_ACCOUNT} });
  has outputs => (is => 'rw', isa => 'HashRef');
  has params  => (is => 'rw', isa => 'HashRef', lazy => 1, default => sub { $_[0]->get_params_from_origin });

  sub get_params_from_origin {
    my $params = $_[0]->origin->params;
    my @attrs  = map { $_->name } $params->meta->get_all_attributes;
    my %p = map { $_ => $params->$_ } grep {
          $_ ne 'ARGV'
      and $_ ne 'extra_argv'
      and $_ ne 'help_flag'
      and $_ ne 'usage'
    } @attrs;
    return \%p;
  }

  sub output {
    my ($self, $name) = @_;
    die "Output $name not found in " . $self->name if (not defined $self->outputs or not defined $self->outputs->{ $name });
    return $self->outputs->{ $name };
  }

  sub undeploy { }

  sub redeploy { }

  sub deploy { }

  sub new_with_roles {
    my ($class, $params, @roles) = @_;
    use_module($_) for (@roles);
    my $new_class = Moose::Util::with_traits('CCfnX::Deployment', @roles);
    my $dep = $new_class->new(%$params);
    return $dep;
  }
}

1;
