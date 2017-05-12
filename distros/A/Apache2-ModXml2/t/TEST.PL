#!perl

use strict;
use warnings FATAL => 'all';
use lib 'lib';

use Apache::TestRunPerl ();

#$Apache::TestTrace::Level = 'debug';
eval {
    # It seems Apache::Test is somewhat outdated.
    # To have it read the build_config in TestConfig, line 192ff
    # we use the following workaround. 
    require Apache2::Build;
    $ENV{MOD_PERL_API_VERSION} 
        = Apache2::Build->build_config->{API_VERSION};
};

my $test = Apache::TestRunPerl->new;
$test->run(@ARGV);

# Override an Apache::TestConfig function to 
# work around a bug in finding debian config.
# See https://rt.cpan.org/Public/Bug/Display.html?id=55355
no warnings qw(redefine);

package Apache::TestConfig;

sub configure_apxs {
    my $self = shift;

    $self->{APXS} = $self->default_apxs;

    return unless $self->{APXS};

    $self->{APXS} =~ s{/}{\\}g if WIN32;

    my $vars = $self->{vars};

    $vars->{bindir}   ||= $self->apxs('BINDIR', 1);
    my $sbindir = $vars->{sbindir}  ||= $self->apxs('SBINDIR');
    my $target = $vars->{target}   ||= $self->apxs('TARGET');
    $vars->{conf_dir} ||= $self->apxs('SYSCONFDIR');

    if (qx[$sbindir/$target -V] =~ /SERVER_CONFIG_FILE="(.*?)"/) {
      $vars->{httpd_conf} ||= $1;
    } 
}


