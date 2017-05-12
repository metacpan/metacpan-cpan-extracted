use strictures 1;
use Test::More;
use File::Spec;
use App::MyPerl;

delete @ENV{qw(MYPERL_CONFIG MYPERL_HOME)};

sub is_dir {
  my ($type, @rest) = @_;
  &is(App::MyPerl->new->${\"${type}_dir"}->name, @rest);
}

is_dir(project_config => '.myperl', 'project config defaults to .myperl');

{
  local $ENV{MYPERL_CONFIG} = 'monkey';
  is_dir(project_config => 'monkey', 'MYPERL_CONFIG sets project config');
}

{
  local $ENV{HOME} = 'banana';
  is_dir(
    global_config => File::Spec->catdir('banana', '.myperl'),
    'global config defaults to $HOME/.muperl'
  );
}

{
  local $ENV{MYPERL_HOME} = 'fingertrap';
  is_dir(global_config => 'fingertrap', 'MYPERL_HOME sets global config');
}

done_testing;
