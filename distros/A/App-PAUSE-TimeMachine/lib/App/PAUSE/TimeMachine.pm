package App::PAUSE::TimeMachine;

use strict;
use 5.008_005;
our $VERSION = '0.05';

use Pod::Usage ();
use IPC::Run;
use Plack::Runner;
use IO::Compress::Gzip ();
use File::pushd;

our $GIT_REPO = "git://github.com/batchpause/PAUSE-git";

sub new {
    my($class, %args) = @_;

    $args{git_dir} ||= $ENV{"PAUSETM_GIT_DIR"} || "$ENV{HOME}/.pausetm/PAUSE-git";
    bless {
        git_dir => $args{git_dir},
    }, $class;
}

sub psgi_app {
    my $self = shift;

    return sub {
        my $env = shift;

        if ($env->{PATH_INFO} eq '/') {
            return [200, ['Content-Type' => 'text/plain'], ["Access $env->{SCRIPT_NAME}/yyyy-mm-dd"]];
        }

        my $date = 'today';
        if ($env->{PATH_INFO} =~ s!^/([^/]+)!!) {
            $date = $1;
        }

        if ($env->{PATH_INFO} eq '/modules/02packages.details.txt.gz') {
            chomp(my $rev = $self->git_capture('rev-list', '-1', "--before=$date", 'master'));
            my $text = $self->git_capture('show', "$rev:02packages.details.txt");

            my($lastmod) = $text =~ m!^Last-Updated:\s*(.*)$!m;

            if ($env->{HTTP_IF_MODIFIED_SINCE} && $env->{HTTP_IF_MODIFIED_SINCE} eq $lastmod) {
                return [304, [], []];
            }

            IO::Compress::Gzip::gzip \$text => \my $gztext;
            return [
                200,
                [
                    'Content-Type' => 'application/x-gzip',
                    'Content-Length' => length($gztext),
                    'Last-Modified' => $lastmod,
                ],
                [$gztext],
            ];
        }

        if ($env->{PATH_INFO} =~ m!authors/id/!) {
            return [301, ['Location' => "http://backpan.perl.org/$env->{PATH_INFO}"], []];
        }

        return [404, ['Content-Type' => 'text/plain'], ["Not Found"]];
    };
}

sub git_dir {
    $_[0]->{git_dir};
}

sub run {
    my($self, @args) = @_;

    my $cmd = shift @args || "help";
    my $can = $self->can("cmd_$cmd") || $self->can("cmd_help");
    $self->$can(@args);
}

sub git_raw {
    my($self, @commands) = @_;
    IPC::Run::run ["git", @commands], \my $in, \*STDOUT;
}

sub git_opts {
    my $self = shift;
    ("--git-dir=" . $self->git_dir . "/.git", "--work-tree=.");
}

sub git {
    my($self, @commands) = @_;
    IPC::Run::run ["git", $self->git_opts, @commands];
}

sub git_capture {
    my($self, @commands) = @_;
    IPC::Run::run ["git", $self->git_opts, @commands], \my $in, \my $out;
    $out;
}

sub cmd_help {
    my $self = shift;
    Pod::Usage::pod2usage(1);
}

sub cmd_init {
    my $self = shift;
    $self->git_raw('clone', $GIT_REPO, $self->git_dir);
}

sub cmd_sync {
    my $self = shift;
    my $dir = pushd $self->git_dir;
    $self->git_raw('pull', 'origin', 'master');
}

sub cmd_cat {
    my($self, $date) = @_;
    chomp(my $rev = $self->git_capture('rev-list', '-1', "--before=$date", 'master'));
    $self->git('show', "$rev:02packages.details.txt");
}

sub cmd_server {
    my($self, @args) = @_;

    my $runner = Plack::Runner->new;
    $runner->parse_options(@args);
    $runner->run($self->psgi_app);
}

1;
__END__

=encoding utf-8

=head1 NAME

App::PAUSE::TimeMachine - Web server and CLI to display PAUSE package list in previous time

=head1 SYNOPSIS

For C<pausetm> command line usage, see L<pausetm>.

App::PAUSE::TimeMachine provides a PSGI web application coderef, which
you can use in your own application or apply whatever middleware you'd
like to apply.

  my $app = App::PAUSE::TimeMachine->new->psgi_app;

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2015- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<pausetm>

=cut
