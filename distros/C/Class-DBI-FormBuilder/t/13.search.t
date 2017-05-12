
use strict;
use warnings;

use Test::More;
use Test::Exception;

if ( ! DBD::SQLite2->require ) 
{
    plan skip_all => "Couldn't load DBD::SQLite2";
}

plan tests => 9;


use Class::DBI::FormBuilder::DBI::Test; # also includes Bar

$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'name=Dave&_submitted=1';

my $submitted_data = { street => undef,
                       name   => 'Dave',
                       town   => undef,
                       #id     => undef,
                       toys    => undef,
                       job => undef,
                       search_opt_order_by => undef,
                       search_opt_cmp => '=',
                       };
                       
                       
my $data = { street => 'NiceStreet',
             name   => 'Dave',
             town   => 'Trumpton',
             toys    => undef,
             };              

my $form = Person->search_form; # as_form;

is_deeply( scalar $form->field, $submitted_data );

my $iter;
lives_ok { $iter = Person->search_from_form( $form ) } 'search_from_form';
isa_ok( $iter, 'Class::DBI::Iterator' );

is( $iter->count, 19 ); # 21 Daves - 1 DaveBaird, - 1 modified in 06

my $first = $iter->next;
isa_ok( $first, 'Class::DBI' );

my @obj;
lives_ok { @obj = Person->search_from_form( $form ) } 'search_from_form';
isa_ok( $obj[0], 'Class::DBI' );
is( scalar( @obj ), 19 );

my %obj_data;
foreach my $object ( @obj )
{
    $obj_data{ $object->id } = { map { $_ => $object->$_ || undef } keys %$data };
}

# these were created in 01
my %expected;
foreach my $id ( 1..21 )
{
    $expected{ $id } = {%$data};
}

delete $expected{1};  # DaveBaird   - 02
delete $expected{5};  # Brian       - 06

is_deeply( \%obj_data, \%expected );






