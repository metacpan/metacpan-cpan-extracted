package App::Office::Contacts::Donations::Controller::Organization;

use parent 'App::Office::Contacts::Donations::Controller';
use strict;
use warnings;

use App::Office::Contacts::Controller::Exporter::Organization qw/-all/;

# We don't use Moose because we isa CGI::Application.

our $VERSION = '1.10';

# -----------------------------------------------

1;
