package Catalyst::Plugin::Session::Manager::Storage::FastMmap;
use strict;
use warnings;
use base qw/Catalyst::Plugin::Session::Manager::Storage/;
use Cache::FastMmap;

our $SHARE_FILE = "/tmp/session";
our $EXPIRES    = 60 * 60;

sub new { 
    my ($class, $config) = @_;
    bless {
        config => $config,
        _data  => Cache::FastMmap->new(
            share_file  => $config->{session}{file} || $SHARE_FILE,
            expire_time => $config->{session}{expires} || $EXPIRES,
        ),
    }, $class;
}

sub get {
    my $self = shift;
    $self->{_data}->get(@_);
}

sub set {
    my ( $self, $c ) = @_;
    my $sid = $c->sessionid or return;
    $self->{_data}->set( $sid, $c->session );
}

1;
__END__

=head1 NAME

Catalyst::Plugin::Session::Manager::Storage::FastMmap - stores session data with Cache::FastMmap 

=head1 SYNOPSIS

    use Catalyst qw/Session::FastMmap/;

    MyApp->config->{session} = {
        storage => 'FastMmap',
        file    => '/tmp/session',
        expires => 3600,
    };

=head1 DESCRIPTION

This module allows you to store session with Cache::FastMmap.

=head1 CONFIGURATION

=over 4

=item file

'/tmp/session' is set by default.

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

