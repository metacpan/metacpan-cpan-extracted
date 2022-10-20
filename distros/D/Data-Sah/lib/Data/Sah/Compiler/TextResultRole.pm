package Data::Sah::Compiler::TextResultRole;

use 5.010;
use strict;
use warnings;

use Mo qw(default);
use Role::Tiny;

# can be changed to tab, for example
has indent_character => (is => 'rw', default => sub {''});

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-19'; # DATE
our $DIST = 'Data-Sah'; # DIST
our $VERSION = '0.914'; # VERSION

sub add_result {
    my ($self, $cd, @args) = @_;

    $cd->{result} //= [];
    push @{ $cd->{result} }, $self->indent($cd, join("", @args));
    $self;
}

# BEGIN COPIED FROM String::Indent
sub _indent {
    my ($indent, $str, $opts) = @_;
    $opts //= {};

    my $ibl = $opts->{indent_blank_lines} // 1;
    my $fli = $opts->{first_line_indent} // $indent;
    my $sli = $opts->{subsequent_lines_indent} // $indent;
    #say "D:ibl=<$ibl>, fli=<$fli>, sli=<$sli>";

    my $i = 0;
    $str =~ s/^([^\r\n]?)/$i++; !$ibl && !$1 ? "$1" : $i==1 ? "$fli$1" : "$sli$1"/egm;
    $str;
}
# END COPIED FROM String::Indent

sub indent {
    my ($self, $cd, $str) = @_;
    _indent(
        $self->indent_character x $cd->{indent_level},
        $str,
    );
}

sub inc_indent {
    my ($self, $cd) = @_;
    $cd->{indent_level}++;
}

sub dec_indent {
    my ($self, $cd) = @_;
    $cd->{indent_level}--;
}

sub indent_str {
    my ($self, $cd) = @_;
    $self->indent_character x $cd->{indent_level};
}

1;
# ABSTRACT: Role for compilers that produce text result (array of lines)

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Compiler::TextResultRole - Role for compilers that produce text result (array of lines)

=head1 VERSION

This document describes version 0.914 of Data::Sah::Compiler::TextResultRole (from Perl distribution Data-Sah), released on 2022-10-19.

=head1 ATTRIBUTES

=head2 indent_character => STR

=head1 METHODS

=head2 $c->add_result($cd, @arg)

Append result to C<< $cd->{result} >>. Will use C<< $cd->{indent_level} >> to
indent the line. Used by compiler; users normally do not need this.

=head2 $c->inc_indent($cd)

Increase indent level. This is done by increasing C<< $cd->{indent_level} >> by
1.

=head2 $c->dec_indent($cd)

Decrease indent level. This is done by decreasing C<< $cd->{indent_level} >> by
1.

=head2 $c->indent_str($cd)

Shortcut for C<< $c->indent_character x $cd->{indent_level} >>.

=head2 $c->indent($cd, $str) => STR

Indent each line in $str with indent_str and return the result.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah>.

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

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
