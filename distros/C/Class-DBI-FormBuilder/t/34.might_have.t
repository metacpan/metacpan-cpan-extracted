

use strict;
use warnings;

use Test::More;
use Test::Exception;

if ( ! DBD::SQLite2->require ) 
{
    plan skip_all => "Couldn't load DBD::SQLite2";
}

plan tests => 7;

use Class::DBI::FormBuilder::DBI::Test; 


$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'id=1&_submitted=1';

my $dbaird = Person->retrieve( 1 );

# id person jobtitle employer salary
my $jobdata = { person => $dbaird,
                jobtitle => 'Dogs Body',
                employer => 'Tyrant Joe',
                salary => 3,
                };
                         
Job->create( $jobdata );

for ( 2..10 )
{
    my %jd = %$jobdata; # copy
    $jd{person} = $_;
    $jd{jobtitle} .= " $_";
    Job->create( \%jd );
}

my $job;
lives_ok { $job = $dbaird->job } 'got a job';

like( $job->jobtitle, qr(^Dogs Body$) );
like( $dbaird->jobtitle, qr(^Dogs Body$) );



my $data = { street => 'NiceStreet',
             name   => 'DaveBaird',
             town   => 'Trumpton',
             toys    => [ qw( 1 2 3 ) ],
             job    => 'Dogs Body', # stringifies job object
             jobtitle => 'Dogs Body',
             employer => 'Tyrant Joe',
             salary => 3,
             };        

my $obj_data = { map { $_ => $dbaird->$_ || undef } keys %$data };
$obj_data->{toys} = [ map { $_->id } $dbaird->toys ];
is_deeply( $obj_data, $data );

my $form = $dbaird->as_form( selectnum => 2 );

my $html = $form->render;

like( $html, qr(job) );

like( $html, qr(<select id="job" name="job">\s*<option value="">-select-</option>\s*<option selected="selected" value="1">Dogs Body</option>\s*<option value="2">Dogs Body 2</option>\s*<option value="3">Dogs Body 3</option>\s*<option value="4">Dogs Body 4</option>\s*<option value="5">Dogs Body 5</option>\s*<option value="6">Dogs Body 6</option>\s*<option value="7">Dogs Body 7</option>\s*<option value="8">Dogs Body 8</option>\s*<option value="9">Dogs Body 9</option>\s*<option value="10">Dogs Body 10</option>\s*</select>), 'finding might_have rels' );

my $class_form_html = Person->as_form( selectnum => 2 )->render;

like( $class_form_html, qr(<select id="job" name="job">\s*<option value="">-select-</option>\s*<option value="1">Dogs Body</option>\s*<option value="2">Dogs Body 2</option>\s*<option value="3">Dogs Body 3</option>\s*<option value="4">Dogs Body 4</option>\s*<option value="5">Dogs Body 5</option>\s*<option value="6">Dogs Body 6</option>\s*<option value="7">Dogs Body 7</option>\s*<option value="8">Dogs Body 8</option>\s*<option value="9">Dogs Body 9</option>\s*<option value="10">Dogs Body 10</option>\s*</select>) );




