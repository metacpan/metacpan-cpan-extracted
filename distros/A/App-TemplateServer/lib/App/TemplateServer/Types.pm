package App::TemplateServer::Types;
use Moose::Util::TypeConstraints;

subtype 'Port'
  => as 'Num',
  => where { $_ > 1024 && $_ < 65536 };

subtype 'Page',
  => as 'Object',
  => where { $_->does('App::TemplateServer::Page') };

subtype 'Provider',
  => as 'Object',
  => where {$_->does('App::TemplateServer::Provider') };

use MooseX::Getopt;
MooseX::Getopt::OptionTypeMap->add_option_type_to_map(
    'Port' => '=i'
);

1;
