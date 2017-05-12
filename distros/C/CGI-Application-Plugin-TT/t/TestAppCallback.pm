package TestAppCallback;

use strict;

use base qw(TestAppBase);

__PACKAGE__->add_callback('tt_pre_process', 
    sub {
        my $self = shift;
        my $file = shift;
        my $vars = shift;

        $vars->{pre_process_var} = 'pre_process param.';
    }
);

__PACKAGE__->add_callback('tt_post_process', 
    sub {
        my $self    = shift;
        my $htmlref = shift;

        $$htmlref =~ s/post_process_var/post_process param./;
    }
);

sub test_mode {
    my $self = shift;

    $self->tt_params(template_param_hash => 'template param hash.');
    $self->tt_params({template_param_hashref => 'template param hashref.'});


    my $tt_vars = {
                    template_var => 'template param.'
    };

    return $self->tt_process(\*DATA, $tt_vars);
}

1;

# The test template file is below in the DATA segment

__DATA__

[% template_var %]
[% template_param_hash %]
[% template_param_hashref %]

[% pre_process_var %]

post_process_var

