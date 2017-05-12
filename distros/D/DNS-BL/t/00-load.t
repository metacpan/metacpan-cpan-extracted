# 00-load.t - Very basic testing of our classes. Test their ability to
# be use()d, and its POD documentation.

# $Id: 00-load.t,v 1.4 2004/12/21 21:17:38 lem Exp $

use Test::More;

my @modules = qw/
  DNS::BL
  DNS::BL::Entry
  DNS::BL::cmds
  DNS::BL::cmds::add
  DNS::BL::cmds::print
  DNS::BL::cmds::punch
  DNS::BL::cmds::delete
  DNS::BL::cmds::connect
  DNS::BL::cmds::connect::db
  DNS::BL::cmds::connect::dbi
	/;

my @paths = ();

plan tests => 2 * scalar @modules;

use_ok($_) for @modules;

my $checker = 0;

eval { require Test::Pod;
     Test::Pod::import();
       $checker = 1; };

for my $m (@modules)
{
    my $p = $m . ".pm";
    $p =~ s!::!/!g;
    push @paths, $INC{$p};
}

END { unlink "./out.$$" };

SKIP: {
    skip "Test::Pod is not available on this host", scalar @paths
	unless $checker;
    pod_file_ok($_) for @paths;
}

__END__

$Log: 00-load.t,v $
Revision 1.4  2004/12/21 21:17:38  lem
Added boilerplate DBI connector.

Revision 1.3  2004/10/13 13:54:18  lem
Functional punch()

Revision 1.2  2004/10/11 21:16:34  lem
Basic db and commands added

Revision 1.1.1.1  2004/10/08 15:08:32  lem
Initial import

