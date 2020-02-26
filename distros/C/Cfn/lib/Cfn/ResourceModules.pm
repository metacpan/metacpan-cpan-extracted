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
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::ResourceModules - Load Cfn resource classes

=head1 SYNOPSIS

  use Cfn::ResourceModules;

  my $perl_class = Cfn::ResourceModules::load('AWS::EC2::Instance');
  my $ec2_instance_object = $perl_class->new(...);

  my @supported_modules = Cfn::ResourceModules::list;

=head1 DESCRIPTION

This module is designed to load Perl modules that respresent CloudFormation resources.

It exposes functions for knowing what resources are available on the system (what CloudFormation
resource types can be loaded) and making them available to your programs. It doesn't export 
anything into the callers namespace.

=head1 FUNCTIONS

=head2 list

Returns an array of CloudFormation resource types present on the system that can be passed to C<load>

=head2 load($resource)

When passed a CloudFormation resource type (f.ex. C<AWS::EC2::SecurityGroup>) it loads into memory the 
Perl modules that will later let the program instance objects of that type. Note that the Perl class 
for the resource type will get returned (Cfn resource objects are in the C<Cfn::Resource> 
namespace), so you will get strings of the form C<Cfn::Resource::AWS::EC2::SecurityGroup>.

=head1 AUTHOR

    Jose Luis Martinez
    CAPSiDE
    jlmartinez@capside.com

=head1 COPYRIGHT and LICENSE

Copyright (c) 2013 by CAPSiDE
This code is distributed under the Apache 2 License. The full text of the 
license can be found in the LICENSE file included with this module.

=cut
