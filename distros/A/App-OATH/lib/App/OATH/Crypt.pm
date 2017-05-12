package App::OATH::Crypt;
our $VERSION = '1.20151002'; # VERSION

use strict;
use warnings;

use App::OATH::Crypt::Rijndael;
use App::OATH::Crypt::CBC;
use String::Random qw{ random_string };

sub new {
    my ( $class, $password ) = @_;
    
    my $self = {
        'workers' => {
            'rijndael'    => App::OATH::Crypt::Rijndael->new({ 'password' => $password }),
            'cbcrijndael' => App::OATH::Crypt::CBC->new({ 'password' => $password, 'type' => 'Rijndael', }),
            'cbcblowfish' => App::OATH::Crypt::CBC->new({ 'password' => $password, 'type' => 'Blowfish', }),
        },
        'type'  => q{},
        'check' => 'oath',
    };
    bless $self, $class;
    return $self;
}

sub get_workers_list {
    my ( $self ) = @_;
    my @list = sort keys %{ $self->{'workers'} };
    return \@list;
}

sub set_worker {
    my ( $self, $type ) = @_;
    if ( $type ne q{} and not exists( $self->{'workers'}->{$type} ) ) {
        die "Unknown encryption type $type";
    }
    $self->{'type'} = $type;
    return;
}

sub encrypt {
    my ( $self, $data ) = @_;
    my $type = $self->{'type'};
    $type = 'cbcrijndael' if $type eq q{};
    my $worker = $self->{'workers'}->{$type};
    my $u = random_string( '..........' ) . ' ' . $self->{'check'} . ' ' . $data;
    return $type . ':' . $worker->encrypt( $u );
}

sub decrypt {
    my ( $self, $data ) = @_;
    my $type = $self->{'type'};
    $type = 'rijndael' if $type eq q{};
    if ( $data =~ /:/ ) {
        ( $type, $data ) = split ':', $data;
    }
    my $worker = $self->{'workers'}->{$type};
    die "Unknown encryption type $type" if ! $worker;
    my $u = $worker->decrypt( $data );
    my ( $salt, $check, $payload ) = split( ' ', $u );
    $check = q{} if ! $check;
    if ( $check ne $self->{'check'} ) {
        return;
    }
    return $payload;
}

1;

__END__

=head1 NAME

App::OATH::Crypt - Crypto modules for Simple OATH authenticator

=head1 DESCRIPTION

Crypto modules super class

=head1 SYNOPSIS

Handles all crypto, detection of methods and handing off to sub
modules which implement the actual encryption and decryption of data

=head1 METHODS

=over

=item I<new()>

Instantiate a new object

=item I<get_workers_list()>

Return an array ref of possible worker types

=item I<set_worker($worker)>

Set the default worker type

=item I<encrypt($data)>

Encrypt the given data

=item I<decrypt($data)>

Decrypt the given data

=back

=head1 DEPENDENCIES

=head1 AUTHORS

Marc Bradshaw E<lt>marc@marcbradshaw.netE<gt>

=head1 COPYRIGHT

Copyright 2015

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

