package Data::Sah::Filter;

use strict 'subs', 'vars';
use warnings;
no warnings 'once';
use Log::ger;

use Data::Sah::FilterCommon;
use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-17'; # DATE
our $DIST = 'Data-Sah-Filter'; # DIST
our $VERSION = '0.024'; # VERSION

our @EXPORT_OK = qw(gen_filter);

our %SPEC;

our $Log_Filter_Code = $ENV{LOG_SAH_FILTER_CODE} // 0;

$SPEC{gen_filter} = {
    v => 1.1,
    summary => 'Generate filter code',
    description => <<'_',

This is mostly for testing. Normally the filter rules will be used from
<pm:Data::Sah>.

_
    args => {
        %Data::Sah::FilterCommon::gen_filter_args,
    },
    result_naked => 1,
};
sub gen_filter {
    my %args = @_;

    my $rt = $args{return_type} // 'val';

    my $rules = Data::Sah::FilterCommon::get_filter_rules(
        %args,
        compiler=>'perl',
        data_term=>'$data',
    );

    my $code;
    if (@$rules) {
        my $code_require = '';
        my %mem;
        for my $rule (@$rules) {
            next unless $rule->{modules};
            for my $mod (keys %{$rule->{modules}}) {
                next if $mem{$mod}++;
                $code_require .= "require $mod;\n";
            }
        }

        my $code_filter = "";
        my $has_defined_tmp;
        for my $rule (@$rules) {
            if ($rule->{meta}{might_fail}) {
                $code_filter .= "    my \$tmp;\n" unless $has_defined_tmp++;
                $code_filter .= "    \$tmp = $rule->{expr_filter};\n";
                if ($rt eq 'val') {
                    $code_filter .= "    return undef if \$tmp->[0];\n";
                } else {
                    $code_filter .= "    return \$tmp if \$tmp->[0];\n";
                }
                $code_filter .= "    \$data = \$tmp->[1];\n";
            } else {
                $code_filter .= "    \$data = $rule->{expr_filter};\n";
            }
        }

        $code = join(
            "",
            $code_require,
            "sub {\n",
            "    my \$data = shift;\n",
            "    unless (defined \$data) {\n",
            "        return ", ($rt eq 'val' ? "undef" : "[undef, undef]"), "\n",
            "    }\n",
            $code_filter, "\n",
            "    ", ($rt eq 'val' ? "\$data" : "[undef, \$data]"), ";\n",
            "}",
        );
    } else {
        if ($rt eq 'val') {
            $code = 'sub { $_[0] }';
        } else {
            $code = 'sub { [undef, $_[0]] }';
        }
    }

    if ($Log_Filter_Code) {
        log_trace("Filter code (gen args: %s): %s", \%args, $code);
    }

    return $code if $args{source};

    my $filter = eval $code; ## no critic: BuiltinFunctions::ProhibitStringyEval
    die if $@;
    $filter;
}

1;
# ABSTRACT: Filtering for Data::Sah

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter - Filtering for Data::Sah

=head1 VERSION

This document describes version 0.024 of Data::Sah::Filter (from Perl distribution Data-Sah-Filter), released on 2024-01-17.

=head1 SYNOPSIS

 use Data::Sah::Filter qw(gen_filter);

 # a utility routine: gen_filter
 my $c = gen_filter(
     filter_names       => ['Str::ltrim', 'Str::rtrim'],
 );

 my $val = $c->("foo");        # unchanged, "foo"
 my $val = $c->(" foo ");      # "foo"

Another example:

 my $c = gen_filter(
     filter_names       => [ ['Str::remove_comment' => {style=>'shell'}] ],
     #filter_names      => ['Str::remove_comment=style,shell'], # same as above
 );

=head1 DESCRIPTION

This distribution contains a standard set of filter rules for L<Data::Sah> (to
be used in C<prefilters> and C<postfilters> clauses). It is separated from the
C<Data-Sah> distribution and can be used independently.

A filter rule is put in C<Data::Sah::Filter::$COMPILER::$CATEGORY:$DESCRIPTION>
module, for example: L<Data::Sah::Filter::perl::Str::trim> for trimming
whitespace at the beginning and end of string.

Basically, a filter rule will provide an expression (in C<expr_filter>) in the
target language (e.g. Perl, JavaScript, or others) to convert one data to
another. Multiple filter rules can be combined to form the final filtering code.
This code can be used by C<Data::Sah> when generating validator code from L<Sah>
schema, or can be used directly. Some projects which use filtering rules
directly include: L<App::orgadb> (which lets users specify filters from the
command-line).

=head2 meta()

The filter rule module must contain C<meta> subroutine which must return a
hashref (L<DefHash>) that has the following keys (C<*> marks that the key is
required):

=over

=item * v* => int (default: 1)

Metadata specification version. From L<DefHash>. Currently at 1.

=item * summary => str

From L<DefHash>.

=item * might_fail => bool

Whether coercion might fail, e.g. because of invalid input. If set to 1,
C<expr_filter> key that the C<filter()> routine returns must be an expression
that returns an array (envelope) of C<< (error_msg, data) >> instead of just
filtered data. Error message should be a string that is set when filtering fails
and explains why. Otherwise, if filtering succeeds, the error message string
should be set to undefined value.

This is used for filtering rules that act as a data checker.

=item * args => hash

List of arguments that this filter accepts, in the form of hash where hash keys
are argument names and hash values are argument specifications. Argument
specification is a L<DefHash> similar to argument specification for functions in
L<Rinci::function> specification.

=back

=head2 filter()

The filter rule module must also contain C<filter> subroutine which must
generate the code for filtering. The subroutine must accept a hash of arguments
and will be passed these:

=over

=item * data_term => str

=item * args => hash

The arguments for the filter. Hash keys will contain the argument names, while
hash values will contain the argument's values.

=back

The C<filter> subroutine must return a hashref with the following keys (C<*>
indicates required keys):

=over

=item * expr_filter* => str

Expression in the target language to actually convert data.

=item * modules => hash

A list of modules required by the expression, where hash keys are module names
and hash values are modules' minimum versions.

=back

Basically, the C<filter> subroutine must generate a code that accepts a
non-undef data and must convert this data to the desired value.

Program/library that uses L<Data::Sah::Filter> can collect rules from the rule
modules then compose them into the final code, something like (in pseudo-Perl
code):

 if (!defined $data) {
   return undef;
 } else {
   $data = expr-filter-from-rule1($data);
   $data = expr-filter-from-rule2($data);
   ...
   return $data;
 }

=head2 Filter modules included in this distribution

=over

=item 1. L<Data::Sah::Filter::js::Str::downcase>

=item 2. L<Data::Sah::Filter::js::Str::lc>

=item 3. L<Data::Sah::Filter::js::Str::lcfirst>

=item 4. L<Data::Sah::Filter::js::Str::lowercase>

=item 5. L<Data::Sah::Filter::js::Str::ltrim>

=item 6. L<Data::Sah::Filter::js::Str::rtrim>

=item 7. L<Data::Sah::Filter::js::Str::trim>

=item 8. L<Data::Sah::Filter::js::Str::uc>

=item 9. L<Data::Sah::Filter::js::Str::ucfirst>

=item 10. L<Data::Sah::Filter::js::Str::upcase>

=item 11. L<Data::Sah::Filter::js::Str::uppercase>

=item 12. L<Data::Sah::Filter::perl::Array::check_uniq>

=item 13. L<Data::Sah::Filter::perl::Array::check_uniqnum>

=item 14. L<Data::Sah::Filter::perl::Array::check_uniqstr>

=item 15. L<Data::Sah::Filter::perl::Array::remove_undef>

=item 16. L<Data::Sah::Filter::perl::Array::uniq>

=item 17. L<Data::Sah::Filter::perl::Array::uniqnum>

=item 18. L<Data::Sah::Filter::perl::Array::uniqstr>

=item 19. L<Data::Sah::Filter::perl::Float::ceil>

=item 20. L<Data::Sah::Filter::perl::Float::check_has_fraction>

=item 21. L<Data::Sah::Filter::perl::Float::check_int>

=item 22. L<Data::Sah::Filter::perl::Float::floor>

=item 23. L<Data::Sah::Filter::perl::Float::round>

=item 24. L<Data::Sah::Filter::perl::Str::check>

=item 25. L<Data::Sah::Filter::perl::Str::check_lowercase>

=item 26. L<Data::Sah::Filter::perl::Str::check_oneline>

=item 27. L<Data::Sah::Filter::perl::Str::check_uppercase>

=item 28. L<Data::Sah::Filter::perl::Str::downcase>

=item 29. L<Data::Sah::Filter::perl::Str::ensure_trailing_newline>

=item 30. L<Data::Sah::Filter::perl::Str::lc>

=item 31. L<Data::Sah::Filter::perl::Str::lcfirst>

=item 32. L<Data::Sah::Filter::perl::Str::lowercase>

=item 33. L<Data::Sah::Filter::perl::Str::ltrim>

=item 34. L<Data::Sah::Filter::perl::Str::oneline>

=item 35. L<Data::Sah::Filter::perl::Str::remove_comment>

=item 36. L<Data::Sah::Filter::perl::Str::remove_non_latin_alphanum>

=item 37. L<Data::Sah::Filter::perl::Str::remove_nondigit>

=item 38. L<Data::Sah::Filter::perl::Str::remove_whitespace>

=item 39. L<Data::Sah::Filter::perl::Str::replace_map>

=item 40. L<Data::Sah::Filter::perl::Str::rtrim>

=item 41. L<Data::Sah::Filter::perl::Str::trim>

=item 42. L<Data::Sah::Filter::perl::Str::try_center>

=item 43. L<Data::Sah::Filter::perl::Str::uc>

=item 44. L<Data::Sah::Filter::perl::Str::ucfirst>

=item 45. L<Data::Sah::Filter::perl::Str::underscore_non_latin_alphanum>

=item 46. L<Data::Sah::Filter::perl::Str::underscore_non_latin_alphanums>

=item 47. L<Data::Sah::Filter::perl::Str::upcase>

=item 48. L<Data::Sah::Filter::perl::Str::uppercase>

=item 49. L<Data::Sah::Filter::perl::Str::wrap>

=back

=head1 VARIABLES

=head2 $Log_Filter_Code => bool (default: from ENV or 0)

If set to true, will log the generated filter code (currently using L<Log::ger>
at trace level). To see the log message, e.g. to the screen, you can use
something like:

 % TRACE=1 perl -MLog::ger::LevelFromEnv -MLog::ger::Output=Screen \
     -MData::Sah::Filter=gen_filter -E'my $c = gen_filter(...)'

=head1 FUNCTIONS


=head2 gen_filter

Usage:

 gen_filter(%args) -> any

Generate filter code.

This is mostly for testing. Normally the filter rules will be used from
L<Data::Sah>.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filter_names>* => I<array[str]>

(No description)

=item * B<return_type> => I<str> (default: "val")

(No description)


=back

Return value:  (any)

=for Pod::Coverage ^(.+)$

=head1 ENVIRONMENT

=head2 LOG_SAH_FILTER_CODE => bool

Set default for C<$Log_Filter_Code>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Filter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Filter>.

=head1 SEE ALSO

L<Data::Sah>

L<Data::Sah::FilterJS>

L<App::SahUtils>, including L<filter-with-sah> to conveniently test filter from
the command-line.

L<Data::Sah::Coerce>. Filtering works very similarly to coercion in the
L<Data::Sah> framework (see l<Data::Sah::Coerce>) but is simpler and composited
differently to form the final filtering code. Mainly, input data will be passed
to all filtering expressions.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2023, 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Filter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
