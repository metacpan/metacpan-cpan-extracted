package Data::Dumper::AutoEncode;
use strict;
use warnings;
use Data::Dumper; # Dumper
use Data::Recursive::Encode;
use parent qw/Exporter/;
our @EXPORT = qw/eDumper Dumper/;

our $VERSION = '0.107';

our $ENCODING = '';

sub _dump {
    my $d = Data::Dumper->new(\@_);
    return $d->Dump;
}

sub eDumper {
    local $Data::Recursive::Encode::DO_NOT_PROCESS_NUMERIC_VALUE = 1;
    my @args;
    for my $arg (@_) {
        push @args, Data::Recursive::Encode->encode($ENCODING || 'utf8', $arg);
    }
    _dump(@args);
}

1;

__END__

=encoding UTF-8

=head1 NAME

Data::Dumper::AutoEncode - Dump with recursive encoding


=head1 SYNOPSIS

    use utf8;
    use Data::Dumper::AutoEncode;

    eDumper(+{ foo => 'おでん' })

=head1 DESCRIPTION

Data::Dumper::AutoEncode stringifies perl data structures including unicode string to human-readable.

example:

    use utf8;
    use Data::Dumper;

    my $foo = +{ foo => 'おでん' };

    print Dumper($foo);

It will dump like this

    { foo => "\x{304a}\x{3067}\x{3093}" }

This is not human-readable.

Data::Dumper::AutoEncode exports `eDumper` function. You can use it.

    use utf8;
    use Data::Dumper::AutoEncode;

    my $foo = +{ foo => 'おでん' };

    print eDumper($foo);
    # { foo => "おでん" }

Also `Dumper` function is exported from Data::Dumper::AutoEncode. It is same as Data::Dumper::Dumper


=head1 METHOD

=over

=item eDumper(LIST)

Dump with recursive encoding(default: utf8)

If you want to encode other encoding, set encoding to $Data::Dumper::AutoEncode::ENCODING.

    $Data::Dumper::AutoEncode::ENCODING = 'CP932';

=item Dumper(LIST)

same as Data::Dumper::Dumper

=back

=head1 REPOSITORY

Data::Dumper::AutoEncode is hosted on github
<http://github.com/bayashi/Data-Dumper-AutoEncode>


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Data::Dumper>


=head1 THANKS

gfx

tomyhero


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
