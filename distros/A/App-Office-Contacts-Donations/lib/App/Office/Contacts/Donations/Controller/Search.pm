package App::Office::Contacts::Donations::Controller::Search;

use parent 'App::Office::Contacts::Donations::Controller';
use strict;
use warnings;

use App::Office::Contacts::Controller::Exporter::Search qw/-all/;

# We don't use Moose because we isa CGI::Application.

our $VERSION = '1.10';

# -----------------------------------------------

1;
