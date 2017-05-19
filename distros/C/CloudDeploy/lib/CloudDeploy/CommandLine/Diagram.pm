package CloudDeploy::CommandLine::Diagram {
  use MooseX::App;  
  use CloudDeploy::Utils;

  parameter deploy_class => (is => 'ro', isa => 'Str', required => 1);

  sub run {
    my ($self) = @_;

    my $module = load_class($self->deploy_class);
    my $obj = $module->{class}->new(params => $module->{params_class}->new_with_options(argv => $self->extra_argv));

    print "digraph diagrama {\n";
    foreach my $r_name ($obj->ResourceList) {
      my $r = $obj->Resource($r_name);
      foreach my $dep (@{ $r->dependencies }){
        print "$r_name -> $dep;\n";
      }
    }
    print "}\n";
  }
}

1;
