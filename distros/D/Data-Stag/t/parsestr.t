use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 6;
}
use Data::Stag;
use strict;


eval {
    require "XML/Parser/PerlSAX.pm";
};
if ($@) {
    for (1..6) {
        skip("XML::Parser::PerlSAX not installed",1);
    }
    exit 0;
}

my $h = Data::Stag->makehandler(
                                a => sub { my ($self,$stag) = @_;
                                           $stag->set_foo("bar");$stag});
my $stag = Data::Stag->parse(-str=>'(data(a (foo "x")(fee "y")))',
                             -handler=>$h);
print $stag->xml;
ok($stag->getnode_a->get_foo eq 'bar');

my $mixed = <<EOM;
<yo>
 <paragraph id="1">
    example of <bold>mixed</bold>content
  </paragraph>
</yo>
EOM

print $mixed;
my $p = Data::Stag->from('xmlstr', $mixed);
#my $p = Data::Stag->parse(-str=>$mixed,
#			  -format=>'xml');
print $p->sxpr;
my $para = $p->get('paragraph');
ok ($para->kids == 4);
my @text = $para->get('.');
ok("@text" eq "example of content");
my $id = $para->find_id;
ok($id == 1);
my $mixed2 = <<EOM;
<yo>
 <paragraph id="1">
    TEXT
  </paragraph>
</yo>
EOM
print $p->sxpr;
print $mixed2;
$p = Data::Stag->from('xmlstr', $mixed2);
#my $p = Data::Stag->parse(-str=>$mixed,
#			  -format=>'xml');
print $p->sxpr;
ok($p->get('paragraph/@/id') == 1);
ok($p->get('paragraph/.') eq 'TEXT');
