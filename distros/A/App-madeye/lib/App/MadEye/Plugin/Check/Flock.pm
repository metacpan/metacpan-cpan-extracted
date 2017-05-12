package App::MadEye::Plugin::Check::Flock;
use strict;
use warnings;
use base qw/App::MadEye::Plugin::Base/;
use LWP::UserAgent;
use Fcntl ":flock";

sub check : Hook {
    my ($self, $context, $args) = @_;

    my $file_name = $self->config->{config}->{file} or die "missing file";
    open $self->{lock_fh} , '>' , $file_name or die $!;
    my $status = flock( $self->{lock_fh}, LOCK_EX|LOCK_NB ) or die "cannot get the lock";
}

sub after_run_jobs : Hook {
    my ($self, $context, $args) = @_;

    close($self->{lock_fh}); # release lock
}

1;
__END__

=head1 NAME

App::MadEye::Plugin::Check::Flock - lock.

=head1 SYNOPSIS

    - module: Check::Flock
      config:
        file: /var/run/madeye

=head1 SCHEMA

    type: map
    mapping:
        file:
            required: yes
            type: str

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<App::MadEye>

