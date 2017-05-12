package Benchmark::Serialize::Library::Data::Serializer;

use strict;
use warnings;

use Benchmark::Serialize::Library;
use Scalar::Util qw(blessed);

=head1 NAME

Benchmark::Serialize::Library::Data::Serializer - Data::Serializer benchmarks

=head1 SYNOPSIS

    # Register tests on use time
    use Benchmark::Serializer::Library::Data::Serializer qw(JSON);

    # Register tests on run time
    Benchmark::Serializer::Library::Data::Serializer->register('JSON');
    

=head1 DESCRIPTION

This modules adds a set of benchmarks to L<Benchmark::Serialize> for
different uses of the L<Data::Serializer> modules. Both native Data::Serializer
bridges and the wrapping of existing benchmarks in a generic Data::Serializer
bridge is supported.  

If the argument to import/register starts with a '+' it is interpreted as a
existing benchmark to be wrapped in the generic wrapper. Other wise the
argument is interpreted as a normal Data::Serializer bridge.

Note that the generic bridge is a bit slower than a hand crafted bridge would
be.

=head1 Benchmark tags

For each added serializer a new Benchmark tag is created called
C<:DS-<nameE<gt>>, i.e C<:DS-JSON> if used as in the synopsis

=cut 

sub import {
    my $pkg     = shift;
    my @imports = map { /^\+(.*)/ ? Benchmark::Serialize::Library->load($1) : $_ } @_;

    for (@imports) {
        my $module   = blessed $_ ? "Benchmark::Serialize" : $_; 
        my $name     = blessed $_ ? $_->name               : $_;
        my $basename = blessed $_ ? $_->name . ",ds"       : "Data::Serializer::$module";
        my %extra    = blessed $_ ? %$_                    : ();
        my %options  = (
                deflate      => \&std_deflate,
                inflate      => \&std_inflate,
                packages     => [ 'Data::Serializer' ],
                "DS-$name"   => 1,
        );

        Benchmark::Serialize::Library->register(
            $basename => {
                %options,
                args => sub { 
                    Data::Serializer->new( serializer => $module, options => \%extra );
                },
            }
        );
        Benchmark::Serialize::Library->register(
            "$basename,raw" => {
                %options,
                args => sub { 
                    Data::Serializer->new( serializer => $module, raw  => 1, options => \%extra );
                },
            }
        );
        Benchmark::Serialize::Library->register(
            "$basename,compressed" => {
                %options,
                args => sub { 
                    Data::Serializer->new( serializer => $module, compress => 1, options => \%extra );
                },
            }
        );
        Benchmark::Serialize::Library->register(
            "$basename,encrypted" => {
                %options,
                args  => sub { 
                    Data::Serializer->new( serializer => $module, secret => "foobar", options => \%extra );
                },
            }
        );
    }
}

sub register {
    my $pkg = shift;

    $pkg->import( @_ );
}

sub std_deflate {
    $_[1]->serialize( $_[0] );
}

sub std_inflate {
    $_[1]->deserialize( $_[0] );
}

=head1 SEE ALSO

L<Data::Serializer>

=head1 AUTHOR

Peter Makholm, C<< <peter at makholm.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-benchmark-serialize at
rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Benchmark-Serialize>.  I will
be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2009-2010 Peter Makholm.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


1;
