package CCfnX::ImportBase {
  use Moose;
  use CCfnX::VirtualDeployment;
  use CCfnX::PersistentDeployment;
  use Data::Printer;

  sub get_deployer {
    my $self = shift;

    my @roles;
    if ($ENV{ CLOUDDEPLOY_PERSIST }) {
      push @roles, 'CCfnX::PersistentDeployment';
    } else {
      warn 'To persist the stack to the database, please activate ENV CLOUDDEPLOY_PERSIST';
    }

    my $new_class = Moose::Util::with_traits('CCfnX::VirtualDeployment', @roles);

    my $deployer = $new_class->new(origin => $self);

    print "These are your outputs\n";
    p $deployer->outputs;

    return $deployer;
  }
}

1;
