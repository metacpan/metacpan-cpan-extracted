package App::PassManager;
{
  $App::PassManager::VERSION = '1.113580';
}

use Moose;
extends 'MooseX::App::Cmd';

$ENV{ESCDELAY} = 0;

1;
