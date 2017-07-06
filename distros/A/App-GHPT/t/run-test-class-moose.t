use App::GHPT::Wrapper::Ourperl;

use Test::Class::Moose::CLI;

# We set this for git
local $ENV{EMAIL} = 'test@example.com';

Test::Class::Moose::CLI->new_with_options->run;
