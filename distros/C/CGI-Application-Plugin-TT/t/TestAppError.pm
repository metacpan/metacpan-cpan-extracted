package TestAppError;

use strict;

use base qw(TestAppBase);

sub test_mode {
    my $self = shift;

    my $tt_vars = {
                    unclosed_if => 'unclosed if'
    };

    return $self->tt_process(\*DATA, $tt_vars);
}

1;

# The test template file is below in the DATA segment

__DATA__

[% IF unclosed_if %]
  [% unclosed_if %]

testing invalid template

