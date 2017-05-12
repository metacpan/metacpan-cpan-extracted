package App::RunCron::Reporter::File;
use strict;
use warnings;
use utf8;

use File::Path     qw/mkpath/;
use File::Basename qw/dirname/;
use Time::Piece;
use parent 'App::RunCron::Reporter';
use Class::Accessor::Lite (
    ro  => [qw/file/],
);

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    my $self = bless \%args, $class;

    defined $self->file or die 'file is required option';
    $self;
}

sub run {
    my ($self, $runner) = @_;

    my $file = $self->file;
    my $now = localtime;
    $file = $now->strftime($file);
    my $dir = dirname($file);
    mkpath $dir;

    open my $fh, '>>', $file or die $!;
    print $fh '-'x78, "\n" . $runner->report;
    close $fh;
}

1;
