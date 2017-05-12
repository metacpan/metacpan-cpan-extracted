my @cases;

BEGIN {
    @cases = (
        { template => "delimiter { 'fail'", args => {}, },
        { template => '{ syntax error + }', args => {}, },
    );
}

use Test::More tests => 2 * @cases;
use Test::Fatal;
use File::Temp ();
use autodie ':all';

use Dancer2::Template::TextTemplate::FakeEngine;
use Text::Template;

my $e = Dancer2::Template::TextTemplate::FakeEngine->new;
$e->caching(0);    # easier without caching

# Do the same thing with Text::Template so we can compare error messages
for my $case (@cases) {

    note 'From here, test failure indicate a wrong test case, '
      . 'not an error from the module ...';

    my $tt_result = my $tt_out =
      Text::Template::fill_in_string( $case->{template},
        HASH => $case->{args} );

    my $tt_errormsg = $Text::Template::ERROR;
    ok $tt_errormsg, 'Text::Template should set $ERROR; with: '
      . $case->{template};
    $Text::Template::ERROR = undef;

    note '... until here, where the module is actually tested.';

    is(
        exception { $e->process( \( $case->{template} ), $case->{args} ) },
        $errormsg,
        'same error as Text::Template is emitted for: ' . $case->{template}
    );
}

1;
