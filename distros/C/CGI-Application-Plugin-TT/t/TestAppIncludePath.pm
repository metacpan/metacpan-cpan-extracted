package TestAppIncludePath;

use strict;

use base qw(CGI::Application);

use CGI::Application::Plugin::TT (
              TEMPLATE_OPTIONS => {
                        POST_CHOMP   => 1,
                        DEBUG => 1,
              },
);

sub setup {
    my $self = shift;
    $self->start_mode('test_mode');
    $self->run_modes(test_mode => 'test_mode' );
}

sub test_mode {
    my $self = shift;

    my $path = $ENV{TT_INCLUDE_PATH};
    $self->tt_include_path([$path]);
    return $self->tt_process({ include_path => $path });
}

1;

