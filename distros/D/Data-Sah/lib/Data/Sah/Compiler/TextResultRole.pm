package Data::Sah::Compiler::TextResultRole;

our $DATE = '2019-07-19'; # DATE
our $VERSION = '0.897'; # VERSION

use 5.010;
use strict;
use warnings;

use Mo qw(default);
use Role::Tiny;

# can be changed to tab, for example
has indent_character => (is => 'rw', default => sub {''});

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

This document describes version 0.897 of Data::Sah::Compiler::TextResultRole (from Perl distribution Data-Sah), released on 2019-07-19.

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
