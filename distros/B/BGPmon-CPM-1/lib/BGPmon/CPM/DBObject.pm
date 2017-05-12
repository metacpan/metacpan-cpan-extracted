package BGPmon::CPM::DBObject;

use BGPmon::CPM::DB;
use base qw(Rose::DB::Object);
sub init_db { BGPmon::CPM::DB->new }

our $VERSION = '1.03';

1;

