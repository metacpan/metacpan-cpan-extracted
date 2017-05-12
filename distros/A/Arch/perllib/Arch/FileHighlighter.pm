# Arch Perl library, Copyright (C) 2004-2005 Mikhael Goikhman
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use 5.005;
use strict;

package Arch::FileHighlighter;

use Arch::Util qw(run_cmd load_file save_file);

sub new ($;$) {
	my $class = shift;
	my $filters = shift;
	$filters ||= [ (-x '/usr/bin/enscript'? 'enscript': ()), 'internal' ];

	my $self = {
		filters => $filters,
	};
	bless $self, $class;

	no strict 'refs';
	${"${class}::global_instance"} = $self;
	return $self;
}

sub instance ($;$) {
	my $class = shift;

	no strict 'refs';
	return ${"${class}::global_instance"} || $class->new(@_);
}

sub htmlize ($) {
	my $str = shift;
	die "No content to htmlize" unless defined $str;

	$str =~ s/&/&amp;/sg;
	$str =~ s/\"/&quot;/sg;
	$str =~ s/</&lt;/sg;
	$str =~ s/>/&gt;/sg;
	return $str;
}

sub dehtmlize ($) {
	my $str = shift;
	die "No content to dehtmlize" unless defined $str;

	$str =~ s/&amp;/&/sg;
	$str =~ s/&quot;/\"/sg;
	$str =~ s/&lt;/</sg;
	$str =~ s/&gt;/>/sg;
	return $str;
}

sub highlight ($$;$) {
	my $self = shift;
	my $file_name = shift;
	my $content = shift;

	load_file($file_name, \$content) unless defined $content;
	my $content_ref = ref($content) eq 'SCALAR'? $content: \$content;

	return undef if -B $file_name;

	foreach (@{$self->{filters}}) {
		# make sure we actually copy $_ and not work in-place
		my $filter = $_;
		my %args = ();
		if ($filter =~ /(.*)\((.*)\)/) {
			$filter = $1;
			my $args = $2;
			%args = map { /^(.+?)=(.*)$/? ($1 => $2): ($_ => 1) }
				split(/[^:\w=]+/, $args);
		}
		my $method = "_highlight_$filter";
		unless ($self->can($method)) {
			warn qq(Arch::FileHighlighter: unknown filter "$filter"\n);
			next;
		}
		my $html_ref = $self->$method($file_name, $content_ref, %args);
		return $html_ref if $html_ref;
	}
	$self->_highlight_none($file_name, $content_ref);
}

sub _highlight_enscript ($$$%) {
	my $self = shift;
	my $file_name = shift;
	my $content_ref = shift;
	my %args = @_;

	my $tmp;
	if ($content_ref) {
		require Arch::TempFiles;
		$tmp = Arch::TempFiles->new;
		$file_name =~ m!^(.*/|^)([^/]+)$! || die "Invalid file name ($file_name)\n";
		$file_name = $tmp->dir("highlight") . "/$2";
		save_file($file_name, $content_ref);
	}

	my @enscript_args = qw(enscript --output - --quiet --pretty-print);
	push @enscript_args, "--color" unless $args{"mono"};
	push @enscript_args, "--language", "html", $file_name;
	my $html = eval { run_cmd(@enscript_args) };
	return undef unless $html;

	$html =~ s!^.*<PRE>\n?!!s; $html =~ s!</PRE>.*$!!s;
	return undef unless $args{"asis"} || $html =~ /</;

	for (1 .. 3) {
		my $dot = $_ == 3? ".": "[^<]";
		$html =~ s!<B><FONT COLOR="#A020F0">($dot*?)</FONT></B>!<span class="syntax_keyword">$1</span>!sg;
		$html =~ s!<B><FONT COLOR="#DA70D6">($dot*?)</FONT></B>!<span class="syntax_builtin">$1</span>!sg;
		$html =~ s!<I><FONT COLOR="#B22222">($dot*?)</FONT></I>!<span class="syntax_comment">$1</span>!sg;
		$html =~ s!<B><FONT COLOR="#5F9EA0">($dot*?)</FONT></B>!<span class="syntax_special">$1</span>!sg;
		$html =~ s!<B><FONT COLOR="#0000FF">($dot*?)</FONT></B>!<span class="syntax_funcdef">$1</span>!sg;
		$html =~ s!<B><FONT COLOR="#228B22">($dot*?)</FONT></B>!<span class="syntax_vartype">$1</span>!sg;
		$html =~ s!<B><FONT COLOR="#BC8F8F">($dot*?)</FONT></B>!<span class="syntax_string">$1</span>!sg;
		$html =~ s!<FONT COLOR="#228B22"><B>($dot*?)</FONT></B>!<span class="syntax_vartype">$1</span>!sg;
		$html =~ s!<FONT COLOR="#BC8F8F"><B>($dot*?)</FONT></B>!<span class="syntax_string">$1</span>!sg;
		$html =~ s!<FONT COLOR="#B8860B">($dot*?)</FONT>!<span class="syntax_constant">$1</span>!sg;
	}
	$html =~ s!<B>(.*?)</B>!<span class="syntax_keyword">$1</span>!sg;
	$html =~ s!<I>(.*?)</I>!<span class="syntax_comment">$1</span>!sg;
	$html =~ s!</FONT></B>!!sg;  # enscript bug with perl highlightling
	$html =~ s!(\r?\n)((?:</span>)+)!$2$1!g;
	return \$html;
}

sub _match_file_extension ($$) {
	my $file_name = shift;
	my $args = shift;

	while (my ($ext, $value) = each %$args) {
		return 1 if $value && $file_name =~ /\.$ext(\.in)?$/i;
	}
	return 0;
}

sub _highlight_internal ($$$%) {
	my $self = shift;
	my $file_name = shift;
	my $content_ref = shift;
	my %args = @_;

	my @xml_extensions = qw(html htm shtml sgml xml wml rss glade);
	my $xml_extension_regexp = join('|', @xml_extensions);

	if (%args) {
		if (exists $args{':xml'}) {
			my $value = delete $args{':xml'};
			$args{$_} = $value foreach @xml_extensions;
		}
		return undef unless _match_file_extension($file_name, \%args);
	}

	print STDERR "internal highlighting for $file_name\n"
		if $ENV{DEBUG} && ("$ENV{DEBUG}" & "\1") ne "\0";
	my $html = htmlize($$content_ref);
	$file_name =~ s/\.in$//;
	$file_name = lc($file_name);

	if ($file_name =~ /\.(ac|am|conf|m4|pl|pm|po|py|rb|sh|sql)$/ || $html =~ /^#!/) {
		$html =~ s!^([ \t]*)(#.*)!$1<span class="syntax_comment">$2</span>!mg;
	}
	if ($file_name =~ /\.(lisp|lsp|scm|scheme)$/) {
		$html =~ s!^([ \t]*)(;.*)!$1<span class="syntax_comment">$2</span>!mg;
	}
	if ($file_name =~ /\.(c|cc|cpp|cxx|c\+\+|h|hpp|idl|php|xpm|l|y)$/) {
		$html =~ s!(^|[^\\:])(//.*)!$1<span class="syntax_comment">$2<\/span>!g;
		$html =~ s!(^|[^\\])(/\*.*?\*/)!$1<span class="syntax_comment">$2<\/span>!sg;
	}
	if ($file_name =~ /(^configure(\.ac)?|\.m4)$/) {
		$html =~ s!(\bdnl\b.*)!<span class="syntax_comment">$1<\/span>!g;
		$html =~ s!\b(m4_\w+)\b!<span class="syntax_builtin">$1<\/span>!g;
		$html =~ s!\b(if|then|else|fi)\b!<span class="syntax_keyword">$1<\/span>!g;
	}
	if ($file_name =~ /\.($xml_extension_regexp)$/) {
		$html =~ s!(&lt;\!--.*?--&gt;)!<span class="syntax_comment">$1<\/span>!sg;
		$html =~ s!(&lt;/?\w+.*?&gt;)!<span class="syntax_keyword">$1<\/span>!sg;
		while ($html =~ s!(>(?:&lt;[\w-]+)?\s+)([\w-]+)(=)("[^"]*"|'[^']'|[^\s]*)!$1<span class="syntax_special">$2<\/span>$3<span class="syntax_string">$4<\/span>!sg) {}
	}
	return \$html;
}

sub _highlight_none ($$$%) {
	my $self = shift;
	my $file_name = shift;
	my $content_ref = shift;
	my %args = @_;

	if (%args) {
		return undef unless _match_file_extension($file_name, \%args);
	}

	my $html = htmlize($$content_ref);
	return \$html;
}

1;

__END__

=head1 NAME

Arch::FileHighlighter - syntax-highlight file's content using markup

=head1 SYNOPSIS

    use Arch::FileHighlighter;
    my $fh = Arch::FileHighlighter->new(
        [ 'internal(pm+c)', 'none(txt), 'enscript', 'internal', ]
    );

    my $html_ref = $fh->highlight($0);
    print $$html_ref;

    print ${$fh->highlight('file.c', '/* some code */')};

=head1 DESCRIPTION

This class processes file contents and produces syntax highlighting markup.
This may be used together with css that defines exact text colors and faces.

The default is to use the builtin "internal" processing, that is pretty
poor; only very basic file types and syntax constructions are supported.
It is suggested to configure and use the external "enscript" utility.
GNU enscript understands quite a rich number of file types and produces
a useful syntax highlighting. "enscript" filter is used by default if
/usr/bin/enscript is found.

It is possible to configure different filters ("none", "internal",
"enscript") depending on file name extension. In any case the resulting
markup is always unified, i.e. all special characters are HTML-encoded
using SGML entities, and the markup that looks like
E<lt>spanclass="syntax_foo"E<gt>barE<lt>/spanE<gt> is used.

=head1 METHODS

The following methods are available:

B<new>,
B<instance>,
B<highlight>.

=over 4

=item B<new> [I<filters>]

Create a new instance of L<Arch::FileHighlighter>.

I<filters> is arrayref of strings of the form I<filter>(ext1+ext2+...)",
where I<filter> is one of "enscript", "internal" or "none". Special
extension ":xml" is a shortcut for "html+htm+sgml+xml+wml+rss+glade".
The filters optionally constrained by file extensions are probed
sequentially and the first passed one is used.

Note that if enscript is configured in the sequence, but is not installed,
then its probing may print a warning to stderr. The "enscript" filter is
handled a bit specially, it may take parameters "mono" (less colors) and
"asis" instead of the file extensions. If enscript returns html without
any tags, then the filter is handled as failed, unless "asis" is given.

By default, I<filters> is [ 'internal' ], or [ 'enscript', 'internal' ]
depending on presense of '/usr/bin/enscript'.

=item B<instance> [I<filters>]

Alternative constructor. Return the last created instance of
L<Arch::FileHighlighter> or create a new one.

The purpose of this alternative constructor is to allow the singleton
behaviour as well as certain Aspect Oriented Programming practices.  

=item B<highlight> I<filename> [I<content>]

Process I<filename> using configured filters (as described in the
constructor) and produce the file content with embeded E<lt>span
class="I<class>"E<gt>...E<lt>/spanE<gt> markup. I<class> is one of:

    syntax_keyword
    syntax_builtin
    syntax_comment
    syntax_special
    syntax_funcdef
    syntax_vartype
    syntax_string
    syntax_constant

If I<content> is provided (either string or reference to string), it is
used, otherwise the content of I<filename> is loaded.

=back

=head1 BUGS

Awaiting for your reports.

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

=head1 SEE ALSO

For more information, see L<enscript>, L<Arch::Util>,
L<Syntax::Highlight::Perl>.

=cut
