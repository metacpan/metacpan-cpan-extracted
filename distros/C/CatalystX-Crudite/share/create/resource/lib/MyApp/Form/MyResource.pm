package <% dist_module %>::Form::<% resource_name %>;
use HTML::FormHandler::Moose;
extends 'CatalystX::Crudite::Form::Base';
has '+item_class'  => (default => '<% resource_name %>');
has_field 'name'   => (type    => 'Text', required => 1);
has_field 'submit' => (type    => 'Submit');
1;
