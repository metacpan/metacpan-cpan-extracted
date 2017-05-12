package App::NoPAN::Installer::Perl;

use strict;
use warnings;

use base qw(App::NoPAN::Installer);
use List::Util qw(first);
use Config;
use CPAN::Inject;
use File::Temp;
use Archive::Tar qw/COMPRESS_GZIP/;
use CPAN ();
use Path::Class qw/dir/;

App::NoPAN->register(__PACKAGE__);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    my $tmp = File::Temp->new(UNLINK => 1, SUFFIX => '.tar.gz');
    my $tar = Archive::Tar->new;
    dir('.')->recurse(
        callback => sub {
            $tar->add_files($_[0]);
        }
    );
    $tar->write($tmp->filename, COMPRESS_GZIP);

    my $inject = CPAN::Inject->from_cpan_config();
    my $path = $inject->add(file => $tmp->filename);
    $self->{inject_path} = $path;
    $self->{inject} = $inject;

    $self->{tmp} = $tmp;

    return $self;
}

sub DESTROY {
    my ($self) = @_;
    $self->{inject}->remove(file => $self->{inject_path});
}

sub can_install {
    my ($klass, $nopan, $root_files) = @_;
    ! ! first { $_ eq 'Makefile.PL' } @$root_files;
}

sub build {
    my ($self, $nopan) = @_;
    CPAN::Shell->make($self->{inject_path});
}

sub test {
    my ($self, $nopan) = @_;
    CPAN::Shell->test($self->{inject_path})
        unless defined $nopan->opt_test && $nopan->opt_test == 0;
}

sub install {
    my ($self, $nopan) = @_;
    CPAN::Shell->install($self->{inject_path});
}

1;
