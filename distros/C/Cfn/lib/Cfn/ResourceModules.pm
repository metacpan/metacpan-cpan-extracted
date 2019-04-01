package Cfn::ResourceModules;

  sub list {
    require Module::Find;
    my @list = Module::Find::findallmod Cfn::Resource;
    # strip off the Cfn::Resource
    @list = map { $_ =~ s/^Cfn::Resource:://; $_ } @list;
    return @list;
  }

  use Module::Runtime qw//;
  sub load {
    my $type = shift;
    my $cfn_resource_class = "Cfn::Resource::$type";
    my $retval = Module::Runtime::require_module($cfn_resource_class);
    die "Couldn't load $cfn_resource_class" if (not $retval);
    return $cfn_resource_class;
  }

1;
