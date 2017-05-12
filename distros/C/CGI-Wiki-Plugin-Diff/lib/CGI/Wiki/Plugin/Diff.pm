package CGI::Wiki::Plugin::Diff;

use strict;
use warnings;

our $VERSION = '0.09';

use base 'CGI::Wiki::Plugin';
use Algorithm::Diff;
use VCS::Lite;
use Params::Validate::Dummy ();
use Module::Optional qw(Params::Validate 
        validate validate_pos SCALAR SCALARREF ARRAYREF HASHREF UNDEF);

sub new {
    my $class = shift;
    my %par = validate( @_, {
        metadata_separator => { type => SCALAR, default => "<br />\n"} ,
    	line_number_format => { type => SCALAR, default => "== Line \$_ ==\n" }, 
        word_matcher => { type => SCALARREF, default => qr(
            &.+?;                   #HTML special characters e.g. &lt;
            |<br\s*/>               #Line breaks
            |\w+\s*       	    #Word with trailing spaces 
            |.                      #Any other single character
        )xsi },
    	} );
    bless \%par, $class;
}

sub differences {
    my $self = shift;
    my %args = validate( @_, {
        node          => { type => SCALAR},
        left_version  => { type => SCALAR},
        right_version => { type => SCALAR},
        meta_include  => { type => ARRAYREF, optional => 1 },
        meta_exclude  => { type => ARRAYREF, optional => 1 } });

    my ($node, $v1, $v2)  = @args{ qw( node left_version right_version) };
    my $store = $self->datastore;
    my $fmt = $self->formatter;
    
    my %ver1 = $store->retrieve_node( name => $node, version => $v1);
    my %ver2 = $store->retrieve_node( name => $node, version => $v2);

    my $verstring1 = "Version ".$ver1{version};
    my $verstring2 = "Version ".$ver2{version};
    
    my $el1 = VCS::Lite->new($verstring1,undef,
    	$self->content_escape($ver1{content}).
    	$self->{metadata_separator}.
	$self->serialise_metadata($ver1{metadata},
		@args{qw(meta_include meta_exclude)}));
    my $el2 = VCS::Lite->new($verstring2,undef,
    	$self->content_escape($ver2{content}).
    	$self->{metadata_separator}.
	$self->serialise_metadata($ver2{metadata},
		@args{qw(meta_include meta_exclude)}));
    my %pag = %ver1;
    $pag{left_version} = $verstring1;
    $pag{right_version} = $verstring2;
    $pag{content} = $fmt->format($ver1{content});
    my $dlt = $el1->delta($el2)
	or return %pag;

    my @out;
    
    for ($dlt->hunks) {
    	my ($lin1,$lin2,$out1,$out2);
	for (@$_) {
	    my ($ind,$line,$text) = @$_;
	    if ($ind ne '+') {
		$lin1 ||= $line;
		$out1 .= $text;
	    }
	    if ($ind ne '-') {
		$lin2 ||= $line;
		$out2 .= $text;
	    }
	}
    	push @out,{ left => $self->line_number($lin1), 
		right => $self->line_number($lin2) };
	my ($text1,$text2) = $self->intradiff($out1,$out2);
	push @out,{left => $text1,
		right => $text2};
    }

    $pag{diff} = \@out;
    %pag;
}

sub line_number {
    my $self = shift;

    local ($_) = validate_pos(@_, {type => SCALAR | UNDEF, optional => 1} );
    return '' unless defined $_;

    my $fmt = '"'. $self->{line_number_format} . '"';
    eval $fmt;
}

sub serialise_metadata {
    my $self = shift;
    my ($all_meta,$include,$exclude) = validate_pos ( @_, 
        { type => HASHREF },
        { type => ARRAYREF | UNDEF, optional => 1 },
        { type => ARRAYREF | UNDEF, optional => 1 },
            );
    $include ||= [keys %$all_meta];
    $exclude ||= [qw(comment username 
         __categories__checksum __locales__checksum)] ;
    
    my %metadata = map {$_,$all_meta->{$_}} @$include;
    delete $metadata{$_} for @$exclude;

    join $self->{metadata_separator}, 
        map {"$_='".join (',',sort @{$metadata{$_}})."'"} 
            sort keys %metadata;
}

sub content_escape {
    my $self = shift;
    my ($str) = validate_pos( @_, { type => SCALAR } );

    $str =~ s/&/&amp;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s!\s*?\n!<br />\n!gs;

    $str;
}

sub intradiff {
    my $self = shift;
    my ($str1,$str2) = validate_pos( @_, {type => SCALAR|UNDEF }, 
                                         {type => SCALAR|UNDEF });

    return (qq{<span class="diff1">$str1</span>},"") unless $str2;
    return ("",qq{<span class="diff2">$str2</span>}) unless $str1;
    my $re_wordmatcher = $self->{word_matcher};                                             
    my @diffs = Algorithm::Diff::sdiff([$str1 =~ /$re_wordmatcher/sg]
    	,[$str2 =~ /$re_wordmatcher/sg], sub {$self->get_token(@_)});
    my $out1 = '';
    my $out2 = '';
    my ($mode1,$mode2);

    for (@diffs) {
    	my ($ind,$c1,$c2) = @$_;

	my $newmode1 = $ind =~ /[c\-]/;
	my $newmode2 = $ind =~ /[c+]/;
	$out1 .= '<span class="diff1">' if $newmode1 && !$mode1;
	$out2 .= '<span class="diff2">' if $newmode2 && !$mode2;
	$out1 .= '</span>' if !$newmode1 && $mode1;
	$out2 .= '</span>' if !$newmode2 && $mode2;
	($mode1,$mode2) = ($newmode1,$newmode2);
	$out1 .= $c1;
	$out2 .= $c2;
    }
    $out1 .= '</span>' if $mode1;
    $out2 .= '</span>' if $mode2;

    ($out1,$out2);
}

sub get_token {
    my ($self,$str) = @_;

    $str =~ /^(\S*)\s*$/;	# Match all but trailing whitespace

    $1 || $str;
}

1;
__END__

=head1 NAME

CGI::Wiki::Plugin::Diff - format differences between two CGI::Wiki pages

=head1 SYNOPSIS

  use CGI::Wiki::Plugin::Diff;
  my $plugin = CGI::Wiki::Plugin::Diff->new;
  $wiki->register_plugin( plugin => $plugin );   # called before any node reads
  my %diff = $plugin->differences( node => 'Imperial College',
  				left_version => 3,
				right_version => 5);

=head1 DESCRIPTION

A plug-in for CGI::Wiki sites, which provides a nice extract of differences
between two versions of a node. 

=head1 BASIC USAGE

B<differences>

  my %diff_vars = $plugin->differences(
      node          => "Home Page",
      left_version  => 3,
      right_version => 5
  );

Takes a series of key/value pairs:

=over 4

=item *
B<left_version>

The node version whose content we're considering canonical.

=item *
B<right_version>

The node version that we're showing the differences from.

=item *
B<meta_include>

Filter the list of metadata fields to only include a certain
list in the diff output. The default is to include all metadata fields.

=item *
B<meta_exclude>

Filter the list of metadata fields to exclude certain
fields from the diff output. The default is the following list, to match
previous version (OpenGuides) behaviour:
   C<qw(
   username
   comment
   __categories__checksum
   __locales__checksum )>

Agreed this list is hopelessly inadequate, especially for L<OpenGuides>.
Hopefully, future wiki designers will use the meta_include parameter to
specify exactly what metadata they want to appear on the diff.

=back

The differences method returns a list of key/value pairs, which can be
assigned to a hash:

=over 4

=item B<left_version>

The node version whose content we're considering canonical.

=item B<right_version>

The node version that we're showing the differences from.

=item B<content> 

The (formatted) contents of the I<Left> version of the node.

=item B<diff> 

An array of hashrefs of C<hunks> of differences between the
versions. It is assumed that the display will be rendered in HTML, and SPAN
tags are inserted with a class of diff1 or diff2, to highlight which
individual words have actually changed. Display the contents of diff using
a E<lt>tableE<gt>, with each member of the array corresponding to a row 
E<lt>TRE<gt>, and keys {left} and {right} being two columns E<lt>TDE<gt>.

Usually you will want to feed this through a templating system, such as
Template Toolkit, which makes iterating the AoH very easy.

=back

=head1 ADVANCED

CGI::Wiki::Plugin::Diff allows for a more flexible approach than HTML only
rendering of pages. In particular, there are optional parameters to the
constructor which control fine detail of the resultant output.

If this is not sufficient, the module is also subclassable, and the 
programmer can supply alternative methods.

=head2 METHODS

Most of these are called internally by the plugin, but provide hooks
for alternative code if the module is subclassed.

=over 4

=item B<new>

  my $plugin = CGI::Wiki::Plugin::Diff->new( option => value, option => value...);

Here, I<option> can be one of the following:

=over 4

=item B<metadata_separator>

A string which is inserted between each metadata
field, and also between the contents and the metadata. This defaults to 
"E<lt>br /E<gt>\n" so as to render each metadata field on a new line.

=item B<line_number_format>

Used to lay out the head line number for a 
difference hunk. The string is eval'ed with $_ containing the line number.
Default is "== Line \$_ ==" .

=item B<word_matcher> 

is a regular expression, used to tokenize the input
string. This is the way of grouping together atomic sequences, so as to
give a readable result. The default is the following:

            &.+?;                   #HTML special characters e.g. &lt;
            |<br\s*/>               #Line breaks
            |\w+\s*       	    #Word with trailing spaces 
            |.                      #Any other single character

=back

=item B<differences>

see above.

=item B<line_number>

This method is called to format a line number into a suitable string.
The supplied routine performs the necessary substitution of 
$self->{line_number_format} using eval.

=item B<serialise_metadata>

The purpose of this method is to turn a metadata hash into a string
suitable for diffing.

=item B<content_escape>

This method is used to apply the necessary quoting or escaping of 
characters that could appear in the content body, that could interfere
with the rendering of the diff text.

=item B<intradiff>

This method turns an array of hunks as returned by VCS::Lite::Delta->hunks
into a side by side diff listing, with highlights indicating different 
words and punctuation.

Currently, this is hardcoded to present the differences with HTML tags.

This module is a prime candidate for migration into VCS::Lite, where this
functionality really belongs.

=item B<get_token>

This allows the "false positive" bug discovered by Earle Martin to be solved
(rt.cpan.org #6284).
Effectively, the input strings (diff1 and diff2) are tokenised using the
word_matcher regexp (see above), and turned into arrays of tokens.

The default regexp absorbs trailing whitespace, to give a more readable result.
However, if a word is followed by differing whitespace or no whitespace at
all, this was throwing up a diff.

The get_token method supplied removes trailing whitespace from the key
values before they are compared.

=back

=head1 TODO

Move intradiff functionality into VCS::Lite.

=head1 BUGS AND ENHANCEMENTS

Please use rt.cpan.org to report any bugs in this module. If you have any
ideas for how this module could be enhanced, please email the author, or
post to the CGI::Wiki list (cgi (hyphen) wiki (hyphen) dev (at) earth (dot) li).

=head1 AUTHOR

I. P. Williams (ivorw_openguides [at] xemaps {dot} com)

=head1 COPYRIGHT

     Copyright (C) 2003-2004 I. P. Williams (ivorw_openguides [at] xemaps {dot} com).
     All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<VCS::Lite>, L<CGI::Wiki>, L<CGI::Wiki::Plugin>, L<OpenGuides>

=cut
