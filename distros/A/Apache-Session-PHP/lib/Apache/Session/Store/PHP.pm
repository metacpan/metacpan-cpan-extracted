package Apache::Session::Store::PHP;

use strict;
use vars qw($VERSION);
$VERSION = 0.05;

use Apache::Session::File;

use Fcntl qw(:flock);
use IO::File;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub _file {
    my($self, $session) = @_;
    my $directory = $session->{args}->{SavePath} || '/tmp';
    my $file = $directory.'/sess_'.$session->{data}->{_session_id};
    ## taint safe
    ( $file ) = $file =~ /^(.*)$/;
    return( $file );
}

sub insert {
    my($self, $session) = @_;
    $self->_write($session, 1);
}

sub update {
    my($self, $session) = @_;
    $self->_write($session, 0);
}

sub _write {
    my($self, $session, $check) = @_;

    if ($check && -e $self->_file($session)) {
        die "Object already exists in the data store";
    }

    my $fh = IO::File->new(">".$self->_file($session))
        or die "Could not open file: $!";
    flock $fh, LOCK_EX;
    $fh->print($session->{serialized});
    $fh->close;
}

sub materialize {
    my($self, $session) = @_;
    my $file = $self->_file($session);
    -e $file or die "Object does not exist in the data store";

    my $fh = IO::File->new($self->_file($session), O_RDWR|O_CREAT)
	or die "Could not open file: $!";
    flock $fh, LOCK_EX;
    while (<$fh>) {
	$session->{serialized} .= $_;
    }
    close $fh;
}

sub remove {
    my($self, $session) = @_;
    my $file = $self->_file($session);
    unlink $file if -e $file;
}

1;
__END__

=head1 NAME

Apache::Session::Store::PHP - writes to PHP4 builtin session files

=head1 SYNOPSIS

B<DO NOT USE THIS MODULE DIRECTLY>

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::Session::PHP>

=cut
