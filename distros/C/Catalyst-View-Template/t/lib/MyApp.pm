use strict; use warnings;

package MyApp;

use Catalyst;

__PACKAGE__->config(
	name                  => 'MyApp',
	default_message       => 'hi',
	default_view          => 'PkgConfig',
	'View::AppConfig' => {
		template_ext => '.tt',
		PRE_CHOMP    => 1,
		POST_CHOMP   => 1,
	},
);

__PACKAGE__->setup;
