package CloudDeploy::Utils {
  use Moose;
  use Moose::Exporter;

  Moose::Exporter->setup_import_methods(
      as_is     => [ 'load_deployment_class', 'load_class' ],
  );

  use Module::Runtime qw/require_module/;
  use Moose::Util qw/find_meta/;

  sub _params_class {
    my $module = shift;

    my $params_constraint = $module->meta->find_attribute_by_name('params')->type_constraint;
    if (not defined $params_constraint) {
      die "$module is not a valid CloudDeploy classs. It doesn't specify an isa for it's params attribute";
    }
    my $params_class = $params_constraint->name;
  }

  sub load_class {
    my $class = shift;

    # get class name from a path or a class name
    $class = _get_name($class);
    require_module($class);

    return { class => $class, params_class => _params_class($class) } if (find_meta($class));
    
    #TODO: other path-to-class loading techiques
    # strip the last part of a class, and try to load that
    #($class) = ($class =~ m/\:\:(.*)$/);
    #return $class;

    die "Couldn't load class $class";

  }

  #TODO: this method will be unused as soon as the first level command-lines are deleted. Please delete it
  #      when that condition becomes true
  sub load_deployment_class {
    my $class = shift;
    return load_class($class)->{class};
  }

  # Tries to convert a filename into a ClassName and load it
  # If it's already a class name, don't touch
  sub _get_name {
    my $module = shift;
    # FS paths to ::
    $module =~ s/\//::/g;
    # 
    $module =~ s/\.pm//g;
    return $module;
  }

}

1;
