use warnings;
use strict;
use Test::More tests => 23;

use App::SpamcupNG::Summary;

my $instance = new_ok('App::SpamcupNG::Summary');
can_ok( $instance,
    qw(new as_text tracking_url to_text set_receivers _fields) );
is( ref( $instance->_fields ),
    'ARRAY', '_fields method returns the expected reference type' );
my @expected_fields = sort( (
        'tracking_id', 'mailer',   'content_type', 'age',
        'age_unit',    'contacts', 'receivers',    'charset'
) );
is_deeply( $instance->_fields, \@expected_fields,
    'fields returns all expected members' );
note('summary with nothing set');
is(
    $instance->as_text,
'age_unit=not available,charset=not available,content_type=not available,mailer=not available,tracking_id=not available,age=not available,receivers=(),contacts=()',
    'as_text returns the expected empty instance'
);
is(
    $instance->to_text('mailer'),
    'not available',
    'to_text returns the expected string'
);
is( $instance->to_text('contacts'),
    '()', 'to_text returns the expected string' );

my $tracking_id = 'z6738604873z6ba5c9152db3f6a67929aec945c60dddz';
ok( $instance->set_tracking_id($tracking_id), 'set tracking ID' );
is(
    $instance->tracking_url,
    "https://www.spamcop.net/sc?id=$tracking_id",
    'tracking URL is the expected'
);
my $mailer = 'Foobar Mailer';
ok( $instance->set_mailer($mailer), 'set mailer' );
is( $instance->to_text('mailer'),
    $mailer, 'to_text returns the expected string' );
ok( $instance->set_content_type('text/plain'), 'set content type' );
ok( $instance->set_charset('utf-8'),           'set charset' );
ok( $instance->set_age(2),                     'set age' );
ok( $instance->set_age_unit('hour'),           'set age unit' );
my $emails_ref = [ 'john@gmail.com', 'doe@gmail.com' ];
my $report_id  = 7164185194;
my @receivers  = map { [ $_, ++$report_id ] } @{$emails_ref};
ok( $instance->set_receivers( \@receivers ), 'set receivers' );
is(
    $instance->to_text('receivers'),
    'receivers=((john@gmail.com,7164185195);(doe@gmail.com,7164185196))',
    'to_text returns the expected string'
);
ok( $instance->set_contacts($emails_ref), 'set contacts' );
is(
    $instance->to_text('contacts'),
    '(john@gmail.com;doe@gmail.com)',
    'to_text returns the expected string'
);
note('summary with everything set');
is(
    $instance->as_text,
"age_unit=hour,charset=utf-8,content_type=text/plain,mailer=Foobar Mailer,tracking_id=$tracking_id,age=2,receivers=((john\@gmail.com,7164185195);(doe\@gmail.com,7164185196)),contacts=(john\@gmail.com;doe\@gmail.com)",
    'as_text returns the expected string'
);

note('summary with reports with age less than one hour');
$instance->set_age(0);
is(
    $instance->as_text,
"age_unit=hour,charset=utf-8,content_type=text/plain,mailer=Foobar Mailer,tracking_id=$tracking_id,age=0,receivers=((john\@gmail.com,7164185195);(doe\@gmail.com,7164185196)),contacts=(john\@gmail.com;doe\@gmail.com)",
    'as_text returns the expected string'
);

# undoing
$instance->set_age(2);
note('summary with missing sent reports ID');
@receivers = ();
@receivers = map { [ $_, undef ] } @{$emails_ref};
ok( $instance->set_receivers( \@receivers ), 'set receivers' );
is(
    $instance->as_text,
"age_unit=hour,charset=utf-8,content_type=text/plain,mailer=Foobar Mailer,tracking_id=$tracking_id,age=2,receivers=((john\@gmail.com,not available);(doe\@gmail.com,not available)),contacts=(john\@gmail.com;doe\@gmail.com)",
    'as_text returns the expected string'
);

# vim: filetype=perl

