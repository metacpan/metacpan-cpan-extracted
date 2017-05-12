package Data::Format::Pretty::HTML;

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

use Data::Format::Pretty::Console 0.24;
use HTML::Entities;
use Scalar::Util qw(looks_like_number);
use URI::Find::Schemeless;
use YAML::Any;

require Exporter;
our @ISA = qw(Exporter Data::Format::Pretty::Console);
our @EXPORT_OK = qw(format_pretty);

our $VERSION = '0.10'; # VERSION

sub content_type { "text/html" }

sub format_pretty {
    my ($data, $opts) = @_;
    $opts //= {};
    __PACKAGE__->new($opts)->_format($data);
}

# OO interface is hidden
sub new {
    my ($class, $opts) = @_;
    my $obj = $class->SUPER::new($opts);
    #my $obj = Data::Format::Pretty::Console->new($opts);
    $obj->{opts}{linkify_urls_in_text} //= 1;
    $obj->{opts}{interactive} = 1;
    $obj->{opts}{list_max_columns} = 1;
    #bless $class, $obj;
    $obj;
}

sub _htmlify {
    my ($self, $text) = @_;

    $text = encode_entities($text);
    if ($self->{opts}{linkify_urls_in_text}) {
        URI::Find::Schemeless->new(
            sub {
                #my $uri = encode_entities $_[0];
                #my $uri = $_[0];
                my $uri = decode_entities $_[0];
                return qq|<a href="$uri">$uri</a>|;
            })->find(\$text);
    }
    if ($text =~ /\R/) {
        return "<pre>$text</pre>";
    } else {
        return $text;
    }
}

sub _render_table {
    my ($self, $t) = @_;
    my @t = ("<table>\n");

    my $sh = $t->{at_opts}{show_header};
    unless (defined($sh) && !$sh) {
        push @t, "  <thead>\n";
        push @t, "    <tr>";
        for my $c (@{$t->{cols}}) {
            push @t, (
                "<th", (looks_like_number($c) ? ' class="number"':''), ">",
                $self->_htmlify($c),
                "</th>",
            );
        }
        push @t, "</tr>\n";
        push @t, "  </thead>\n";
    }

    push @t, "  <tbody>\n";
    for my $r (@{$t->{rows}}) {
        push @t, "    <tr>";
        my $cidx = 0;
        for my $c (@$r) {
            if ($t->{html_cols} && $t->{html_cols}[$cidx]) {
                push @t, "<td>", $c, "</td>";
            } else {
                push @t, (
                    "<td", (looks_like_number($c) ? ' class="number"':''), ">",
                    $self->_htmlify($c),
                    "</td>",
                );
            }
            $cidx++;
        }
        push @t, "</tr>\n";
    }
    push @t, "  </tbody>\n";
    push @t, "</table>\n";
    join "", @t;
}

# format unknown structure, the default is to dump YAML structure
sub _format_unknown {
    my ($self, $data) = @_;
    $self->_htmlify(Dump $data);
}

sub _format_scalar {
    my ($self, $data) = @_;

    my $sdata = defined($data) ? "$data" : "";
    $self->_htmlify($sdata);
}

sub _format_hot {
    my ($self, $data) = @_;
    my @t;
    # format as 2-column table of key/value
    my $t = {cols=>[qw/key value/], html_cols=>[0, 1], rows=>[]};
    for my $k (sort keys %$data) {
        push @{ $t->{rows} }, [$k, $self->_format($data->{$k})];
    }
    $self->_render_table($t);
}

1;
# ABSTRACT: Pretty-print data structure for HTML output

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Format::Pretty::HTML - Pretty-print data structure for HTML output

=head1 VERSION

This document describes version 0.10 of Data::Format::Pretty::HTML (from Perl distribution Data-Format-Pretty-HTML), released on 2015-08-17.

=head1 SYNOPSIS

In your program:

 use Data::Format::Pretty::HTML qw(format_pretty);
 ...
 print format_pretty($result);

Some example output:

Scalar, format_pretty("foo & bar"):

 foo &amp; bar

Scalar multiline, format_pretty("foo\nbar\nbaz"):

 <pre>foo
 bar
 baz</pre>

List, format_pretty([qw/foo bar baz qux/]):

 <table>
   <tr><td>foo</td></tr>
   <tr><td>bar</td></tr>
   <tr><td>baz</td></tr>
   <tr><td>qux</td></tr>
 </table>

Hash, format_pretty({foo=>"data",bar=>"format",baz=>"pretty",qux=>"html"}):

 <table>
   <tr><th>key</th><th>value</th></tr>
   <tr><td>bar</td><td>format</td></tr>
   <tr><td>baz</td><td>pretty</td></tr>
   <tr><td>foo</td><td>data</td></tr>
   <tr><td>qux</td><td>html</td></tr>
 </table>

2-dimensional array, format_pretty([ [1, 2, ""], [28, "bar", 3], ["foo", 3,
undef] ]):

 <table>
   <tr><th>column0</th><th>column1</th><th>column2</th></tr>
   <tr><td class="number">1</td><td class="number">2</td><td></td></tr>
   <tr><td class="number">28</td><td>bar</td><td class="number">3</td></tr>
   <tr><td>foo</td><td class="number">3</td><td></td></tr>
 </table>

An array of hashrefs, such as commonly found if you use DBI's fetchrow_hashref()
and friends, format_pretty([ {a=>1, b=>2}, {b=>2, c=>3}, {c=>4} ]):

 <table>
   <tr><th>a</th><th>b</th><th>c</th></tr>
   <tr><td class="number">1</td><td class="number">2</td><td></td></tr>
   <tr><td></td><td class="number">2</td><td class="number">3</td></tr>
   <tr><td></td><td></td><td class="number">4</td></tr>
 </table>

Some more complex data, format_pretty({summary => "Blah...", users =>
[{name=>"budi", domains=>["f.com", "b.com"], quota=>"1000"}, {name=>"arif",
domains=>["baz.com"], quota=>"2000"}], verified => 0}):

 <table>

   <tr>
     <td>summary</td>
     <td>Blah...</td>
   </tr>

   <tr>
     <td>users</td>
     <td>
       <table>
         <tr><th>domains</th><th>name</th><th>quota</th></tr>
         <tr><td>f.com, b.com</td><td>budi</td><td class="number">1000</td></tr>
         <tr><td>baz.com</td><td>arif</td><td class="number">2000</td></tr>
     </td>
   </tr>

   <tr>
     <td>verified</td>
     <td class="number">0</td>
   </tr>

 </table>

Structures which can't be handled yet will simply be output as YAML,
format_pretty({a => {b=>1}}):

 <pre>a:
   b: 1
 </pre>

=head1 DESCRIPTION

This module has the same spirit as L<Data::Format::Pretty::Console> (and
currently implemented as its subclass). The idea is to throw it some data
structure and let it figure out how to best display the data in a pretty HTML
format.

Differences with Data::Format::Pretty::Console:

=over 4

=item * hot (hash of table) structure is rendered as table of inner tables

=back

=for Pod::Coverage new

=head1 FUNCTIONS

=head2 format_pretty($data, \%opts)

Return formatted data structure as HTML. Options:

=over 4

=item * table_column_orders => [[colname, colname], ...]

See Data::Format::Pretty::Console for more details.

=item * linkify_urls_in_text => BOOL

Whether to convert 'http://foo' in text into '<a
href="http://foo">http://foo</a>'. Default is true.

=back

=head1 SEE ALSO

L<Data::Format::Pretty>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Format-Pretty-HTML>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Data-Format-Pretty-HTML>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Format-Pretty-HTML>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
