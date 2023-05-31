package Data::Section::Seekable::Writer;

use 5.010001;
use strict;
use warnings;

use overload
    '""'  => 'as_string',
    ;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-03-24'; # DATE
our $DIST = 'Data-Section-Seekable'; # DIST
our $VERSION = '0.092'; # VERSION

sub new {
    my $class = shift;

    my $self = bless {@_}, $class;
    $self->empty;
    $self->{header} //= sub {
        my ($self, $name, $content, $extra) = @_;
        "### $name ###\n";
    };
    $self;
}

sub empty {
    my $self = shift;
    $self->{_toc} = [];
    $self->{_content} = '';
    $self->{_part_names} = {};
}

sub header {
    my $self = shift;
    $self->{header} = $_[0] if @_;
    $self->{header};
}

sub add_part {
    my ($self, $name, $content, $extra) = @_;
    die "Name cannot be empty" unless length($name);
    die "Name cannot contain comma/newline" if $name =~ /,|\R/;
    die "Extra cannot contain newline" if defined($extra) && $extra =~ /\R/;

    die "Duplicate part name '$name'" if $self->{_part_names}{$name}++;

    my $header;
    if (ref($self->{header}) eq 'CODE') {
        $header = $self->{header}->($self, $name, $content, $extra);
    } else {
        $header = $self->{header};
    }
    $self->{_content} .= $header if defined($header);

    push @{ $self->{_toc} }, [
        $name,
        length($self->{_content}),
        length($content),
        $extra,
    ];
    $self->{_content} .= $content;
}

sub as_string {
    my $self = shift;

    join(
        "",
        "Data::Section::Seekable v1\n",
        (map {"$_->[0],$_->[1],$_->[2]".(defined($_->[3]) ? ",$_->[3]":"")."\n"}
             @{ $self->{_toc} }),
        "\n",
        $self->{_content},
    );
}

1;
# ABSTRACT: Generate data section with multiple parts

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Section::Seekable::Writer - Generate data section with multiple parts

=head1 VERSION

This document describes version 0.092 of Data::Section::Seekable::Writer (from Perl distribution Data-Section-Seekable), released on 2023-03-24.

=head1 SYNOPSIS

In your script:

 use Data::Section::Seekable::Writer;

 my $writer = Data::Section::Seekable::Writer->new;

 $writer->add_part(part1 => "This is part1\n");
 $writer->add_part(part2 => "This is part\ntwo\n", "very,important");
 print "__DATA__\n", $writer;

will print:

 __DATA__
 Data::Section::Seekable v1
 part1,0,14
 part2,14,17,very,important

 This is part1
 This is part
 two

If we add a header before printing:

 $writer->header(sub { my ($writer, $name, $content, $extra) = @_; "### $name ###\n"});
 print "__DATA__\n", $writer;

then the output will be:

 __DATA__
 Data::Section::Seekable v1
 part1,14,14
 part2,42,17,very,important

 ### part1 ###
 This is part1
 ### part2 ###
 This is part
 two

=head1 DESCRIPTION

This class lets you generate data section which can contain multiple part in the
format described by L<Data::Section::Seekable>.

=head1 METHODS

=head2 new(%attrs) => obj

Constructor. Attributes:

=over

=item * header => str|code (default: code to list filename)

Header string (or code which should return a string) to add before each part's
content. The default is to print:

 ### <name> ###

Code will get these arguments:

 ($writer, $name, $content, $extra)

=back

=head2 $writer->add_part($name => $content)

=head2 $writer->as_string => str

Get the final data section as string. You can also use the object as a string,
e.g.:

 print $writer;

because this method is used for stringification overloading.

=head2 $writer->header([ $str_or_code ]) => value

Get/set header attribute.

=head2 $writer->empty

Empty content.

=head2 Why am I getting the error message "readline() on unopened filehandle DATA at ..."?

You are probably writing in the BEGIN phase, at which point the DATA filehandle
is not available. Read L<perldata> for more details.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Section-Seekable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Section-Seekable>.

=head1 SEE ALSO

L<Data::Section::Seekable> for the description of the data format.

L<Data::Section::Seekable::Reader> for the reader class.

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

This software is copyright (c) 2023, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Section-Seekable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
