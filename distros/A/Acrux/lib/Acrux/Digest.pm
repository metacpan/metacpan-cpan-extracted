package Acrux::Digest;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

Acrux::Digest - Acrux Digest base class

=head1 SYNOPSIS

    use parent qw/Acrux::Digest/;

=head1 DESCRIPTION

Acrux Digest base class

=head2 new

    my $provider = Acrux::Digest::Provider->new();

Returns Digest Provider instance

=head1 ATTRIBUTES

This class implements the following attributes

=head2 data

    my $data = $provider->data;
    $provider = $provider->data({foo => 'bar'});

Data structure to be processed

=head1 METHODS

This class implements the following methods

=head2 add

    $provider->add("data", "and another data", ...);

Add data to digest calculate.
All specified data of array will be concatenated to one pool of data

=head2 addfile

    $provider->addfile("/path/of/file");

Add file content to data pool

    $provider->addfile(*STDIN);

Add STDIN content to data pool

=head2 digest

    my $digest = $provider->digest;

Returns result digest (as is)

=head2 hexdigest

    my $digest = $provider->hexdigest;

Returns sesult digest as hex string

=head2 b64digest, base64digest

    my $digest = $provider->b64digest;

Returns sesult digest as b64 string

=head2 reset

    $provider->reset;

Reset data (set to "")

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Digest>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '0.01';

use constant {
    BUFFER_SIZE => 4*1024, # 4kB
};

use Carp;

use IO::File;
use MIME::Base64;

sub new {
    my $class = shift;
    return bless {
        data => '',
    }, $class;
}
sub data {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{data} = shift;
        return $self;
    }
    return $self->{data};
}
sub add {
    my $self = shift;
    $self->{data} .= join('', @_);
    return $self;
}
sub addfile {
    my $self = shift;
    my $fh = shift;
    return $self unless $fh;
    if (!ref($fh) && ref(\$fh) ne "GLOB") {
        $fh = IO::File->new($fh, "r");
        return $self unless $fh;
    }
    $fh->binmode() or croak(sprintf("Can't switch to binmode: %s", $!));
    my $buf;
    while ($fh->read($buf, BUFFER_SIZE)) {
        $self->add($buf);
    }
    $fh->close() or croak(sprintf("Can't close file: %s", $!));
    return $self;
}
sub reset {
    my $self = shift;
    $self->{data} = "";
    return $self;
}
sub hexdigest {
    my $self = shift;
    return unpack("H*", $self->digest(@_));
}
sub base64digest {
    my $self = shift;
    return encode_base64($self->digest(@_), "");
}
sub b64digest { goto &base64digest }
sub digest { croak 'Method "digest" not implemented by subclass' };

1;

__END__
