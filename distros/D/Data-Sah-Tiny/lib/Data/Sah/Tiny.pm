package Data::Sah::Tiny;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-01'; # DATE
our $DIST = 'Data-Sah-Tiny'; # DIST
our $VERSION = '0.000001'; # VERSION

use 5.010001;
use strict 'refs', 'vars';
use warnings;
use Log::ger;

use Data::Sah::Normalize qw(normalize_schema);

use Exporter qw(import);
our @EXPORT_OK = qw(gen_validator normalize_schema);

# data_term must already be set
sub _gen_expr {
    my ($schema0, $opts) = @_;

    my $nschema = $opts->{schema_is_normalized} ?
        $schema0 : normalize_schema($schema0);
    log_trace "normalized schema: %s", $nschema;
    my $type = $nschema->[0];
    my $clset = { %{$nschema->[1]} };
    my $dt = $opts->{data_term};

    my ($default_expr, $success_if_undef_expr, @check_exprs);

    require Data::Dmp;

    # first, handle 'default'
    if (exists $clset->{default}) {
        $default_expr = "$dt = defined($dt) ? $dt : ".
            Data::Dmp::dmp($clset->{default});
        delete $clset->{default};
    }

    # then handle 'req' & 'forbidden'
    if (delete $clset->{req}) {
        push @check_exprs, "defined($dt)";
    } elsif (delete $clset->{forbidden}) {
        $success_if_undef_expr = "!defined($dt)";
        push @check_exprs, "!defined($dt)";
    } else {
        $success_if_undef_expr = "!defined($dt)";
    }

  PROCESS_BUILTIN_TYPES: {
        if ($type eq 'int') {
            push @check_exprs, "!ref($dt) && $dt =~ /\\A-?[0-9]+\\z/";
            if (defined(my $val = delete $clset->{min})) { push @check_exprs, "$dt >= $val" }
            if (defined(my $val = delete $clset->{max})) { push @check_exprs, "$dt <= $val" }
        } elsif ($type eq 'str') {
            push @check_exprs, "!ref($dt)";
            if (defined(my $val = delete $clset->{min_len})) { push @check_exprs, "length $dt >= $val" }
            if (defined(my $val = delete $clset->{max_len})) { push @check_exprs, "length $dt <= $val" }
        } elsif ($type eq 'array') {
            push @check_exprs, "ref($dt) eq 'ARRAY'";
            if (defined(my $val = delete $clset->{min_len})) { push @check_exprs, "\@{$dt} >= $val" }
            if (defined(my $val = delete $clset->{max_len})) { push @check_exprs, "\@{$dt} <= $val" }
            if (defined(my $val = delete $clset->{of})) {
                my $expr = _gen_expr($val, {data_term => "\$_dst_elem"});
                push @check_exprs, "do { my \$ok=1; for my \$_dst_elem (\@{$dt}) { (\$ok=0, last) unless $expr } \$ok }";
            }
        } else {
            die "Unknown type '$type'";
        }

        if (keys %$clset) {
            die "Unknown clause(s) for type '$type': ".
                join(", ", sort keys %$clset);
        }
    }

    my $expr = join(
        "",
        ($default_expr ? "( (($default_expr), 1), " : ""),
        ($success_if_undef_expr ? "$success_if_undef_expr || (" : ""),
        join(" && ", map { "($_)" } @check_exprs),
        ($success_if_undef_expr ? ")" : ""),
        ($default_expr ? ")" : ""),
    );

    if ($opts->{hash}) {
        return {
            v => 2,
            result => $expr,
            modules => [],
            vars => {},
        };
    } else {
        return $expr;
    }
}

sub gen_validator {
    my ($schema, $opts0) = @_;
    $opts0 //= {};

    my $opts = {};
    $opts->{schema_is_normalized} = delete $opts0->{schema_is_normalized};
    $opts->{source} = delete $opts0->{source};
    $opts->{hash} = delete $opts0->{hash};
    $opts->{return_type} = delete $opts0->{return_type} // "bool_valid";
    $opts->{return_type} =~ /\A(bool_valid\+val|bool_valid)\z/
        or die "return_type must be bool_valid or bool_valid+val";
    $opts->{data_term} = delete $opts0->{data_term} // '$tmp';
    keys %$opts0 and die "Unknown option(s): ".join(", ", sort keys %$opts0);

    my $dt = $opts->{data_term};

    my $expr = _gen_expr($schema, $opts);
    return $expr if $opts->{hash};
    my $src = join(
        "",
        "sub { ",
        "my $dt = shift; ",
        ($opts->{return_type} eq 'bool_valid+val' ? "my \$_dst_res = $expr; [\$_dst_res, $dt]" : $expr),
        " }",
    );
    return $src if $opts->{source};

    my $code = eval $src;
    die if $@;
    $code;
}

1;
# ABSTRACT: Validate Sah schemas with as little code as possible

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Tiny - Validate Sah schemas with as little code as possible

=head1 VERSION

This document describes version 0.000001 of Data::Sah::Tiny (from Perl distribution Data-Sah-Tiny), released on 2021-08-01.

=head1 SYNOPSIS

 use Data::Sah::Tiny qw(normalize_schema gen_validator);

 my $v = gen_validator([int => min=>1]);
 say $v->(0); # false
 say $v->(2); # true

=head1 DESCRIPTION

B<Early release. Not all types and clauses are supported.>

This is a tiny alternative to L<Data::Sah>, with fewer dependencies and much
faster compilation speed. But it supports only a subset of Data::Sah's features.

=head1 PERFORMANCE NOTES

Validator generation is several times faster than Data::Sah, so L<Params::Sah>
with L<Data::Sah::Tiny> backend is in the same order of magnitude with other
validator generators like L<Type::Params> and L<Params::ValidationCompiler>.
See L<Bencher::Scenarios::ParamsSah>.

=head1 FUNCTIONS

=head2 gen_validator($sch[, \%opts ]) => code|str

See L<Data::Sah>'s documentation. Supported options:

=over

=item * schema_is_normalized

Bool.

=item * return_type

Str. Only "bool_valid" and "bool_valid+val" are supported.

=item * data_term

Str. Defaults to C<$_[0]>.

=item * source

Bool. Set to 1 to return source code instead of compiled coderef.

=item * hash*

Bool. If set to 1 will return compilation result details.

=back

=head2 normalize_schema

See L<Data::Sah::Normalize>'s documentation.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Tiny>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Tiny>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Tiny>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
