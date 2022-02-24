use warnings;
use strict;
use Test::More tests => 7;
use Test::Exception;
use App::SpamcupNG qw(TARGET_HTML_FORM);
use App::SpamcupNG::HTMLParse qw(find_best_contacts);
use Log::Log4perl qw(:easy);

use lib './t';
use Fixture 'read_html';

Log::Log4perl->easy_init($WARN);

use constant BASE_URI => 'http://www.spamcop.net/sc?id=z6728954861zb68b40';

note('Parsing an OK HTML document with report submission form');
my $html_doc = read_html('sendreport_form_ok.html');
my $form     = App::SpamcupNG::_report_form( $html_doc, BASE_URI );
isa_ok( $form, 'HTML::Form' );
is( $form->attr('name'), TARGET_HTML_FORM,
    'the form returned has the expected name' );
my $best_ref = find_best_contacts($html_doc);
is( scalar(@$best_ref), 0, 'No best contacts are expected' );

note('Parsing an HTML document without the expected form');
$html_doc = read_html('missing_sendreport_form.html');
$form     = App::SpamcupNG::_report_form( $html_doc, BASE_URI );
is( $form, undef, 'The form is not found' );
$best_ref = find_best_contacts($html_doc);
is( scalar(@$best_ref), 2, 'It has the expected number of best contacts' );
is_deeply(
    $best_ref,
    [qw(abuse@ovh.net noc@ovh.net)],
    'It has the expected best contacts'
    );
throws_ok { find_best_contacts('foobar') } qr/scalar\sreference/,
    'find_best_contacts dies with invalid parameter';

