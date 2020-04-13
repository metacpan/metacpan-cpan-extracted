package Data::Dumper::AutoEncode;
use strict;
use warnings;
use Carp ();
use Encode ();
use Scalar::Util qw(blessed refaddr);
use B;
use Data::Dumper; # Dumper

our $VERSION = '1.00';

our $ENCODING = '';
our $CHECK_ALREADY_ENCODED = 0;
our $DO_NOT_PROCESS_NUMERIC_VALUE = 1;
our $FLAG_STR = '';

our $BEFORE_HOOK;
our $AFTER_HOOK;

sub import {
    my $class = shift;
    my %args = map { $_ => 1 } @_;

    if (delete $args{'-dumper'}) {
        no strict 'refs'; ## no critic
        *{__PACKAGE__."::Dumper"} = *{__PACKAGE__."::eDumper"};
    }

    my $export_all = !!(scalar(keys %args) == 0);

    my $pkg = caller;

    for my $f (qw/ Dumper eDumper /) {
        if ( $export_all || (exists $args{$f} && $args{$f}) ) {
            no strict 'refs'; ## no critic
            *{"${pkg}::${f}"} = \&{$f};
        }
    }
}

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
            if (_can_exec($arg)) {
                push @retval, $FLAG_STR ? $FLAG_STR . _exec($code, $arg) : _exec($code, $arg);
            }
            else {
                push @retval, $arg;
            }
        }
    }

    return wantarray ? @retval : $retval[0];
}

sub _exec {
    my ($code, $arg) = @_;

    if (ref $BEFORE_HOOK eq 'CODE') {
        $arg = $BEFORE_HOOK->($arg);
    }

    my $result = $code->($arg);

    if (ref $AFTER_HOOK eq 'CODE') {
        return $AFTER_HOOK->($result);
    }

    return $result;
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
    return if $DO_NOT_PROCESS_NUMERIC_VALUE && _is_number($arg);
    return 1 if Encode::is_utf8($arg);
    return 1 if !$CHECK_ALREADY_ENCODED && !Encode::is_utf8($arg);

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

By default, both functions B<eDumper> and B<Dumper> will be exported.

=over

=item eDumper(LIST)

Dump with recursive encoding(default: utf8)

If you want to encode other encoding, set encoding to $Data::Dumper::AutoEncode::ENCODING.

    $Data::Dumper::AutoEncode::ENCODING = 'CP932';

=item Dumper(LIST)

Same as the C<Dumper> function of L<Data::Dumper>. However, if you specify an import option C<-dumper>, then the C<Dumper> function will work as same as C<eDumper> function. Please see C<IMPORT OPTIONS> section for more details.

=item encode($encoding, $stuff)

Just encode stuff.

=back

=head1 IMPORT OPTIONS

You can specify an import option to override C<Dumper> function.

    use Data::Dumper::AutoEncode '-dumper';

It means C<Dumper> function is overrided as same as eDumper.


=head1 GLOBAL VARIABLE OPTIONS

=head2 ENCODING : utf8

Set this option if you need another encoding;

=head2 BEFORE_HOOK / AFTER_HOOK

Set code ref for hooks which excuted around encoding

    $Data::Dumper::AutoEncode::BEFORE_HOOK = sub {
        my $value = $_[0]; # decoded
        $value =~ s/\x{2019}/'/g;
        return $value;
    };

    $Data::Dumper::AutoEncode::AFTER_HOOK = sub {
        my $value = $_[0]; # encoded
        // do something
        return $value;
    };

=head2 CHECK_ALREADY_ENCODED : false

If you set this option true value, check a target before encoding. And do encode in case of decoded value.

=head2 DO_NOT_PROCESS_NUMERIC_VALUE : true

By default, numeric values are ignored (do nothing).

=head2 FLAG_STR

Additional string (prefix) for encoded values.


=head1 HOW TO SET CONFIGURATION VARIABLES TO DUMP

This C<Data::Dumper::AutoEncode> is using L<Data::Dumper> internally. So, you can set configuration variables to dump as the variables of Data::Dumper, like below.

    use Data::Dumper::AutoEncode;

    local $Data::Dumper::Indent   = 2;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Deparse  = 1;

    say eDumper($hash);


=head1 REPOSITORY

Data::Dumper::AutoEncode is hosted on github
L<http://github.com/bayashi/Data-Dumper-AutoEncode>


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
