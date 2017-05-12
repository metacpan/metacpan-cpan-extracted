package TestAppLoadtmpl;

use strict;

use base qw(TestAppBase);

__PACKAGE__->add_callback('load_tmpl', 
    sub {
        my $self    = shift;
        my $options = shift;
        my $vars    = shift;
        my $file    = shift;

        $vars->{load_tmpl_var} = 'load_tmpl param.';
    }
);

sub test_mode {
    my $self = shift;

    my $tt_vars = {
                    template_var => 'template param.'
    };

    return $self->tt_process(\*DATA, $tt_vars);
}

1;

# The test template file is below in the DATA segment

__DATA__

[% template_var %]

[% load_tmpl_var %]

