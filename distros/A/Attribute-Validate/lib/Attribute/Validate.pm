package Attribute::Validate;

use v5.16.0;

use strict;
use warnings;

use Attribute::Handlers;
use Type::Params qw/signature/;
use Carp::Always;
use Carp qw/confess/;

use parent 'Exporter';  # inherit all of Exporter's methods
our @EXPORT_OK = qw(anon_requires);

our $VERSION = "0.0.3";

{
    my %compilations_of_types;

    sub UNIVERSAL::Requires : ATTR(CODE) {
        no warnings 'redefine';
        no strict 'refs';
        my (
            $package, $symbol, $referent, $attr,
            $data,    $phase,  $filename, $linenum
        ) = @_;
        if ( $symbol eq 'ANON' ) {
            local $Carp::Internal{'Attribute::Validate'} = 1;
            confess "Unable to add signature to anon subroutine";
        }
        my $orig_sub = *{$symbol}{CODE};
        my $compiled = $compilations_of_types{$referent};
        if ( !defined $compiled ) {
            $compilations_of_types{$referent} = _requires_compile_types(@$data);
        }
        *{$symbol} = _requires_new_sub($compilations_of_types{$referent}, $orig_sub);
    }
}

sub _requires_compile_types {
    my $data = [];
    @$data = @_;
    my %extra_options;
    if ( 'HASH' eq ref $data->[0] ) {
        %extra_options = %{ shift @$data };
    }
    return signature( %extra_options, positional => $data );
}

sub anon_requires {
    my $orig_sub      = shift;
    if (!defined $orig_sub || 'CODE' ne ref $orig_sub) {
        die 'Anon requires didn\'t receive a sub';
    }
    my $compiled = _requires_compile_types(@_);
    return _requires_new_sub($compiled, $orig_sub);
}

sub _requires_new_sub {
    my ($compiled, $orig_sub) = @_;
    if (!defined $orig_sub) {
        die 'Didn\'t receive a sub';
    }
    return sub {
        local $Carp::Internal{'Attribute::Validate'} = 1;
        eval { $compiled->(@_); };
        if ($@) {
            confess _filter_error("$@");
        }
        goto &$orig_sub;
    };
}

sub _filter_error {
    my $error = shift;
    $error =~ s{at lib/Attribute/Validate.pm line \d+}{}g;
    return $error;
}
1;

=encoding utf8

=head1 NAME

Attribute::Validate - Validate your subs with attributes

=head1 SYNOPSIS

    use Attribute::Validate;

    use Types::Standard qw/Maybe InstanceOf ArrayRef Str/

    use feature 'signatures';

    sub install_gentoo: Requires(Maybe[ArrayRef[InstanceOf['Linux::Capable::Computer']]], Str) ($maybe_computers, $hostname) {
        # Do something here
    }

    install_gentoo([$computer1, $computer2], 'Tux');

=head1 DESCRIPTION

This module allows you to validate your non-anonymous subs using the powerful attribute syntax of Perl, bringing easy type-checks to
your code, thanks to L<Type::Tiny> you can create your own types to enforce your program using the data you expect it to use.

=head1 INSTANCE METHODS

This module cannot and shouldn't be instanced.

=head1 ATTRIBUTES

=head2 Requires

    sub say_word: Requires(Str) {
        say shift;
    }

    sub say_word_with_spec: Requires(\%spec, Str) {
        say shift;
    }

Receives a list of L<Type::Tiny> types and enforces those types into the arguments, the first argument may be a HashRef containing the
spec of L<Type::Params> to change the behavior of this module, for example {strictness => 0} as the first argument will allow the user
to have more arguments than the ones declared.

=head2 anon_requires

    my $say_thing = anon_requires(sub($thing) {
        say $thing;
    ), Str);

    my $say_thing = anon_requires(sub($thing) {
        say $thing;
    }, \%spec, Str);

Enforces types into anonymous subroutines since those cannot be enchanted using attributes.

=head1 DEPENDENCIES

The module will pull all the dependencies it needs on install, the minimum supported Perl is v5.16.3, although latest versions are mostly tested for 5.38.2

=head1 CONFIGURATION AND ENVIRONMENT

If your OS Perl is too old perlbrew can be used instead.

=head1 BUGS AND LIMITATIONS

Enchanting anonymous subroutines with attributes won't allow them to be used by this module because of limitations of the language.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2025 Sergio Iglesias

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the " Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice (including the next paragraph) shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=head1 CREDITS

Thanks to MultiSafePay and the Tech Leader of MultiSafePay for agreeing in creating this CPAN module inspired in a similar feature in their codebase, this code was inspired by code found there, but was
written without the code in front from scratch.

MultiSafePay is searching for Perl Developers for working in their offices on Estepona on Spain next to the beach, if you apply and do not get a reply and you think you are a 
experienced/capable enough Perl Developer drop me a e-mail so I can try to help you get a job L<mailto:sergioxz@cpan.org>.

=head1 INCOMPATIBILITIES

None known.

=head1 VERSION

0.0.x

=head1 AUTHOR

Sergio Iglesias

=cut
