use strict;
use warnings;
package App::AppSpec::Spec;

our $VERSION = '0.005'; # VERSION

use base 'Exporter';
our @EXPORT_OK = qw/ $SPEC /;

our $SPEC;

# START INLINE
$SPEC = {
  'appspec' => {
    'version' => '0.001'
  },
  'class' => 'App::AppSpec',
  'description' => 'This script is a collection of tools for authors of L<App::Spec> command line
scripts.

  # generate completion
  % appspec completion --bash path/to/spec.yaml
  # generate pod
  % appspec pod path/to/spec.yaml
  # validate your spec file
  % appspec validate path/to/spec.yaml
  # generate a new App::Spec app skeleton
  % appspec new --class App::foo --name foo --with-subcommands
',
  'markup' => 'pod',
  'name' => 'appspec',
  'options' => [],
  'subcommands' => {
    'completion' => {
      'description' => 'This command takes a spec file and outputs the corresponding
shell script for tab completion.
',
      'op' => 'cmd_completion',
      'options' => [
        'name=s --name of the program (optional, override the value from the spec)',
        'zsh --for zsh',
        'bash --for bash'
      ],
      'parameters' => [
        '+spec_file= +file --Path to the spec file (use \'-\' for standard input)'
      ],
      'summary' => 'Generate completion for a specified spec file'
    },
    'new' => {
      'description' => 'This command creates a skeleton for a new app.
It will create a directory for your app and write a skeleton
spec file.

Example:

  appspec new --name myprogram --class App::MyProgram App-MyProgram
',
      'op' => 'cmd_new',
      'options' => [
        '+name|n=s --The (file) name of the app',
        '+class|c=s --The main class name for your app implementation',
        'overwrite|o --Overwrite existing dist directory',
        'with-subcommands|s --Create an app with subcommands'
      ],
      'parameters' => [
        'path=s --Path to the distribution directory (default is \'Dist-Name\' in current directory)'
      ],
      'summary' => 'Create new app'
    },
    'pod' => {
      'description' => 'This command takes a spec file and outputs the generated pod
documentation.
',
      'op' => 'generate_pod',
      'parameters' => [
        '+spec_file= +file --Path to the spec file (use \'-\' for standard input)'
      ],
      'summary' => 'Generate pod'
    },
    'validate' => {
      'description' => 'This command takes a spec file and validates it against the current
L<App::Spec> schema.
',
      'op' => 'cmd_validate',
      'options' => [
        'color|C --output colorized'
      ],
      'parameters' => [
        '+spec_file= +file --Path to the spec file (use \'-\' for standard input)'
      ],
      'summary' => 'Validate spec file'
    }
  },
  'title' => 'Utilities for spec files for App::Spec cli apps'
};
# END INLINE

1;
