use strict;
use warnings FATAL => 'all';

package Attribute::Universal;

# ABSTRACT: Install L<attribute handlers|Attribute::Handlers> directly into UNIVERSAL namespace

use Attribute::Handlers 0.99;
use Scalar::Util qw(refaddr);
use Carp qw(croak);

our $VERSION = '0.003';    # VERSION

my %sigil = (
    SCALAR => '$',
    ARRAY  => '@',
    HASH   => '%',
    CODE   => '&',
);

sub import {
    my ( $class, %cfg ) = @_;
    @_ = ( $class, 'UNIVERSAL', %cfg );
    goto &import_into;
}

sub import_into {
    my $class  = shift;
    my $target = shift;
    my $caller = scalar caller;
    my %cfg    = @_;
    foreach my $name ( keys %cfg ) {
        my $cfg = uc( $cfg{$name} );
        ## no critic
        eval sprintf 'sub %s::%s : ATTR(%s) { goto &%s::ATTRIBUTE }',
          $target, $name, $cfg, $caller;
        ## use critic
        croak "cannot install $target attribute $name in $caller: $@" if $@;
    }
}

sub to_hash {
    shift if $_[0] eq __PACKAGE__;
    my ( $package, $symbol, $referent, $attribute, $payload, $phase, $file,
        $line )
      = @_;
    my ( $label, $type, $sigil, $name, $full_name, @content );
    $label = ref($symbol) ? *{$symbol}{NAME} : undef;
    if ( defined $referent ) {
        $type = ref $referent;
        if ( defined $type ) {
            $sigil = $sigil{$type};
            if ( defined $sigil and defined $label ) {
                $name      = $sigil . $label;
                $full_name = $sigil . $package . '::' . $label;
            }
        }
    }
    @content = ref $payload eq 'ARRAY' ? @$payload : ($payload);
    return {
        package   => $package,
        symbol    => $symbol,
        referent  => $referent,
        attribute => $attribute,
        payload   => $payload,
        content   => \@content,
        phase     => $phase,
        file      => $file,
        line      => $line,
        label     => $label,
        type      => $type,
        sigil     => $sigil,
        name      => $name,
        full_name => $full_name,
    };
}

sub collect_by_referent {
    my $collection = shift;
    my $hash       = @_ > 1 ? to_hash(@_) : shift;
    my $key        = refaddr( $hash->{referent} );
    my $attr       = $hash->{attribute};
    $collection->{$key} //= {};
    if ( exists $collection->{$key}->{$attr} ) {
        push @{ $collection->{$key}->{$attr}->{content} } =>
          @{ $hash->{content} };
    }
    else {
        delete $hash->{payload};
        $collection->{$key}->{$attr} = $hash;
    }
    return $hash;
}

1;

__END__

=pod

=head1 NAME

Attribute::Universal - Install L<attribute handlers|Attribute::Handlers> directly into UNIVERSAL namespace

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    package Disco;

    use Attribute::Universal Loud => 'CODE';

    sub ATTRIBUTE {
        my ($package, $symbol, $referent, $attr, $data) = @_;
        # See Attribute::Handlers
    }

    # Attribute is installed global

    sub Noise : Loud {
        ...
    }

=head1 DESCRIPTION

According to the example above, this module does just this on import:

    use Attribute::Handlers;

    sub UNIVERSAL::Load : ATTR(CODE) {
        goto &Disco::ATTRIBUTE;
    }

Hint: the I<redefine> warning is still enabled.

More than one attribute may be defined at import, with any allowed option:

    use Attribute::Universal RealLoud => 'BEGIN,END', TooLoud => 'ANY,RAWDATA';

See L<Attributes::Handlers> for more information about attribute handlers.

=head1 FUNCTIONS

=head2 import_into

Instead of installing an attribute in UNIVERSAL namespace (which I<may> pollute it) the attributes can also installed directory into a target namespace.

    package Producer;

    use Attribute::Universal;

    sub import {
        my $caller = scalar caller;
        Attribute::Universal->import_into($caller, 'MyAttribute' => 'RAWDATA');
    }

    sub ATTRIBUTE {
        ...
    }

    package Consumer;

    use Producer;

    sub Function : MyAttribute;

=head2 to_hash

    sub ATTRIBUTE {
        my $hash = Attribute::Universal::to_hash(@_);
    }

Its hard to remember what arguments are given to C<ATTRIBUTE()>. This helper function converts the list into a hashref, with these keywords:

=over 4

=item * I<package>

The package the attribute was used

=item * I<symbol>

The GlobRef to the named symbol or the string L<LEXICAL>.

=item * I<referent>

The reference to the object itself (CodeRef, HashRef, ArrayRef or ScalarRef)

=item * I<attribute>

The name of the attribute

=item * I<payload>

The payload of all attributes, if used more than once. This is an ArrayRef of strings!

=item * I<phase>

The phase the attribute was covered. (BEGIN, CHECK, INIT, END)

=item * I<file>

The filename, if known

=item * I<line>

The linenumber, if known

=back

And these additional keywords:

=over 4

=item * I<label>

The name of the symbol. Imagine you have:

    sub MyFunction : Attribute;
    our $MyScalar : Attribute;

so I<label> becomes C<MyFunction> and C<MyScalar>

A lexical symbol cannot have a label.

=item * I<type>

The reftype of the referent (CODE, HASH, ARRAY, SCALAR)

=item * I<sigil>

The sigil by the reftype (C<$>, C<@>, C<%>, c<&>)

This keyword is available since v0.003

=item * I<name>

The name as sigil plus label (<$scalar>, C<@array>, C<%hash>, C<&code>)

This keyword is available since v0.003

=item * I<full_name>

The full name as sigil plus package plus label (<$package::scalar>, C<@package::array>, C<%package::hash>, C<&package::code>)

This keyword is available since v0.003

=item * I<content>

Like I<payload>, but as a forced ArrayRef.

This keyword is available since v0.003

=back

=head2 collect_by_referent

    my $collection;
    sub ATTRIBUTE {
        my $hash = Attribute::Universal::collect_by_referent($collection, @_);
        # OR
        my $hash = Attribute::Universal::to_hash(@_);
        Attribute::Universal::collect_by_referent($collection, $hash);
    }

This helper collects all attributes by the L<refaddr|Scalar::Util/refaddr> of the referent and the attribute name:

    {
        refaddr($hash->{referent)} => {
            $hash->{attribute} => $hash
        }
    }

The major difference is that, the keyword I<payload> is stripped off, but I<content> is grown if the attribute occured more than once at a referent. So after all, I<content> is an ArrayRef holding all payloads together.

This function is available since v0.003

=head1 COMPATIBILITY

This module needs a minimum perl version of 5.16 - due to the magic on module import.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/zurborg/libattribute-universal-perl/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

David Zurborg <zurborg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Zurborg.

This is free software, licensed under:

  The ISC License

=cut
