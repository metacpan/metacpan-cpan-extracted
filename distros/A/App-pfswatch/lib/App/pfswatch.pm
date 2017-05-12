package App::pfswatch;

use strict;
use warnings;
use 5.008_001;
use Pod::Usage;
use Getopt::Long;
use POSIX qw(:sys_wait_h);
use Filesys::Notify::Simple;
use Carp ();

our $VERSION = '0.08';

sub new {
    my $class = shift;
    my %opts  = @_;
    my %args  = (
        path => _is_arrayref( $opts{path} )
        ? [ sort @{ $opts{path} } ]
        : ['.'],
        exec  => _is_arrayref( $opts{exec} ) ? $opts{exec} : undef,
        quiet => delete $opts{quiet}         ? 1           : 0,
        pipe  => delete $opts{pipe}          ? 1           : 0,
    );

    unless ( $args{exec} ) {
        my $type
            = ref $opts{exec}     ? ref $opts{exec}
            : defined $opts{exec} ? $opts{exec}
            :                       'undef';
        Carp::croak(
            "Mandatory parameter 'exec' does not pass the type constraint because: Validation failed for Array with value $type"
        );
    }

    bless \%args, $class;
}

sub new_with_options {
    my $klass = shift;
    my $class = ref $klass || $klass;

    my %opts = $class->parse_argv(@_);
    if ( $opts{help} or scalar @{ $opts{exec} } == 0 ) {
        pod2usage();
    }

    $class->new(
        path  => $opts{path},
        exec  => $opts{exec},
        quiet => $opts{quiet} ? 1 : 0,
        pipe  => $opts{pipe} ? 1 : 0,
    );
}

sub run {
    my $self = shift;

    local $| = 1;

    my @path = @{ $self->{path} };
    warn sprintf "Start watching %s\n", join ',', @path
        unless $self->{quiet};

    my $watcher = Filesys::Notify::Simple->new( \@path );
    my $cb      = $self->_child_callback($watcher);

LOOP:
    if ( my $pid = fork ) {
        waitpid( $pid, 0 );
        goto LOOP;
    }
    elsif ( $pid == 0 ) {

        # child
        $watcher->wait($cb);
    }
    else {
        die "cannot fork: $!";
    }
}

sub _child_callback {
    my $self    = shift;
    my $watcher = shift;

    my @cmd             = @{ $self->{exec} };
    my $ignored_pattern = $self->ignored_pattern;

    sub {
        my @events = @_;
        my @files;
        for my $e (@events) {
            warn sprintf "[PFSWATCH_DEBUG] Path:%s\n", $e->{path}
                if $ENV{PFSWATCH_DEBUG};
            if ( $e->{path} !~ $ignored_pattern ) {
                push @files, $e->{path};
                last;
            }
        }
        if ( scalar @files > 0 ) {
            warn sprintf "exec %s\n", join ' ', @cmd
                unless $self->{quiet};
            if ( $self->{pipe} ) {
                open my $child_stdin, "|-", @cmd
                    or die $!;
                print $child_stdin @files;
                close $child_stdin or die $!;
                exit 0;
            }
            else {
                exec @cmd or die $!;
            }
        }
    };
}

sub parse_argv {
    my $class = shift;
    local @ARGV = @_;

    my $p = Getopt::Long::Parser->new( config => ['pass_through'] );
    $p->getoptions( \my %opts, 'pipe', 'quiet', 'help|h' );

    my ( @path, @cmd );
    my $exec_re = qr/^-(e|-exec)$/i;
    while ( my $arg = shift @ARGV ) {
        if ( $arg =~ $exec_re ) {
            @cmd = splice @ARGV, 0, scalar @ARGV;
        }
        else {
            push @path, $arg;
        }
    }
    $opts{path} = \@path;
    $opts{exec} = \@cmd;

    return %opts;
}

my @DEFAULT_IGNORED = (
    '',    # dotfile
);

sub ignored_pattern {
    qr{^.*/\..+$};    #dotfile
}

sub _is_arrayref {
    my $v = shift;
    $v && ref $v eq 'ARRAY' && scalar @$v > 0 ? 1 : 0;
}

1;
__END__

=head1 NAME

App::pfswatch - a simple utility that detects changes in a filesystem and run given command

=head1 SYNOPSIS

    use App::pfswatch->new;
    App::pfswatch->new_with_options(@ARGV)->run;

=head1 DESCRIPTION

Use L<pfswatch> instead of App::pfswatch.

=head1 AUTHOR

Yoshihiro Sasaki E<lt>ysasaki at cpan.orgE<gt>

=head1 SEE ALSO

L<Filesys::Notify::Simple>, L<App::watcher>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 COPYRIGHT

Copyright 2011 Yoshihiro Sasaki All rights reserved.

=cut
