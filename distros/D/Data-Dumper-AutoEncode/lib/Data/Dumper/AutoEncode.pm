package Data::Dumper::AutoEncode;
use strict;
use warnings;
use Carp ();
use Encode ();
use Scalar::Util qw(blessed refaddr);
use B;
use Data::Dumper; # Dumper
use parent qw/Exporter/;
our @EXPORT = qw/eDumper Dumper/;

our $VERSION = '0.108';

our $ENCODING = '';
our $CHECK_ALREADY_ENCODED = 1;
our $DO_NOT_PROCESS_NUMERIC_VALUE = 1;

sub _dump {
    my $d = Data::Dumper->new(\@_);
    return $d->Dump;
}

sub eDumper {
    my @args;
    for my $arg (@_) {
        push @args, encode($ENCODING || 'utf8', $arg);
    }
    _dump(@args);
}

sub encode {
    my ($encoding, $stuff, $check) = @_;
    $encoding = Encode::find_encoding($encoding)
        || Carp::croak("unknown encoding '$encoding'");
    $check ||= 0;
    _apply(sub { $encoding->encode($_[0], $check) }, {}, $stuff);
}

# copied from Data::Recursive::Encode
sub _apply {
    my $code = shift;
    my $seen = shift;

    my @retval;
    for my $arg (@_) {
        if(my $ref = ref $arg){
            my $refaddr = refaddr($arg);
            my $proto;

            if(defined($proto = $seen->{$refaddr})){
                 # noop
            }
            elsif($ref eq 'ARRAY'){
                $proto = $seen->{$refaddr} = [];
                @{$proto} = _apply($code, $seen, @{$arg});
            }
            elsif($ref eq 'HASH'){
                $proto = $seen->{$refaddr} = {};
                %{$proto} = _apply($code, $seen, %{$arg});
            }
            elsif($ref eq 'REF' or $ref eq 'SCALAR'){
                $proto = $seen->{$refaddr} = \do{ my $scalar };
                ${$proto} = _apply($code, $seen, ${$arg});
            }
            else{ # CODE, GLOB, IO, LVALUE etc.
                $proto = $seen->{$refaddr} = $arg;
            }

            push @retval, $proto;
        }
        else{
            push @retval, _can_exec($arg) ? $code->($arg) : $arg;
        }
    }

    return wantarray ? @retval : $retval[0];
}

# copied from Data::Recursive::Encode
sub _is_number {
    my $value = shift;
    return 0 unless defined $value;

    my $b_obj = B::svref_2object(\$value);
    my $flags = $b_obj->FLAGS;
    return $flags & ( B::SVp_IOK | B::SVp_NOK ) && !( $flags & B::SVp_POK ) ? 1 : 0;
}

sub _can_exec {
    my ($arg) = @_;

    return unless defined($arg);
    return 1 if ( !$DO_NOT_PROCESS_NUMERIC_VALUE || !_is_number($arg) )
                    && ( $CHECK_ALREADY_ENCODED && Encode::is_utf8($arg) );
    return;
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
