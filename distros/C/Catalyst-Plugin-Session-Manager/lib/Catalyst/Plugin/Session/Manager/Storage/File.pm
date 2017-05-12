package Catalyst::Plugin::Session::Manager::Storage::File;
use strict;
use warnings;

use base qw/Catalyst::Plugin::Session::Manager::Storage/;

use Catalyst::Exception;
use File::Spec;
use Fcntl qw/:flock/;

our $DIR     = "/tmp";
our $PREFIX  = "Catalyst-Session";
our $EXPIRES = 60 * 60;

sub new {
    my $class = shift;
    bless { config => $_[0], _data => {} }, $class;
}

sub set {
    my ( $self, $c ) = @_;
    my $sid  = $c->sessionid or return;
    my $file = $self->filepath($sid);
    my $fh = IO::File->new($file, "w")
        or Catalyst::Exception->throw(qq/Couldn't save session "$file"/);
    flock($fh, LOCK_EX);
    $fh->print( $self->serialize( $self->{_data} ) );
    $fh->close;
    $self->{_data} = {};
    $self->cleanup;
}

sub get {
    my ( $self, $sid ) = @_;
    my $file = $self->filepath($sid);
    my $fh   = IO::File->new($file);
    return $self->{_data} unless $fh;
    flock($fh, LOCK_SH);
    my $data;
    $data .= $_ while ( <$fh> );
    $fh->close;
    $self->{_data} = $self->deserialize($data);
    return $self->{_data};
}

sub filepath {
    my ( $self, $sid ) = @_;
    my $dir    = $self->{config}{storage_dir} || $DIR;
    my $prefix = $self->{config}{file_prefix} || $PREFIX;
    my $file   = sprintf "%s-%s", $prefix, $sid;
    return File::Spec->catfile($dir, $file);
}

sub cleanup {
    my $self    = shift;
    my $dir     = $self->{config}{storage_dir} || $DIR;
    my $expires = $self->{config}{expires}     || $EXPIRES;
    my $prefix  = $self->{config}{file_prefix} || $PREFIX;
    my $file    = sprintf "%s-*", $prefix;
    my $glob    = File::Spec->catfile($dir, $file);
    unlink $_ for grep { _mtime($_) < time - $expires } glob $glob;
}

sub _mtime { (stat(shift))[9] }

1;
__END__

=head1 NAME

Catalyst::Plugin::Session::Manager::Storage::File - stores session-data with file

=head1 SYNOPSIS

    use Catalyst qw/Session::Manager/;

    MyApp->config->{session} = {
        storage     => 'File',
        storage_dir => '/tmp',
        file_prefix => 'MyApp-Session',
        expires     => 3600,
    };

=head1 DESCRIPTION

This module allows you to handle session with file.

=head1 CONFIGURATION

=over 4

=item storage_dir

'/tmp' is set by default.

=item file_prefix

'Catalyst-Session' is set by default.

=item expires

3600 is set by default.

=back

=head1 SEE ALSO

L<Catalyst>

L<Catalyst::Plugin::Session::Manager>

=head1 AUTHOR

Lyo Kato E<lt>lyo.kato@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

