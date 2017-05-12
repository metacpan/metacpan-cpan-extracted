use strict;
use warnings;

package ShellTest;

use parent 'Test::Class::TestGroup';

use Test::More;
use Test::BinRegression;
use File::Slurp 'read_file';

use Code::Statistics::App;

sub make_fixture : Test(setup) {
    my ( $self ) = @_;

    $self->{basic_collect_args} = [ qw(
        collect
        --dirs=data/shelltest/basic_collect
        --relative_paths
        --foreign_paths=Unix
        --conf_file=data/config/shelltestrc
        --global_conf_file=data/config/does_not_exist
    ) ];

    return;
}

sub basic_collect : TestGroup {
    my ( $self ) = @_;

    local @ARGV = @{ $self->{basic_collect_args} };

    $self->check_codestat_shell_app_against( "data/json/basic_collect.json" );

    ok( -e 'codestat.out', 'output file is generated' );

    ok_regression(
        sub { $self->get_codestat_out_file },
        "data/json/basic_collect.json",
        'dumped file matches expected output'
    );

    @ARGV = qw( report --quiet --file_ignore=;Ignored );

    $self->check_codestat_shell_app_against( "data/json/basic_report.json" );

    unlink( 'codestat.out' );

    return;
}

sub nodump_collect : TestGroup {
    my ( $self ) = @_;

    local @ARGV = (
        @{$self->{basic_collect_args}},
        qw( --no_dump )
    );

    $self->check_codestat_shell_app_against( "data/json/basic_collect.json" );

    ok( !-e 'codestat.out', '--no_dump does not generate a file' );

    return;
}

sub check_codestat_shell_app_against {
    my ( $self, $file ) = @_;

    ok_regression(
        sub {
            my $result = Code::Statistics::App->run;
            if ( grep { $_ eq 'report' } @ARGV ) {
                $result =~ s/2.62\n/2.63\n/;
                $result =~ s/^(ccomp: 3.66)\d+/$1/m;
                $result =~ s/^(ccomp: 2.71)\d+/$1/m;
                $result =~ s/^(ccomp: 1.61)\d+/$1/m;
                $result =~ s/^(lines: 6.47)\d+/$1/m;
                $result =~ s/^(lines: 4.30)\d+/$1/m;
                $result =~ s/^(sdepth: 5.42)\d+/$1/m;
                $result =~ s/^(size: 69.42)\d+/$1/m;
                $result =~ s/^(size: 44.30)\d+/$1/m;
            }
            return $result;
        },
        $file,
        'returned string matches expected output',
        'binmode',
    );

    return;
}

sub get_codestat_out_file {
    my $result = read_file('codestat.out');
    return $result;
}

1;
