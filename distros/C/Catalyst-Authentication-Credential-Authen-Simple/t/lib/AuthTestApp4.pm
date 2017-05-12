package AuthTestApp4;

use TestLogger;
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
            'class' => 'Logger'
          },
        ],
      }
    }
  }
};

__PACKAGE__->log( TestLogger->new );

__PACKAGE__->setup();
