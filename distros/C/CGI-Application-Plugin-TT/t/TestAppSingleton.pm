package TestAppSingleton;

use strict;

use base qw(CGI::Application);

use CGI::Application::Plugin::TT;
TestAppSingleton->tt_config(
              TEMPLATE_OPTIONS => {
                        INCLUDE_PATH => 't',
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

    $self->tt_params(template_param_hash => 'template param hash.');
    $self->tt_params({template_param_hashref => 'template param hashref.'});


    my $tt_vars = {
                    template_var => 'template param.'
    };

    return $self->tt_process(\*DATA, $tt_vars);
}

sub tt_pre_process {
    my $self = shift;
    my $file = shift;
    my $vars = shift;

    $vars->{pre_process_var} = 'pre_process param.';
}

sub tt_post_process {
    my $self    = shift;
    my $htmlref = shift;

    $$htmlref =~ s/post_process_var/post_process param./;
}

1;

# The test template file is below in the DATA segment

__DATA__

[% template_var %]
[% template_param_hash %]
[% template_param_hashref %]

[% pre_process_var %]

post_process_var

