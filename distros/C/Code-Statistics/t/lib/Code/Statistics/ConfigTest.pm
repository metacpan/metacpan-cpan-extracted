use strict;
use warnings;

package Code::Statistics::ConfigTest;

use lib '../..';

use parent 'Test::Class::TestGroup';

use Test::More;

use Code::Statistics::Config;

sub make_fixtures : Test(setup) {
    my ( $self ) = @_;

    $self->{conf_args} = {
        global_conf_file => 'data/config/globalcodestatrc',
        conf_file =>        'data/config/codestatrc',
        command =>        'collect',
        profile =>        'test',
        args =>        { overridden_by_args => 7 },
    };

    return;
}

sub overrides_basic : TestGroup(configuration overrides work if all config inputs are present and active) {
    my ( $self ) = @_;

    my $config = Code::Statistics::Config->new( $self->{conf_args} )->assemble;

    my %options = (
        global_setting              => 1,
        overridden_by_command       => 2,
        overridden_by_profile       => 3,
        overridden_by_local         => 4,
        overridden_by_local_command => 5,
        overridden_by_local_profile => 6,
        overridden_by_args          => 7,
    );

    is( $config->{$_}, $options{$_}, "$_ works" ) for keys %options;

    return;
}

sub overrides_no_profile : TestGroup(configuration overrides work if all no profile is given) {
    my ( $self ) = @_;

    delete $self->{conf_args}{profile};

    my $config = Code::Statistics::Config->new( $self->{conf_args} )->assemble;

    my %options = (
        global_setting              => 1,
        overridden_by_command       => 2,
        overridden_by_profile       => 2,
        overridden_by_local         => 4,
        overridden_by_local_command => 5,
        overridden_by_local_profile => 5,
        overridden_by_args          => 7,
    );

    is( $config->{$_}, $options{$_}, "$_ works" ) for keys %options;

    return;
}

sub overrides_no_file : TestGroup(configuration overrides work if a file argument is empty) {
    my ( $self ) = @_;

    $self->{conf_args}{conf_file} = '';

    my $config = Code::Statistics::Config->new( $self->{conf_args} )->assemble;

    my %options = (
        global_setting              => 1,
        overridden_by_command       => 2,
        overridden_by_profile       => 3,
        overridden_by_local         => 3,
        overridden_by_local_command => 3,
        overridden_by_local_profile => 3,
        overridden_by_args          => 7,
    );

    is( $config->{$_}, $options{$_}, "$_ works" ) for keys %options;

    return;
}

1;
