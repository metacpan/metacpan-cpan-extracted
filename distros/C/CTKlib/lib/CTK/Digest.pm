package CTK::Digest; # $Id: Digest.pm 285 2020-08-28 21:34:27Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::Digest - CTK Digest base class

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use parent qw/CTK::Digest/;

=head1 DESCRIPTION

CTK Digest base class

=head1 METHODS

=over 8

=item B<new>

    my $provider = CTK::Digest::Provider->new();

Returns Digest Provider instance

=item B<add>

    $provider->add("data", "and another data", ...);

Add data to digest calculate.
All specified data of array will be concatenated to one pool of data

=item B<addfile>

    $provider->addfile("/path/of/file");

Add file content to data pool

    $provider->addfile(*STDIN);

Add STDIN content to data pool

=item B<digest>

    my $digest = $provider->digest;

Returns sesult digest (as is)

=item B<hexdigest>

    my $digest = $provider->hexdigest;

Returns sesult digest as hex string

=item B<b64digest>, B<base64digest>

    my $digest = $provider->b64digest;

Returns sesult digest as b64 string

=item B<reset>

    $provider->reset;

Reset data (set to "")

=back

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<Digest>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '1.00';

use constant {
    BUFFER_SIZE => 4*1024, # 4kB
};

use Carp;

use IO::File;
use MIME::Base64;

sub digest;

sub new {
    my $class = shift;
    return bless {
        data => '',
    }, $class;
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

1;

__END__

