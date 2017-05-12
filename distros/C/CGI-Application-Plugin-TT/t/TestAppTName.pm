package TestAppTName;

use strict;

use base qw(TestAppBase);

sub test_mode {
    my $self = shift;

    $self->tt_params(template_param_hash => 'template param hash');
    $self->tt_params({template_param_hashref => 'template param hashref'});


    my $tt_vars = {
                    template_var => 'template param',
                    template_name => $self->tt_template_name,
    };

    return $self->tt_process($tt_vars);
}

sub tt_pre_process {
    my $self = shift;
    my $file = shift;
    my $vars = shift;

    $vars->{pre_process_var} = 'pre_process param';
}

sub tt_post_process {
    my $self    = shift;
    my $htmlref = shift;

    $$htmlref =~ s/post_process_var/post_process param/;
}

package TestAppTName::CustName;

use strict;

use TestAppTName;
@TestAppTName::CustName::ISA = qw(TestAppTName);

sub cgiapp_init {
    my $self = shift;

    $self->tt_config(
              TEMPLATE_OPTIONS => {
                        INCLUDE_PATH => 't',
                        POST_CHOMP   => 1,
                        DEBUG => 1,
              },
              TEMPLATE_NAME_GENERATOR => sub { return 'TestAppTName/test.tmpl' },
    );
}

package TestAppTName::NoVars;

use strict;

@TestAppTName::NoVars::ISA = qw(TestAppTName);

sub test_mode {
    my $self = shift;

    $self->tt_params(template_param_hash => 'template param hash');
    $self->tt_params({template_param_hashref => 'template param hashref'});

    return $self->tt_process('TestAppTName/test_mode.tmpl');
}


package TestAppTName::NoNameNoVars;

use strict;

@TestAppTName::NoNameNoVars::ISA = qw(TestAppTName);

sub test_mode {
    my $self = shift;

    $self->tt_params(template_param_hash => 'template param hash');
    $self->tt_params({template_param_hashref => 'template param hashref'});

    return $self->tt_process;
}

package TestAppTName::UpLevel;

use strict;

@TestAppTName::UpLevel::ISA = qw(TestAppTName);

sub test_mode {
    my $self = shift;

    $self->tt_params(template_param_hash => 'template param hash');
    $self->tt_params({template_param_hashref => 'template param hashref'});

    my $tt_vars = {
                    template_var => 'template param',
                    template_name => $self->call_tt_template_name,
    };

    return $self->call_tt_process($tt_vars);
}

sub call_tt_process {
    my $self = shift;
    return $self->tt_process($self->tt_template_name(1), @_);
}

sub call_tt_template_name {
    my $self = shift;
    return $self->tt_template_name(1);
}

1;
