package Command::Template;

# vim: ts=3 sts=3 sw=3 et ai :

use 5.024000;
use warnings;
use experimental qw< signatures >;
no warnings qw< experimental::signatures >;
{ our $VERSION = '0.001' }

use Exporter 'import';
our @EXPORT_OK = qw< command_runner command_template cr ct >;

use Command::Template::Instance;
use Command::Template::Runner;

sub cr (@cmd) { Command::Template::Runner->new(ct(@cmd)) }
sub ct (@cmd) { Command::Template::Instance->new(@cmd) }

{
   no strict 'refs';
   *command_runner = *cr;
   *command_template = *ct;
}

1;
