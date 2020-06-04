package Data::Sah::Filter;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-04'; # DATE
our $DIST = 'Data-Sah-Filter'; # DIST
our $VERSION = '0.008'; # VERSION

use strict 'subs', 'vars';
use warnings;
no warnings 'once';
use Log::ger;

use Data::Sah::FilterCommon;

use Exporter qw(import);
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
                if ($rt eq 'val') {
                    $code_filter .= "    my \$tmp; " unless $has_defined_tmp++;
                    $code_filter .= "    \$tmp = $rule->{expr_filter}; return undef if \$tmp->[0]; ";
                } else {
                    $code_filter .= "    \$data = $rule->{expr_filter}; return \$data if \$data->[0]; ";
                }
            } else {
                if ($rt eq 'val') {
                    $code_filter .= "    \$data = $rule->{expr_filter}; ";
                } else {
                    $code_filter .= "    \$data = [undef, $rule->{expr_filter}]; ";
                }
            }
        }

        $code = join(
            "",
            $code_require,
            "sub {\n",
            "    my \$data = shift;\n",
            "    unless (defined \$data) {\n",
            "        ", ($rt eq 'val' ? "return undef;" :
                             "return [undef, undef];" # str_errmsg+val
                         ), "\n",
            "    }\n",
            $code_filter, "\n",
            "    \$data;\n",
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

    my $filter = eval $code;
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

This document describes version 0.008 of Data::Sah::Filter (from Perl distribution Data-Sah-Filter), released on 2020-06-04.

=head1 SYNOPSIS

 use Data::Sah::Filter qw(gen_filter);

 # a utility routine: gen_filter
 my $c = gen_filter(
     filter_names       => ['Str::ltrim', 'Str::rtrim'],
 );

 my $val = $c->("foo");        # unchanged, "foo"
 my $val = $c->(" foo ");      # "foo"

=head1 DESCRIPTION

This distribution contains a standard set of filter rules for L<Data::Sah> (to
be used in C<prefilters> and C<postfilter> cause). It is separated from the
C<Data-Sah> distribution and can be used independently.

A filter rule is put in C<Data::Sah::Filter::$COMPILER::$CATEGORY:$DESCRIPTION>
module, for example: L<Data::Sah::Filter::perl::Str::trim> for trimming
whitespace at the beginning and end of string.

Basically, a filter rule will provide an expression (C<expr_filter>) to convert
data to another. Multiple filter rules will be combined to form the final
filtering code.

The filter rule module must contain C<meta> subroutine which must return a
hashref (L<DefHash>) that has the following keys (C<*> marks that the key is
required):

=over

=item * v* => int (default: 1)

Metadata specification version. From L<DefHash>. Currently at 1.

=item * summary => str

From L<DefHash>.

=back

The filter rule module must also contain C<filter> subroutine which must
generate the code for filtering. The subroutine must accept a hash of arguments
(C<*> indicates required arguments):

=over

=item * data_term => str

=back

The C<filter> subroutine must return a hashref with the following keys (C<*>
indicates required keys):

=over

=item * might_fail => bool

Whether coercion might fail, e.g. because of invalid input. If set to 1,
C<expr_filter> key that the C<filter()> routine returns must be an expression
that returns an array (envelope) of C<< (error_msg, data) >> instead of just
filtered data. Error message should be a string that is set when filtering fails
and explains why. Otherwise, if filtering succeeds, the error message string
should be set to undefined value.

This is used for filtering rules that act as a data checker.

=item * expr_filter => str

Expression in the target language to actually convert data.

=item * modules => hash

A list of modules required by the expression.

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

=item * B<return_type> => I<str> (default: "val")


=back

Return value:  (any)

=head1 ENVIRONMENT

=head2 LOG_SAH_FILTER_CODE => bool

Set default for C<$Log_Filter_Code>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Filter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Filter>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Filter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

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

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
