package App::Ikaros::Installer;
use strict;
use warnings;
use parent qw/Class::Accessor::Fast/;
use App::Ikaros::Util qw/run_command_on_remote/;
use App::Ikaros::IO;
use App::Ikaros::PathMaker qw/
    lib_top_dir
    prove
    forkprove
/;

__PACKAGE__->mk_accessors(qw/code/);

my @INSTALL_LIBS = qw{
    App/Prove.pm
    App/ForkProve.pm
    XML/Simple.pm
    TAP/Harness/JUnit.pm
    IPC/Run.pm
};

sub new {
    my ($class) = @_;
    my $code = do { local $/; <DATA> };
    return $class->SUPER::new({ code => $code });
}

sub install_all {
    my ($self, $host) = @_;
    $self->__install_libraries($host);
    $self->__install_devel_cover($host) if ($host->coverage);
    $self->__install_trigger_script($host);
}

sub __install_libraries {
    my ($self, $host) = @_;

    my @libs;
    my @bins = (prove, forkprove);

    foreach my $lib (@INSTALL_LIBS) {
        my $lib_top_dir = lib_top_dir $lib;
        push @libs, $lib_top_dir if (-d $lib_top_dir);
    }

    my $workdir = $host->workdir;
    $host->connection->rsync_put({
        recursive => 1,
    }, $_, $workdir . '/ikaros_lib/') foreach (@libs);

    $host->connection->rsync_put({
        recursive => 1,
    }, $_, $workdir . '/ikaros_lib/bin/') foreach (@bins);
}

sub __install_devel_cover {
    my ($self, $host) = @_;
    my $workdir = $host->workdir;
    my $env = ($host->perlbrew) ? 'source $HOME/perl5/perlbrew/etc/bashrc;' : '';
    my $cpanm = "$env cd $workdir && curl -LO http://xrl.us/cpanm";
    my $install_devel_cover = "$env cd $workdir && perl cpanm -l ikaros_lib Devel::Cover --notest";

    run_command_on_remote($host, $cpanm);
    run_command_on_remote($host, $install_devel_cover);
}

sub __install_trigger_script {
    my ($self, $host) = @_;
    return unless defined $host->tests;
    my $filename = $host->trigger_filename;
    my $tests = join ', ', map { "'$_'" } @{$host->tests};
    my $prove = join ', ', map { "'$_'" } @{$host->prove};
    my $trigger_script = sprintf($self->code, $prove, $tests);
    App::Ikaros::IO::write($filename, $trigger_script);
    $host->connection->scp_put({}, $filename, $host->workdir);
}

1;

__DATA__
use strict;
use warnings;
use IPC::Run qw//;

sub run {
    my (@argv) = @_;
    my $stdout = '';
    my $status = do {
        my $in = '';
        my $out = sub {
            my ($s) = @_;
            $stdout .= $s;
            print $s;
        };
        my $err = sub { warn shift; };
        IPC::Run::run \@argv, \$in, $out, $err;
    };
    return map {
        if ($_ =~ /\A(.*?)\s*\(Wstat: [1-9]/ms) {
            $1;
        } else {
            ();
        }
    } split /\n/xms, $stdout;
}

my @prove_args = (
    %s,
    '--harness',
    'TAP::Harness::JUnit',
    %s
);
run(@prove_args);
exit(1);

