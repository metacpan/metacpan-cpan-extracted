package CogSampleAppSimple;
use base 'Cog::App';

use constant Name => 'CogSampleAppSimple';
use constant command_script => 'cog-sample-app-simple';
use constant webapp_class => 'CogSampleAppSimple::WebApp';
use constant config_file => 'cog-sample.yaml';
use constant DISTNAME => 'Cog';

package CogSampleAppSimple::WebApp;
use base 'Cog::WebApp';
use constant DISTNAME => 'Cog';

1;
