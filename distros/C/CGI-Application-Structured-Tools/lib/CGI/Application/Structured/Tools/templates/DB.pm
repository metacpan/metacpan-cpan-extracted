package <tmpl_var main_module>::DB;

use warnings;
use strict;
use base 'DBIx::Class::Schema::Loader';

=head1 NAME

Template DBIC schema for CGI::Application::Structured apps.

=cut 


 __PACKAGE__->loader_options(debug => 1);

