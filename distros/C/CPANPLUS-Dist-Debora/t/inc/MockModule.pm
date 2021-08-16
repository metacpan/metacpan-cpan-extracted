package MockModule;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

our $VERSION = '1.000';

use parent qw(Test::MockObject);

use Cwd qw(cwd);

## no critic (ValuesAndExpressions::ProhibitLongChainsOfMethodCalls)

sub new {
    my $class = shift;

    my $author = Test::MockObject->new
        ->set_always(author => 'Andreas Vögele');

    my $module_tree = sub {
        Test::MockObject->new
            ->set_always(package_name => $_[1] =~ s{::}{-}xmsgr)
            ->set_false('package_is_perl_core');
    };

    my $backend = Test::MockObject->new
        ->mock(module_tree => $module_tree);

    my $prereqs = {
        'CPANPLUS'          => '0.9166',
        'Module::Pluggable' => '2.4',
        'Software::License' => '0.103014',
        'Text::Template'    => '1.22',
    };

    my $status = Test::MockObject->new
        ->set_always(extract        => cwd)
        ->set_always(fetch          => 'CPANPLUS-Dist-Debora-1.0.tar.gz')
        ->set_always(installer_type => 'CPANPLUS::Dist::MM')
        ->set_always(prereqs        => $prereqs);

    my $module = $class->SUPER::new
        ->set_always(author          => $author)
        ->set_always(module          => 'CPANPLUS::Dist::Debora')
        ->set_always(package_name    => 'CPANPLUS-Dist-Debora')
        ->set_always(package_version => '1.0')
        ->set_always(parent          => $backend)
        ->set_always(status          => $status)
        ->set_false('package_is_perl_core');

    return $module;
}

1;
