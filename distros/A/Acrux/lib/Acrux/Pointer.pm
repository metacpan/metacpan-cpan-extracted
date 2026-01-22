package Acrux::Pointer;
use strict;
use utf8;

=encoding utf8

=head1 NAME

Acrux::Pointer - The Acrux pointer

=head1 SYNOPSIS

    use Acrux::Pointer;

    my $pointer = Acrux::Pointer->new(data => {foo => [123, 'bar']});

    say $pointer->get('/foo/1');
    say 'Contains "/foo".' if $pointer->contains('/foo');

=head1 DESCRIPTION

This class is an implementation of L<RFC 6901|https://tools.ietf.org/html/rfc6901>
for perl hash-structures

=head2 new

    my $pointer = Acrux::Pointer->new;
    my $pointer = Acrux::Pointer->new(data => {foo => 'bar'});

Build new Acrux::Pointer object

=head1 ATTRIBUTES

This class implements the following attributes

=head2 data

    my $data = $pointer->data;
    $pointer = $pointer->data({foo => 'bar'});

Data structure to be processed

=head1 METHODS

This class implements the following methods

=head2 contains

    my $bool = $pointer->contains('/foo/1');

Check if L</"data"> contains a value that can be identified with the given pointer

=head2 get

    my $value = $pointer->get('/foo/bar');

Extract value from L</"data"> identified by the given pointer

    # "just a string"
    Acrux::Pointer->new(data => 'just a string')->get();

    # "bar"
    Acrux::Pointer->new(data => {foo => 'bar', baz => [4, 5, 6]})->get('/foo');

    # "4"
    Acrux::Pointer->new(data => {foo => 'bar', baz => [4, 5, 6]})->get('/baz/0');

    # "6"
    Acrux::Pointer->new(data => {foo => 'bar', baz => [4, 5, 6]})->get('/baz/2');

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Mojo::JSON::Pointer>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2026 D&D Corporation

=head1 LICENSE

This program is distributed under the terms of the Artistic License Version 2.0

See the C<LICENSE> file or L<https://opensource.org/license/artistic-2-0> for details

=cut

sub new {
    my $class = shift;
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    my $self  = bless {
            data => $args->{data}
        }, $class;
    return $self;
}
sub data {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{data} = shift;
        return $self;
    }
    return $self->{data};
}
sub contains { shift->_p(0, @_) }
sub get      { shift->_p(1, @_) }

sub _p {
    my $self = shift;
    my $get = shift;
    my $pointer = shift // '';
       $pointer =~ s|^/||;
    my $data = $self->data;
    return $get ? $data : 1 unless length($pointer);
    foreach my $p (length($pointer) ? (split /\//, $pointer, -1) : ($pointer)) {
        $p =~ s|~1|/|g;
        $p =~ s|~0|~|g;
        if ((ref($data) eq 'HASH') && exists $data->{$p}) { # Hash ref
            $data = $data->{$p}
        } elsif ((ref($data) eq 'ARRAY') && ($p =~ /^[0-9]+$/) && @$data > $p) { # Array ref
            $data = $data->[$p]
        } else { # Not found
            return undef;
        }
    }
    return $get ? $data : 1;
}

1;

__END__
