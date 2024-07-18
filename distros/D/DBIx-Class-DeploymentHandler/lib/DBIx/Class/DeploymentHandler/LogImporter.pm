package DBIx::Class::DeploymentHandler::LogImporter;
$DBIx::Class::DeploymentHandler::LogImporter::VERSION = '0.002234';
use warnings;
use strict;

use parent 'Log::Contextual';

use DBIx::Class::DeploymentHandler::LogRouter;

{
   my $router;
   sub router { $router ||= DBIx::Class::DeploymentHandler::LogRouter->new }
}

1;
