package Data::Format::Pretty::YAML;

our $DATE = '2014-12-10'; # DATE
our $VERSION = '0.08'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(format_pretty);

sub content_type { "text/yaml" }

sub format_pretty {
    my ($data, $opts) = @_;
    $opts //= {};

    my $interactive = (-t STDOUT);
    my $pretty = $opts->{pretty} // 1;
    my $color  = $opts->{color} // $ENV{COLOR} // $interactive //
        $opts->{pretty};
    my $linum  = $opts->{linum} // $ENV{LINUM} // 0;

    if ($color) {
        require YAML::Tiny::Color;
        local $YAML::Tiny::Color::LineNumber = $linum;
        YAML::Tiny::Color::Dump($data);
    } else {
        require YAML::Syck;
        local $YAML::Syck::ImplicitTyping = 1;
        local $YAML::Syck::SortKeys       = 1;
        local $YAML::Syck::Headless       = 1;
        if ($linum) {
            require String::LineNumber;
            String::LineNumber::linenum(YAML::Syck::Dump($data));
        } else {
            YAML::Syck::Dump($data);
        }
    }
}

1;
# ABSTRACT: Pretty-print data structure as YAML

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Format::Pretty::YAML - Pretty-print data structure as YAML

=head1 VERSION

This document describes version 0.08 of Data::Format::Pretty::YAML (from Perl distribution Data-Format-Pretty-YAML), released on 2014-12-10.

=head1 SYNOPSIS

 use Data::Format::Pretty::YAML qw(format_pretty);
 print format_pretty($data);

Some example output:

=over 4

=item * format_pretty({a=>1, b=>2})

  a: 1
  b: 2

=back

=head1 DESCRIPTION

This module uses L<YAML::Syck> to encode data as YAML.

=head1 FUNCTIONS

=head2 format_pretty($data, \%opts)

Return formatted data structure as YAML. Currently there are no known options.
YAML::Syck's settings are optimized for prettiness, currently as follows:

 $YAML::Syck::ImplicitTyping = 1;
 $YAML::Syck::SortKeys       = 1;
 $YAML::Syck::Headless       = 1;

Options:

=over

=item * color => BOOL (default: from env or 1)

Whether to enable coloring. The default is the enable only when running
interactively.

=item * pretty => BOOL (default: 1)

Whether to focus on prettyness. If set to 0, will focus on producing valid YAML
instead of prettiness.

=item * linum => BOOL (default: from env or 0)

Whether to enable line numbering.

=back

=head2 content_type() => STR

Return C<text/yaml>.

=head1 ENVIRONMENT

=head2 COLOR => BOOL

Set C<color> option (if unset).

=head2 LINUM => BOOL

Set C<linum> option (if unset).

=head1 FAQ

=head1 SEE ALSO

L<Data::Format::Pretty>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Format-Pretty-YAML>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Format-Pretty-YAML>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Format-Pretty-YAML>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
