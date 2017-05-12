package MyApp::Test;
use strict;
use base qw(MyApp);
use CLITest;
use constant subcommands => qw(hate Cascading);
use constant options => (
    'v|verbose' => 'verbose',
);

sub run {
    my $self = shift;
    cliack($self->{verbose} ? 'v' : '', @_);
}

package MyApp::Test::hate;
use base 'MyApp::Test';
use CLITest;

sub run {
    my $self = shift;
    cliack($self->{verbose} ? 'v' : '', 'hate', @_);
}

1;
