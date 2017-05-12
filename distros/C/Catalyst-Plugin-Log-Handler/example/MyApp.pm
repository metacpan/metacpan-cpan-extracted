package MyApp;

# A sample Catalyst application
# See also Catalyst::Manual::Intro

use strict;
use warnings;

# Include Log::Handler here and Catalyst will use
# Catalyst::Plugin::Log::Handler for logging.
#
# Warning:  If you use ConfigLoader, please include it in this list *before*
# Log::Handler.
use Catalyst qw(
    -Debug Log::Handler
);

our $VERSION = '0.01';

#
# Configure the application 
#
__PACKAGE__->config(
  name => 'MyApp',
  'Log::Handler' => {
      filename => '/var/log/myapp.log',
      fileopen => 1,
      mode     => 'append',
      newline  => 1,
  },
);

#
# Start the application
#
__PACKAGE__->setup;

sub begin : Private {
    my ($self, $c) = @_;

    $c->log->debug('This useful debugging message was brought to you by Log::Handler.');
}

1;
