package App::TemplateServer::Page;
use Moose::Role;
use App::TemplateServer::Types;

# if /$obj->matches/ is true, then this page will be rendered
has 'match_regex' => (
    is       => 'ro',
    isa      => 'RegexpRef',
    required => 1,
);

has 'provider' => (
    is       => 'ro',
    isa      => 'Provider',
    required => 1,
);

requires 'render';

1;
