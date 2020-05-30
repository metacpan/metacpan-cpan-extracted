package Storage::Common;

use Moo::Role;

requires 'connect_info';

# override in consuming class, if need be
sub should_skip {}

1;
