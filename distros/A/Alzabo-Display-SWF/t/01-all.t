######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Alzabo::Display::SWF qw(etc/my_conf.yml);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use Alzabo::Create::Schema;
use Alzabo::Create::ForeignKey;
use Alzabo::Config;
use File::Path;

Alzabo::Config::root_dir('./t');
eval { mkdir './t/schemas' or die "$!" };
if ( $@ and $@ !~ /File exists/ ) { die "mkdir: $@" }

$Alzabo::Display::SWF::cfg->{fdb_dir} = 'etc';

my $acs = Alzabo::Create::Schema->new(qw/ name foo_db rdbms MySQL /);
# FOO_T1
my $foo_t1 = $acs->make_table( name => 'foo_t1' );
my $id1 = $foo_t1->make_column( qw/ name id  type int  sequenced 1 / );
$foo_t1->add_primary_key($id1);
$foo_t1->make_column( qw/ name bar  type text  nullable 1/ );
# FOO_T2
my $foo_t2 = $acs->make_table( name => 'foo_t2' );
my $id2 = $foo_t2->make_column( qw/ name id  type int  sequenced 1 / );
$foo_t2->add_primary_key($id2);
my $foo_t1_id = $foo_t2->make_column( qw/ name foo_t1_id  type int/ );
$acs->add_relationship( table_from => $foo_t2,
                        table_to   => $foo_t1,
                        columns_from => $foo_t1_id,
                        columns_to   => $id1,
                        cardinality  => ['n', 1],
                        from_is_dependent => 1,
                        to_is_dependent => 0 );
$foo_t2->make_column( qw/ name bar  type text / );
my $foo_t2_id = $foo_t2->make_column( qw/ name foo_t2_id  type int / );
$acs->add_relationship( table_from => $foo_t2,
                        table_to   => $foo_t2,
                        columns_from => $foo_t2_id,
                        columns_to   => $id2,
                        cardinality  => ['n', 1],
                        from_is_dependent => 1,
                        to_is_dependent => 0 );
# FOO_T3
my $foo_t3 = $acs->make_table( name => 'foo_t3' );
my $id3 = $foo_t3->make_column( qw/ name id  type int  sequenced 1 / );
$foo_t3->add_primary_key($id3);
$foo_t1_id = $foo_t3->make_column( qw/ name foo_t1_id  type int/ );
$foo_t2_id = $foo_t3->make_column( qw/ name foo_t2_id  type int/ );
$acs->add_relationship( table_from => $foo_t3,
                        table_to   => $foo_t1,
                        columns_from => $foo_t1_id,
                        columns_to   => $id1,
                        cardinality  => ['n', 1],
                        from_is_dependent => 1,
                        to_is_dependent => 0 );
$acs->add_relationship( table_from => $foo_t3,
                        table_to   => $foo_t2,
                        columns_from => $foo_t2_id,
                        columns_to   => $id2,
                        cardinality  => ['n', 1],
                        from_is_dependent => 1,
                        to_is_dependent => 0 );
# FOO_T4
my $foo_t4 = $acs->make_table( name => 'foo_t4' );
my $id4 = $foo_t4->make_column( qw/ name id  type int  sequenced 1 / );
$foo_t4->add_primary_key($id4);
$foo_t4->make_column( qw/ name bar  type text / );
$foo_t4_id = $foo_t2->make_column( qw/ name foo_t4_id  type int/ );
$acs->add_relationship( table_from => $foo_t2,
                        table_to   => $foo_t4,
                        columns_from => $foo_t4_id,
                        columns_to   => $id4,
                        cardinality  => ['n', 1],
                        from_is_dependent => 1,
                        to_is_dependent => 0 );
$acs->save_to_file;

my $s = Alzabo::Display::SWF->create('foo_db');
if ( $s->isa( 'Alzabo::Display::SWF::Schema' ) ) { print "ok 2\n" }
else { print "not ok 2\n" }

if ( $s->save('./t/schemas/foo_db.swf') ) { print "ok 3\n" }
else { print "not ok 3\n" }

my ($x, $y) = $s->dim;
if ( $x < $y ) { print "ok 4\n" }
else { print "not ok 4\n" }

