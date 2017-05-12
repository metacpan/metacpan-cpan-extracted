#!perl

package My::TestConfig;

use strict;
use warnings;

use base qw(Apache::TestConfig);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    # explicit call to apxs...
    $self->configure_apxs;
    # ... so this works.
    $self->{vars}{src_dir} ||= $self->apxs('LIBEXECDIR');

    $self;
}

package My::TestRun;

use strict;
use warnings;

use lib qw(lib);

use base qw(Apache::TestRunPerl);

__PACKAGE__->new->run(@ARGV);

sub new_test_config {
    my $self = shift;

    My::TestConfig->new($self->{conf_opts});
}

#sub pre_configure {
#    my $self = shift;
    # XXX dodgy, not through the interface
#    my $tc = $self->{test_config} or die $!;

#    map { $tc->find_and_load_module($_) } qw(proxy proxy_http proxy_connect);

#    $self->SUPER::pre_configure;
#}
