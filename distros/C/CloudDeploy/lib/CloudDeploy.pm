package CloudDeploy;

  our $VERSION = '1.06';

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

CloudDeploy - A toolkit for building and managing AWS CloudFormation stacks

=head1 DESCRIPTION

CloudDeploy is a toolkit to build and manage CloudFormation stacks. It has tools at various
levels:

Cfn.pm - A base class to build an object model of a cloudformation stack

CCfn.pm and CCfnX::Shortcuts - A DSL to develop cloudformation stacks

clouddeploy - a command line util to deploy and manage cloudformation stacks

imager - a command line util to build and manage EC2 AMIs

The CloudDeploy project was born in 2013 as an internal tool developed at CAPSiDE to help us manage 
all the cloudformation stacks for us and our customers. We built it generic enough to be
used outside of our organization, and are now opening it to the larger community.

This is a partial release of the tool that we have been developing (and using) daily, sadly
the documentention is still internal. You're free to tinker around and ask questions. In the meanwhile
we'll be working on properly converting our internal documentation to community-usable documentation, 
and getting the whole toolkit usable by the larger community. Your feedback is more than welcome.

=head1 AUTHOR

Jose Luis Martinez

=head1 CONTRIBUTORS

Sergi Pruneda, Miquel Ruiz, Luis Alberto Gimenez, Miquel Soriano, Hamilton Daniel Cesario,
Eleatzar Colomer, Oriol Soriano, Diego Fernandez, Roi Vazquez, Sergio Lopez, Loic Prieto, 
Enric Font, Joan Maldonado.

=head1 COPYRIGHT and LICENSE

Copyright (c) 2013 by CAPSiDE SL

This code is distributed under the Apache 2 License. The full text of the license can be 
found in the LICENSE file included with this module.

=cut
