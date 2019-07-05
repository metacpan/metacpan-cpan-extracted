package Data::Sah::Util::Role;

our $DATE = '2019-07-04'; # DATE
our $VERSION = '0.896'; # VERSION

use 5.010;
use strict 'subs', 'vars';
use warnings;
#use Log::Any '$log';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       has_clause has_clause_alias
                       has_func   has_func_alias
               );

sub has_clause {
    my ($name, %args) = @_;
    my $caller = caller;
    my $into   = $args{into} // $caller;

    my $v = $args{v} // 1;
    if ($v != 2) {
        die "Declaration of clause '$name' still follows version $v ".
            "(2 expected), please make sure $caller is the latest version";
    }

    if ($args{code}) {
        *{"$into\::clause_$name"} = $args{code};
    } else {
        eval "package $into; use Role::Tiny; ".
            "requires 'clause_$name';";
    }
    *{"$into\::clausemeta_$name"} = sub {
        state $meta = {
            names        => [$name],
            tags         => $args{tags},
            prio         => $args{prio} // 50,
            schema       => $args{schema},
            allow_expr   => $args{allow_expr},
            attrs        => $args{attrs} // {},
            inspect_elem => $args{inspect_elem},
            subschema    => $args{subschema},
        };
        $meta;
    };
    has_clause_alias($name, $args{alias}  , $into);
    has_clause_alias($name, $args{aliases}, $into);
}

sub has_clause_alias {
    my ($name, $aliases, $into) = @_;
    my $caller   = caller;
    $into      //= $caller;
    my @aliases = !$aliases ? () :
        ref($aliases) eq 'ARRAY' ? @$aliases : $aliases;
    my $meta = $into->${\("clausemeta_$name")};

    for my $alias (@aliases) {
        push @{ $meta->{names} }, $alias;
        eval
            "package $into;".
            "sub clause_$alias { shift->clause_$name(\@_) } ".
            "sub clausemeta_$alias { shift->clausemeta_$name(\@_) } ";
        $@ and die "Can't make clause alias $alias -> $name: $@";
    }
}

sub has_func {
    my ($name, %args) = @_;
    my $caller = caller;
    my $into   = $args{into} // $caller;

    if ($args{code}) {
        *{"$into\::func_$name"} = $args{code};
    } else {
        eval "package $into; use Role::Tiny; requires 'func_$name';";
    }
    *{"$into\::funcmeta_$name"} = sub {
        state $meta = {
            names => [$name],
            args  => $args{args},
        };
        $meta;
    };
    my @aliases =
        map { (!$args{$_} ? () :
                   ref($args{$_}) eq 'ARRAY' ? @{ $args{$_} } : $args{$_}) }
            qw/alias aliases/;
    has_func_alias($name, $args{alias}  , $into);
    has_func_alias($name, $args{aliases}, $into);
}

sub has_func_alias {
    my ($name, $aliases, $into) = @_;
    my $caller   = caller;
    $into      //= $caller;
    my @aliases = !$aliases ? () :
        ref($aliases) eq 'ARRAY' ? @$aliases : $aliases;
    my $meta = $into->${\("funcmeta_$name")};

    for my $alias (@aliases) {
        push @{ $meta->{names} }, $alias;
        eval
            "package $into;".
            "sub func_$alias { shift->func_$name(\@_) } ".
            "sub funcmeta_$alias { shift->funcmeta_$name(\@_) } ";
        $@ and die "Can't make func alias $alias -> $name: $@";
    }
}

1;
# ABSTRACT: Sah utility routines for roles

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Util::Role - Sah utility routines for roles

=head1 VERSION

This document describes version 0.896 of Data::Sah::Util::Role (from Perl distribution Data-Sah), released on 2019-07-04.

=head1 DESCRIPTION

This module provides some utility routines to be used in roles, e.g.
C<Data::Sah::Type::*> and C<Data::Sah::FuncSet::*>.

=head1 FUNCTIONS

=head2 has_clause($name, %opts)

Define a clause. Used in type roles (C<Data::Sah::Type::*>). Internally it adds
a L<Moo> C<requires> for C<clause_$name>.

Options:

=over 4

=item * v => int

Specify clause specification version. Must be 2 (the current version).

=item * schema => sah::schema

Define schema for clause value.

=item * prio => int {min=>0, max=>100, default=>50}

Optional. Default is 50. The higher the priority (the lower the number), the
earlier the clause will be processed.

=item * aliases => \@aliases OR $alias

Define aliases. Optional.

=item * inspect_elem => bool

If set to true, then this means clause inspect the element(s) of the data. This
is only relevant for types that has elements (see L<HasElems
role|Data::Sah::Type::HasElems>). An example of clause like this is C<has> or
C<each_elem>. When the value of C<inspect_elem> is true, a compiler must prepare
by coercing the elements of the data, if there are coercion rules applicable.

=item * subschema => coderef

If set, then declare that the clause value contains a subschema. The coderef
must provide a way to get the subschema from

=item * code => coderef

Optional. Define implementation for the clause. The code will be installed as
'clause_$name'.

=item * into => str $package

By default it is the caller package, but can be set to other package.

=back

Example:

 has_clause minimum => (arg => 'int*', aliases => 'min');

=head2 has_clause_alias TARGET => ALIAS | [ALIAS1, ...]

Specify that clause named ALIAS is an alias for TARGET.

You have to define TARGET clause first (see B<has_clause> above).

Example:

 has_clause max_length => ...;
 has_clause_alias max_length => "max_len";

=head2 has_func($name, %opts)

Define a Sah function. Used in function set roles (C<Data::Sah::FuncSet::*>).
Internally it adds a L<Moo> C<requires> for C<func_$name>.

Options:

=over 4

=item * aliases => \@aliases OR $alias

Optional. Declare aliases.

=item * code => $code

Supply implementation for the function. The code will be installed as
'func_$name'.

=item * into => $package

By default it is the caller package, but can be set to other package.

=back

Example:

 has_func abs => (args => 'num');

=head2 has_func_alias TARGET => ALIAS | [ALIASES...]

Specify that function named ALIAS is an alias for TARGET.

You have to specify TARGET function first (see B<has_func> above).

Example:

 has_func_alias 'atan' => 'arctan';

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
