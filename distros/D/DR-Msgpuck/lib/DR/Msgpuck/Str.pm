use utf8;
use strict;
use warnings;

package DR::Msgpuck::Str;
use Carp;
use overload
    bool        => sub { ${ $_[0] } ? 1 : 0 },
    int         => sub { int ${ $_[0] } },
    '""'        => sub { ${ $_[0] } },
;

sub TO_MSGPACK {
    my ($self) = @_;
    my $len = length $$self;
    return pack 'Ca*',      0xA0| $len, $$self if $len < 0x20;
    return pack 'CCa*',     0xD9, $len, $$self if $len < 0x1_00;
    return pack 'Cs>a*',    0xDA, $len, $$self if $len < 0x1_0000;
    return pack 'Cl>a*',    0xDB, $len, $$self if $len <= 0xFFFF_FFFF;
    croak "Too long line ($len bytes) can't be packed as msgpack";
}

sub new {
    my ($class, $v) = @_;
    croak 'usage DR::Msgpuck::Str->new($str)' unless defined $v;
    $v = "$v";
    utf8::encode $v if utf8::is_utf8 $v;
    bless \$v => ref($class) || $class;
}

1;

__END__

=head1 NAME

DR::Msgpuck::Str - container for strings.

=head1 SYNOPSIS

    use DR::Msgpuck::Bool;
    use DR::Msgpuck;

    my $blobstr = msgpack(DR::Msgpuck::Str->new(123));



=head1 DESCRIPTION

From time to time You need to pack numbers as strings.
Use the class for such cases.


=head1 AUTHOR

Dmitry E. Oboukhov, E<lt>unera@debian.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Dmitry E. Oboukhov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
