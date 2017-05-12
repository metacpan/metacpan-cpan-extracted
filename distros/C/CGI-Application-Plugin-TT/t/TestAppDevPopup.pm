package TestAppDevPopup;

use strict;

use base qw(TestAppBase);
use CGI::Application::Plugin::DevPopup;

sub test_mode {
    my $self = shift;
    my $tt_vars = {
                    template_var => 'template param.',
                    html_var => '<div class="test"></div>'
    };

    return $self->tt_process(\*DATA, $tt_vars);
}

1;

# The test template file is below in the DATA segment

__DATA__

[% template_var %]

