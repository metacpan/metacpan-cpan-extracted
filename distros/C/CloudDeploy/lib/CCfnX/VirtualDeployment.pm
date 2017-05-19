package CCfnX::VirtualDeployment {
  use Moose;

  has origin  => (is => 'rw' );
  has region  => (is => 'rw', isa => 'Str', required => 1, lazy => 1, default => sub { $_[0]->origin->params->region });
  has name    => (is => 'rw', isa => 'Str', required => 1, lazy => 1, default => sub { $_[0]->origin->params->name });
  has type    => (is => 'rw', isa => 'Str', required => 1, lazy => 1, default => sub { $_[0]->origin->meta->name });
  has account => (is => 'rw', isa => 'Str', required => 1, lazy => 1, default => sub { $ENV{CPSD_AWS_ACCOUNT} });
  has outputs => (is => 'rw', isa => 'HashRef', lazy => 1, default => sub { shift->get_outputs_from_origin });
  has params  => (is => 'rw', isa => 'HashRef', lazy => 1, default => sub { shift->get_params_from_origin });

  sub get_params_from_origin {
    my $params = $_[0]->origin->params;
    my @attrs  = $params->meta->get_all_attributes;
    my %p = map { my $att_name = $_->name; ($att_name => $params->$att_name) }
            grep {
                  substr($_->name,0,1) ne '_'
              and $_->name ne 'ARGV'
              and $_->name ne 'extra_argv'
              and $_->name ne 'help_flag'
              and $_->name ne 'usage'
            }
            @attrs;
    return \%p;
  }

  sub get_outputs_from_origin {
    my $params = $_[0]->origin->params;
    my @attrs  = $params->meta->get_all_attributes;
    my %p = map { my $att_name = $_->name; ($att_name => $params->$att_name) }
            grep {
              $_->does('NoGetopt')
            }
            grep {
                  $_->name ne 'ARGV'
              and $_->name ne 'extra_argv'
              and $_->name ne 'help_flag'
              and $_->name ne 'usage'
            }
            @attrs;
    return \%p;
  }

  sub output {
    my ($self, $name) = @_;
    die "Output $name not found in " . $self->name if (not defined $self->outputs->{ $name });
    return $self->outputs->{ $name };
  }

  sub redeploy { }

  sub undeploy { }

  sub deploy { }
}

1;
