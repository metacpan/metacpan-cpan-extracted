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
