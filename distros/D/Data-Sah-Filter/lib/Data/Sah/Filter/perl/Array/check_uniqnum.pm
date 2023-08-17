package Data::Sah::Filter::perl::Array::check_uniqnum;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-06-21'; # DATE
our $DIST = 'Data-Sah-Filter'; # DIST
our $VERSION = '0.021'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'Check that an array has unique elements, using List::Util\'s uniqnum()',
        target_type => 'array',
        might_fail => 1,
        args => {
            reverse => {
                summary => 'If set to true, then will *fail* when array is unique',
                schema => 'bool*',
            },
        },
        examples => [
            {value=>[], valid=>1},
            {value=>[1,2], valid=>1},
            {value=>[1,2,"1.0"], valid=>0},

            {value=>[], filter_args=>{reverse=>1}, valid=>0},
            {value=>[1,2], filter_args=>{reverse=>1}, valid=>0},
            {value=>[1,2,"1.0"], filter_args=>{reverse=>1}, valid=>1},
        ],
    };
}

sub filter {
    my %fargs = @_;

    my $dt = $fargs{data_term};
    my $gen_args = $fargs{args} // {};
    my $res = {};
    $res->{modules}{'List::Util::Uniq'} = "0.005";
    $res->{modules}{'Data::Dmp'} = "0.242";
    $res->{expr_filter} = join(
        "",
        "do { my \$orig = $dt; \$tmp=".($gen_args->{ci} ? "[map {lc} \@\$orig]":"$dt")."; my \@dupes = List::Util::Uniq::uniqnum( List::Util::Uniq::dupenum(\@\$tmp) ); ",
        ($gen_args->{reverse} ? "\@dupes ? [undef,\$tmp] : [\"Array does not have duplicate number(s)\"]" : "!\@dupes ? [undef,\$tmp] : [\"Array has duplicate number(s): \".join(', ', map { Data::Dmp::dmp(\$_) } \@dupes)]"),
        "}",
    );

    $res;
}

1;
# ABSTRACT: Check that an array has unique elements, using List::Util's uniqnum()

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Array::check_uniqnum - Check that an array has unique elements, using List::Util's uniqnum()

=head1 VERSION

This document describes version 0.021 of Data::Sah::Filter::perl::Array::check_uniqnum (from Perl distribution Data-Sah-Filter), released on 2023-06-21.

=head1 SYNOPSIS

=head2 Using in Sah schema's C<prefilters> (or C<postfilters>) clause

 ["array","prefilters",[["Array::check_uniqnum"]]]

=head2 Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 
 my $schema = ["array","prefilters",[["Array::check_uniqnum"]]];
 my $validator = gen_validator($schema);
 if ($validator->($some_data)) { print 'Valid!' }

=head2 Using with L<Data::Sah:Filter> directly:

 use Data::Sah::Filter qw(gen_filter);

 my $filter = gen_filter([["Array::check_uniqnum"]]);
 # $errmsg will be empty/undef when filtering succeeds
 my ($errmsg, $filtered_value) = $filter->($some_data);

=head2 Sample data and filtering results

 [] # valid, unchanged
 [1,2] # valid, unchanged
 [1,2,"1.0"] # INVALID (Array has duplicate number(s): "1.0"), becomes undef
 [] # filtered with args {reverse=>1}, INVALID (Array does not have duplicate number(s)), becomes undef
 [1,2] # filtered with args {reverse=>1}, INVALID (Array does not have duplicate number(s)), becomes undef
 [1,2,"1.0"] # filtered with args {reverse=>1}, valid, unchanged

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Filter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Filter>.

=head1 SEE ALSO

L<Data::Sah::Filter::perl::Array::uniqnum>.

L<Data::Sah::Filter::perl::Array::check_uniq>,
L<Data::Sah::Filter::perl::Array::check_uniqstr>

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

This software is copyright (c) 2023, 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Filter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
