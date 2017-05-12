package    # hide from PAUSE
    TestApp::User;

use Moose;
has 'name' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
    lazy     => 1,
    default  => sub { return 'Amiri' }
);

1;
