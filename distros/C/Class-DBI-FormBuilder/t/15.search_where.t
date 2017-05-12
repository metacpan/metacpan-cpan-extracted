

use strict;
use warnings;

use Test::More;
use Test::Exception;

if ( ! DBD::SQLite2->require ) 
{
    plan skip_all => "Couldn't load DBD::SQLite2";
}

if ( ! Class::DBI::AbstractSearch->require )
{
    plan skip_all => "Couldn't load Class::DBI::AbstractSearch";
}

plan tests => 9;


use Class::DBI::FormBuilder::DBI::Test; # also includes Bar

{
    package Class::DBI::FormBuilder::DBI::Test;
    use Class::DBI::AbstractSearch;
}

$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'name=Dave&name=Winston&town=&_submitted=1';

my $submitted_data = { street => undef,
                       name   => [ qw( Dave Winston ) ],
                       town   => '',
                       #id     => undef,
                       toys    => undef,
                       job => undef,
                       search_opt_order_by => undef,
                       search_opt_cmp => '=',
                       };
                       
                       
my $ddata = { street => 'NiceStreet',
              name   => 'Dave',
              town   => 'Trumpton',
              toys    => undef,
              };              
my $wdata = { street => 'DowningStreet',
              name   => 'Winston',
              town   => 'London',
              toys    => undef,
              };              

my $form = Person->search_form; 

#is_deeply( scalar $form->field, $submitted_data );

# this only captures the first item in lists
my $formdata = $form->field;
# so need this:
$formdata->{name} = [ $form->field( 'name' ) ];
is_deeply( $formdata, $submitted_data );


my $iter;
lives_ok { $iter = Person->search_where_from_form( $form ) } 'search_where_from_form';
isa_ok( $iter, 'Class::DBI::Iterator' );

is( $iter->count, 20 ); # 21 Daves - 1 DaveBaird, - 1 modified in 06, + 1 Winston

my $first = $iter->next;
isa_ok( $first, 'Class::DBI' );

my @obj;
lives_ok { @obj = Person->search_where_from_form( $form ) } 'search_where_from_form';
isa_ok( $obj[0], 'Class::DBI' );
is( scalar( @obj ), 20 );

my %obj_data;
foreach my $object ( @obj )
{
    $obj_data{ $object->id } = { map { $_ => $object->$_ || undef } keys %$ddata };
}

# these were created in 01
my %expected;
foreach my $id ( 1..21 )
{
    $expected{ $id } = {%$ddata};
}

delete $expected{1};  # DaveBaird   - 02
delete $expected{5};  # Brian       - 06

# Winston
$expected{25} = $wdata;

is_deeply( \%obj_data, \%expected );

#warn Dumper( \%obj_data );






