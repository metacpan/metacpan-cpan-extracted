package Acme::PERLANCAR::Dummy::POD::LineBreak;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-09'; # DATE
our $DIST = 'Acme-PERLANCAR-Dummy-POD'; # DIST
our $VERSION = '0.005'; # VERSION

1;
# ABSTRACT: Testing linebreaks

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::PERLANCAR::Dummy::POD::LineBreak - Testing linebreaks

=head1 VERSION

This document describes version 0.005 of Acme::PERLANCAR::Dummy::POD::LineBreak (from Perl distribution Acme-PERLANCAR-Dummy-POD), released on 2021-07-09.

=head1 DESCRIPTION

Other things that don't work: EZ<><br> is not recognized. EZ<><13> is ignored.

=head1 WITHOUT LINEBREAK

B<foobar> [B<--opt1>|B<-O>] [B<--regex>|B<--wildcard>] [B<-a>] [B<-u>]
[B<--moreoption1>=I<value>] [B<--moreoption2>=I<value>]
[B<--moreoption3>=I<value>] [B<--moreoption4>=I<value>]
[B<--moreoption5>=I<value>] [B<--moreoption6>=I<value>]
[B<--moreoption7>=I<value>] [B<--moreoption8>=I<value>]
[B<--moreoption9>=I<value>] [B<--moreoption10>=I<value>]
[B<--moreoption11>=I<value>] [B<--moreoption12>=I<value>]
E<lt>I<filename>E<gt> ...

=head1 WITH EZ<><10>

B<foobar> [B<--opt1>|B<-O>] [B<--regex>|B<--wildcard>] [B<-a>] [B<-u>] E<10>
[B<--moreoption1>=I<value>] [B<--moreoption2>=I<value>] E<10>
[B<--moreoption3>=I<value>] [B<--moreoption4>=I<value>] E<10>
[B<--moreoption5>=I<value>] [B<--moreoption6>=I<value>] E<10>
[B<--moreoption7>=I<value>] [B<--moreoption8>=I<value>] E<10>
[B<--moreoption9>=I<value>] [B<--moreoption10>=I<value>] E<10>
[B<--moreoption11>=I<value>] [B<--moreoption12>=I<value>] E<10>
E<lt>I<filename>E<gt> ...

The result: 1/10. B<pod2text> ignores the linebreak. B<pod2man> creates a blank
line (new paragraph) instead of line break. B<pod2html> ignores the linebreak.

=head1 WITH EZ<><10> + EZ<><8>

B<foobar> [B<--opt1>|B<-O>] [B<--regex>|B<--wildcard>] [B<-a>] [B<-u>] E<10> E<8>[B<--moreoption1>=I<value>] [B<--moreoption2>=I<value>] E<10> E<8>[B<--moreoption3>=I<value>] [B<--moreoption4>=I<value>] E<10> E<8>[B<--moreoption5>=I<value>] [B<--moreoption6>=I<value>] E<10> E<8>[B<--moreoption7>=I<value>] [B<--moreoption8>=I<value>] E<10> E<8>[B<--moreoption9>=I<value>] [B<--moreoption10>=I<value>] E<10> E<8>[B<--moreoption11>=I<value>] [B<--moreoption12>=I<value>] E<10> E<8>E<lt>I<filename>E<gt> ...

The result: 7/10. B<pod2text> renders it as intended (but shifts one character
to the left). B<pod2man> renders it as intended. B<pod2html> ignores the
linebreak.

Reference: L<https://www.nntp.perl.org/group/perl.beginners/2006/08/msg85687.html>

=head1 WITH =item

=over

=item B<foobar> [B<--opt1>|B<-O>] [B<--regex>|B<--wildcard>] [B<-a>] [B<-u>]

=item [B<--moreoption1>=I<value>] [B<--moreoption2>=I<value>]

=item [B<--moreoption3>=I<value>] [B<--moreoption4>=I<value>]

=item [B<--moreoption5>=I<value>] [B<--moreoption6>=I<value>]

=item [B<--moreoption7>=I<value>] [B<--moreoption8>=I<value>]

=item [B<--moreoption9>=I<value>] [B<--moreoption10>=I<value>]

=item [B<--moreoption11>=I<value>] [B<--moreoption12>=I<value>]

=item E<lt>I<filename>E<gt> ...

=back

The result: 7/10. B<pod2text> renders it as intended. B<pod2man> renders it as
intended. B<pod2html> shows a paragraph break and makes all lines bold.

=head1 WITH =for (providing rendered code for each output)

=for text      foobar-text [--opt1|-O] [--regex|--wildcard] [-a] [-u]
     [--moreoption1=value] [--moreoption2=value]
     [--moreoption3=value] [--moreoption4=value]
     [--moreoption5=value] [--moreoption6=value]
     [--moreoption7=value] [--moreoption8=value]
     [--moreoption9=value] [--moreoption10=value]
     [--moreoption11=value] [--moreoption12=value]
     <filename> ...

=for roff .IP "\fBfoobar-roff\fR [\fB\-\-opt1\fR|\fB\-O\fR] [\fB\-\-regex\fR|\fB\-\-wildcard\fR] [\fB\-a\fR] [\fB\-u\fR]" 4
.IX Item "foobar-roff [--opt1|-O] [--regex|--wildcard] [-a] [-u]"
.PD 0
.IP "[\fB\-\-moreoption1\fR=\fIvalue\fR] [\fB\-\-moreoption2\fR=\fIvalue\fR]" 4
.IX Item "[--moreoption1=value] [--moreoption2=value]"
.IP "[\fB\-\-moreoption3\fR=\fIvalue\fR] [\fB\-\-moreoption4\fR=\fIvalue\fR]" 4
.IX Item "[--moreoption3=value] [--moreoption4=value]"
.IP "[\fB\-\-moreoption5\fR=\fIvalue\fR] [\fB\-\-moreoption6\fR=\fIvalue\fR]" 4
.IX Item "[--moreoption5=value] [--moreoption6=value]"
.IP "[\fB\-\-moreoption7\fR=\fIvalue\fR] [\fB\-\-moreoption8\fR=\fIvalue\fR]" 4
.IX Item "[--moreoption7=value] [--moreoption8=value]"
.IP "[\fB\-\-moreoption9\fR=\fIvalue\fR] [\fB\-\-moreoption10\fR=\fIvalue\fR]" 4
.IX Item "[--moreoption9=value] [--moreoption10=value]"
.IP "[\fB\-\-moreoption11\fR=\fIvalue\fR] [\fB\-\-moreoption12\fR=\fIvalue\fR]" 4
.IX Item "[--moreoption11=value] [--moreoption12=value]"
.IP "<\fIfilename\fR> ..." 4
.IX Item "<filename> ..."
.PD
.PP

=for html <p><b>foobar-html</b> [<b>--opt1</b>|<b>-O</b>] [<b>--regex</b>|<b>--wildcard</b>] [<b>-a</b>] [<b>-u</b>]<br>
[<b>--moreoption1</b>=<i>value</i>] [<b>--moreoption2</b>=<i>value</i>]<br>
[<b>--moreoption3</b>=<i>value</i>] [<b>--moreoption4</b>=<i>value</i>]<br>
[<b>--moreoption5</b>=<i>value</i>] [<b>--moreoption6</b>=<i>value</i>]<br>
[<b>--moreoption7</b>=<i>value</i>] [<b>--moreoption8</b>=<i>value</i>]<br>
[<b>--moreoption9</b>=<i>value</i>] [<b>--moreoption10</b>=<i>value</i>]<br>
[<b>--moreoption11</b>=<i>value</i>] [<b>--moreoption12</b>=<i>value</i>]<br>
&lt;<i>filename</i>&gt; ...</p>

The result: 10/10, renders as intended obviously. However, you need to provide
code for each output.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-PERLANCAR-Dummy-POD>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-PERLANCAR-Dummy-POD>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-PERLANCAR-Dummy-POD>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://www.perlmonks.org/?node_id=606484>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
