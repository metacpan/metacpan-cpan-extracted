package CGI::Application::Demo::Basic::Faculty;

# Note:
#	o tab = 4 spaces || die
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	Home page: http://savage.net.au/index.html

use strict;
use warnings;

use base 'CGI::Application::Demo::Basic::Base';

our $VERSION = '1.06';

# --------------------------------------------------

__PACKAGE__ -> table('faculty');
__PACKAGE__ -> columns(All => qw/faculty_id faculty_name/);
__PACKAGE__	-> sequence('faculty_seq') if (__PACKAGE__ -> db_vendor !~ /(?:MYSQL|SQLITE)/);

# --------------------------------------------------

1;
