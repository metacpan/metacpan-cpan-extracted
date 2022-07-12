package TestRole::WithGitRepo;

use App::GHPT::Wrapper::OurMoose::Role;

use File::pushd qw( pushd );
use File::Temp  qw( tempdir );
use File::Which qw( which );
use IPC::Run3   qw( run3 );

has _tempdir => (
    is      => 'ro',
    lazy    => 1,
    default => sub { pushd( tempdir() ) },
);

before test_startup => sub ( $self, @ ) {
    my $git = which('git');
    unless ( defined $git ) {
        $self->test_skip('Cannot find git in our path');
        return;
    }

    $self->_tempdir;

    $self->_run(qw( git init ));
    $self->_run(qw( git symbolic-ref HEAD refs/heads/main ));
    open my $fh, '>', 'foo';
    print {$fh} 42 or die $!;
    close $fh;

    $self->_run(qw( git add . ));
    $self->_run(qw( git commit -m Commit ));

    return;
};

sub _run ( $self, @command ) {
    run3 \@command, \undef, \my $stdout, \my $error;
    if ( $error || $? ) {
        die join q{ }, 'Problem running git:', @command, $error, $?;
    }

    return $stdout;
}

1;
