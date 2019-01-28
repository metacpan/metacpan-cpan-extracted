package Class::Data::Lite;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.0010";

sub _croak {require Carp; Carp::croak(@_) }

sub import {
    shift;
    my %args = @_;
    my $pkg = caller(0);

    my %key_ctor = (
        rw => \&_mk_accessor,
        ro => \&_mk_ro_accessor,
    );

    no strict 'refs';
    for my $key (keys %key_ctor) {
        if (my $accessors = delete $args{$key}) {
            _croak "value of the '$key' parameter should be an arrayref or hashref"
                unless ref($accessors) =~ /^(?:HASH|ARRAY)$/;
            my %h = ref($accessors) eq 'HASH' ? %$accessors : map {($_ => undef)} @$accessors;
            while (my ($k, $v) = each %h) {
                *{"${pkg}::${k}"} = $key_ctor{$key}->($pkg, $k, $v);
            }
        }
    }
}

sub _mk_accessor {
    my ($pkg, $meth, $data) = @_;
    return sub {
        if (@_>1) {
            if ($_[0] ne $pkg) {
                # In the case of rw, raise an exception here because there is a
                # possibility of being overwritten from a child class.
                # In the case of ro, there is no risk, so we do not raise
                # exceptions in particular.
                _croak qq[can't call "${pkg}::${meth}" as object method or inherited class method];
            }
            $data = $_[1];
        }
        $data;
    };
}

sub _mk_ro_accessor {
    my ($pkg, $meth, $data) = @_;
    return sub { $data };
}

1;
__END__

=encoding utf-8

=head1 NAME

Class::Data::Lite - a minimalistic class accessors

=head1 SYNOPSIS

    package MyPackage;
    use Class::Data::Lite (
        rw => {
            readwrite => 'rw',
        },
        ro => {
            readonly => 'ro',
        },
    );
    package main;
    print(MyPackage->readwrite); #=> rw

=head1 DESCRIPTION

Class::Data::Lite is a minimalistic implement for class accessors.
There is no inheritance and fast.

=head1 THE USE STATEMENT

The use statement (i.e. the C<import> function) of the module takes a single
hash as an argument that specifies the types and the names of the properties.
Recognises the following keys.

=over

=item C<rw> => (\@name_of_the_properties|\%name_of_the_properties_and_values)

creates a read / write class accessor for the name of the properties passed
through as an arrayref or hashref.

=item C<ro> => (\@name_of_the_properties|\%name_of_the_properties_and_values)

creates a read-only class accessor for the name of the properties passed
through as an arrayref or hashref.

=back

=head1 BENCHMARK

It is faster than Class::Data::Inheritance. See C<eg/bench.pl>.

                                  Rate Class::Data::Inheritable    Class::Data::Lite
    Class::Data::Inheritable 2619253/s                       --                 -38%
    Class::Data::Lite        4191169/s                      60%                   --

=head1 SEE ALSO

L<Class::Accessor::Lite>, L<Class::Data::Inheritance>

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut
