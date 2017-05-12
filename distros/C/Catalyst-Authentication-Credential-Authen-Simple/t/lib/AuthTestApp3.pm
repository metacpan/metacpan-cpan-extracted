package AuthTestApp3;

use Catalyst qw/Authentication/;

__PACKAGE__->config->{'Plugin::Authentication'} = {
  'realms' => {
    'default' => {
      'store' => {
        'class' => 'Minimal',
        'users' => {
          bob => { name => "Bob Smith" },
          john => { name => "John Smith" }
	}
      },
      'credential' => {
        'class' => 'Authen::Simple',
        'authen' => [
          {
            'class' => 'Stub'
          },
          {
            'class' => 'OnlyOne',
            'args' => {
              'pass' => 'uniquepass'
            }
          }
        ],
      }
    }
  }
};

__PACKAGE__->setup();
