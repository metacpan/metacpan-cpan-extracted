#
#   DBIx::XMLMessage no-dbh tests
#

print "1..2\n";

use strict;
use DBI;
use DBIx::XMLMessage;

# new
#
sub t1 { die @_; }
sub t2 { print STDERR @_; }

# Template string
my $tpl_str =<< "_EOT_";
<?xml version="1.0" encoding="UTF-8" ?>
<TEMPLATE NAME='A' TYPE='XML' VERSION='1.0' TABLE='A'>
  <KEY NAME='ID' DATATYPE='NUMERIC' PARENT_NAME='OBJECT_ID' />
  <COLUMN NAME='LoginId' EXPR='ID' DATATYPE='NUMERIC' />
</TEMPLATE>
_EOT_
my $msg = new DBIx::XMLMessage ('TemplateString' => $tpl_str,
        '_OnError' => \&t1, '_OnTrace' => \&t2 );
if ( $msg && defined $msg->{_OnError} && defined $msg->{_OnTrace}
        && defined $msg->{_Template} ) {
    print "ok 1\n";
} else {
    print "not ok 1\n";
}

# input_xml
#
my $msg_str =<< "_EOD2_";
<?xml version="1.0" encoding="UTF-8" ?>
<A>
  <LoginID>1</LoginID>
</A>
_EOD2_

my $msgtype = $msg->input_xml($msg_str);
if ( $msgtype eq 'A' ) {
    print "ok 2";
} else {
    print "not ok 2";
}