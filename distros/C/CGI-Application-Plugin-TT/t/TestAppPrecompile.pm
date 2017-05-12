package TestAppPrecompile;

use strict;

use base qw(TestAppBase);

sub cgiapp_init {
    my $self = shift;

    $self->tt_config(
              TEMPLATE_OPTIONS => {
                        INCLUDE_PATH => $self->param('TT_DIR'),
                        ABSOLUTE     => 1,
              },
              TEMPLATE_PRECOMPILE_DIR => $self->param('TT_DIR'),
              TEMPLATE_PRECOMPILE_FILETEST => $self->param('TEMPLATE_PRECOMPILE_FILETEST'),
    );
}


1;
