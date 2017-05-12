use strict;
use warnings;

use Test::More;

# FILENAME: show_last_10.t
# CREATED: 08/13/14 03:51:50 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Show last 10 releases

use App::cpanoutdated::fresh;
my $instance = App::cpanoutdated::fresh->new( developer => 1, );

my $scroll = $instance->_mk_scroll;
my $i      = 0;
while ( $i++ < 10 and my $result = $instance->_get_next($scroll) ) {
  diag sprintf "%s\@%s\n", $result->{name}, $result->{cpan};
}
pass("Executed without err");
done_testing;

