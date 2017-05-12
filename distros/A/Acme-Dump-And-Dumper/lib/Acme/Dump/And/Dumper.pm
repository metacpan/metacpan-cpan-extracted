package Acme::Dump::And::Dumper;

use strict;
use warnings;

our $VERSION = '1.001005'; # VERSION

require Exporter;
our @ISA = qw/Exporter  Data::Dumper/;
our @EXPORT_OK = @Data::Dumper::EXPORT_OK;
our @EXPORT    = ( 'DnD', @Data::Dumper::EXPORT );

use Data::Rmap;
use Scalar::Util qw/blessed  refaddr/;
use Data::Dumper ( @Data::Dumper::EXPORT, @Data::Dumper::EXPORT_OK, );
use Storable qw/dclone/;
$Storable::Deparse = 1;

sub DnD {
    my @in = @_;

    my @out;
    for my $data ( @in ) {
        my $working_data = eval { dclone $data };
        $working_data = $data
            unless defined $working_data;

        rmap_all {
            my $state = shift;
            if ( defined blessed $_) {
                delete $state->seen->{ refaddr $_ };
                $_ = 'obj[' . ref($_) . ']';
            }
        } $working_data;

        push @out, Dumper $working_data;
    }

    return wantarray ? @out : join '', @out;
}

1;

__END__

=encoding utf8

=for stopwords Dump'n'Dumper clonable pneumonic

=head1 NAME

Acme::Dump::And::Dumper - dump data structures without seeing any object guts

=head1 SYNOPSIS

    use Acme::Dump::And::Dumper;

    my $data = {
        foo => 'bar',
        ber => {
            beer => [qw/x y z/],
            obj  => bless([], 'Foo::Bar'),
        },
    };

    print DnD $data;

    ## Prints:
    ## $VAR1 = {
    ##      'ber' => {
    ##                 'obj' => 'obj[Foo::Bar]',
    ##                 'beer' => [
    ##                             'x',
    ##                             'y',
    ##                             'z'
    ##                           ]
    ##               },
    ##      'foo' => 'bar'
    ## };

    # All the Data::Dumper stuff is still there...
    $Data::Dumper::Useqq = 1;
    print DnD "Foo\nBar";

    # ... even the original Dumper()
    print Dumper "Foo\nBar";

=head1 DESCRIPTION

A L<Data::Dumper>, with an additional sub that's like C<Dumper()>
but doesn't dump the contents of object refs.

=head1 EXPORTS

In addition to all the stuff available for export in L<Data::Dumper>,
this module provides C<DnD()> function (pneumonic: "Dump'n'Dumper").

=head2 C<DnD>

    print DnD $data;

    # Data::Dumper's vars are still available:
    $Data::Dumper::Useqq = 1;
    print DnD "Foo\nBar";

Takes the same stuff and returns the same output as
C<Data::Dumper::Dumper()>, except all of the
objects will be replaced with C<obj[Foo::Bar]>, where C<Foo::Bar> is
object's class. B<See caveats section below>.

=head1 CAVEATS

Whenever possible, the module will try to deep clone the structure
before messing with it and dumping it. B<However>, since not everything
is deep clonable, if the deep clone fails, the module will modify the
original data structure, and method call on what B<used to be> objects
will obviously fail.

=head1 HISTORY

This module arose from my frustration of trying to get rid of object
guts in my dumped data (e.g. dumping C<Foo::Bar> that is a blessed
hashref, would also dump all the contents of that hashref).
Subsequently, during a conversation on IRC, C<tm604> came up with
a hack using C<$Data::Dumper::Freezer>, and the following comment
from C<hoelzro> made me decide to release a module I could actually
use, when I don't want to see any object guts.

    <hoelzro> Data::Dumper::And::Dumper
    * hoelzro ducks
    <hoelzro> s/Dumper/Dump/ # ruined my own awful joke

P.S.: eventually I ended up using L<Data::Rmap> instead of the Freezer.

=begin html

<img src="http://zoffix.com/CPAN/Acme-Dump-and-Dumper.jpg"
    style="border: 2px solid #aaa!important; display: block!important; margin: 20px 0!important;"
    alt="Dumb and Dumber">

=end html

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/Acme-Dump-And-Dumper>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/Acme-Dump-And-Dumper/issues>

If you can't access GitHub, you can email your request
to C<bug-Acme-Dump-And-Dumper at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut
