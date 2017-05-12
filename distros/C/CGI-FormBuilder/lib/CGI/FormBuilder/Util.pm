
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

package CGI::FormBuilder::Util;

=head1 NAME

CGI::FormBuilder::Util - Utility functions for FormBuilder

=head1 SYNOPSIS

    use CGI::FormBuilder::Util;

    belch "Badness";
    puke "Egads";
    debug 2, "Debug message for level 2";

=head1 DESCRIPTION

This module exports some common utility functions for B<FormBuilder>.
These functions are intended for internal use, however I must admit
that, from time to time, I just import this module and use some of
the routines directly (like C<htmltag()> to generate HTML).

=head1 USEFUL FUNCTIONS

These can be used directly and are somewhat useful. Don't tell anyone
I said that, though.

=cut

use strict;
use warnings;
no  warnings 'uninitialized';
use Carp;

# Don't "use" or it collides with our basename()
require File::Basename;

our $VERSION = '3.10';

# Place functions you want to export by default in the
# @EXPORT array. Any other functions can be requested
# explicitly if you place them in the @EXPORT_OK array.
use Exporter;
use base 'Exporter';
our @EXPORT = qw(
    debug belch puke indent escapeurl escapehtml escapejs
    autodata optalign optsort optval arglist arghash
    htmlattr htmltag toname tovar ismember basename rearrange
);
our $DEBUG = 0;
our %TAGNAMES = ();     # holds translated tag names (experimental)

# To clean up the HTML, instead of just allowing the HTML tags that
# we interpret are "valid", instead we yank out all the options and
# stuff that we use internally. This allows arbitrary tags to be
# specified in the generation of HTML tags, and also means that this
# module doesn't go out of date when the HTML spec changes next week.
our @OURATTR = qw(
    add_before_option add_after_option attr autofill autofillshow body bodyname
    buttonname caller checknum cleanopts columns cookies comment debug delete
    disable_enter dtd errorname extraname fields fieldattr fieldsubs fieldtype fieldname
    fieldopts fieldset fieldsets font force formname growable growname header
    idprefix inputname invalid javascript jsmessage jsname jsprefix jsfunc jshead
    jserror jsvalid keepextras labels labelname lalign 
    linebreaks message messages nameopts newline NON_EMPTY_SCRIPT other othername
    optgroups options override page pages pagename params render required
    reset resetname rowname selectname selectnum sessionidname sessionid
    smartness source sortopts static statename sticky stylesheet styleclass submit
    submitname submittedname table tabname template validate values
);

# trick for speedy lookup
our %OURATTR = map { $_ => 1 } @OURATTR;

# Have to populate ourselves to avoid carp'ing with bad information.
# This makes it so deeply-nested calls throw top-level errors, rather
# than referring to a sub-module that probably didn't do it.
our @CARP_NOT = qw(
    CGI::FormBuilder
    CGI::FormBuilder::Field
    CGI::FormBuilder::Field::button
    CGI::FormBuilder::Field::checkbox
    CGI::FormBuilder::Field::file
    CGI::FormBuilder::Field::hidden
    CGI::FormBuilder::Field::image
    CGI::FormBuilder::Field::password
    CGI::FormBuilder::Field::radio
    CGI::FormBuilder::Field::select
    CGI::FormBuilder::Field::static
    CGI::FormBuilder::Field::text
    CGI::FormBuilder::Field::textarea
    CGI::FormBuilder::Messages
    CGI::FormBuilder::Multi
    CGI::FormBuilder::Source
    CGI::FormBuilder::Source::File
    CGI::FormBuilder::Template
    CGI::FormBuilder::Template::Builtin
    CGI::FormBuilder::Template::Fast
    CGI::FormBuilder::Template::HTML
    CGI::FormBuilder::Template::TT2
    CGI::FormBuilder::Template::Text
    CGI::FormBuilder::Template::CGI_SSI
    CGI::FormBuilder::Util
);

=head2 debug($level, $string)

This prints out the given string only if C<$DEBUG> is greater than
the C<$level> specified. For example:

    $CGI::FormBuilder::Util::DEBUG = 1;
    debug 1, "this is printed";
    debug 2, "but not this one";

A newline is automatically included, so don't provide one of your own.

=cut

sub debug ($;@) {
    return unless $DEBUG >= $_[0];  # first arg is debug level
    my $l = shift;  # using $_[0] directly above is just a little faster...
    my($func) = (caller(1))[3];
    #$func =~ s/(.*)::/$1->/;
    warn "[$func] (debug$l) ", @_, "\n";
}

=head2 belch($string)

A modified C<warn> that prints out a better message with a newline added.

=cut

sub belch (@) {
    my $i=1;
    carp "[FormBuilder] Warning: ", @_;
}

=head2 puke($string)

A modified C<die> that prints out a useful message.

=cut

sub puke (@) {
    my $i=1;
    $DEBUG ? Carp::confess("Fatal: ", @_)
           : croak "[FormBuilder] Fatal: ", @_
}

=head2 escapeurl($string)

Returns a properly escaped string suitable for including in URL params.

=cut

sub escapeurl ($) {
    # minimalist, not 100% correct, URL escaping
    my $toencode = shift;
    $toencode =~ s!([^a-zA-Z0-9_,.-/])!sprintf("%%%02x",ord($1))!eg;
    return $toencode;
}

=head2 escapehtml($string)

Returns an HTML-escaped string suitable for embedding in HTML tags.

=cut

sub escapehtml ($) {
    my $toencode = shift;
    return '' unless defined $toencode;
    # use very basic built-in HTML escaping
    $toencode =~ s!&!&amp;!g;
    $toencode =~ s!<!&lt;!g;
    $toencode =~ s!>!&gt;!g;
    $toencode =~ s!"!&quot;!g;
    return $toencode;
}

=head2 escapejs($string)

Returns a string suitable for including in JavaScript. Minimal processing.

=cut

sub escapejs ($) {
    my $toencode = shift;
    $toencode =~ s#'#\\'#g;
    return $toencode;
}

=head2 htmltag($name, %attr)

This generates an XHTML-compliant tag for the name C<$name> based on the
C<%attr> specified. For example:

    my $table = htmltag('table', cellpadding => 1, border => 0);

No routines are provided to close tags; you must manually print a closing
C<< </table> >> tag.

=cut

sub htmltag ($;@) {
    # called as htmltag('tagname', %attr)
    # creates an HTML tag on the fly, quick and dirty
    my $name = shift || return;
    my $attr = htmlattr($name, @_);     # ref return faster

    # see if we have a special tag name (experimental)
    (my $look = $name) =~ s#^(/*)##;
    $name = "$1$TAGNAMES{$look}" if $TAGNAMES{$look};

    my $htag = join(' ', $name,
                  map { qq($_=") . escapehtml($attr->{$_}) . '"' } sort keys %$attr);

    $htag .= ' /' if $name eq 'input' || $name eq 'link';  # XHTML self-closing
    return '<' . $htag . '>';
}

=head2 htmlattr($name, %attr)

This cleans any internal B<FormBuilder> attributes from the specified tag.
It is automatically called by C<htmltag()>.

=cut

sub htmlattr ($;@) {
    # called as htmlattr('tagname', %attr)
    # returns valid HTML attr for that tag
    my $name = shift || return;
    my $attr = ref $_[0] ? $_[0] : { @_ };
    my %html;
    while (my($key,$val) = each %$attr) {
        # Anything but normal scalar data gets yanked
        next if ref $val || ! defined $val;

        # This cleans out all the internal junk kept in each data
        # element, returning everything else (for an html tag).
        # Crap, I used "text" here and body takes a text attr!!
        next if ($OURATTR{$key} || $key =~ /^_/
                                || ($key eq 'text'     && $name ne 'body')
                                || ($key eq 'multiple' && $name ne 'select')
                                || ($key eq 'type'     && $name eq 'select')
                                || ($key eq 'label'    && ($name ne 'optgroup' && $name ne 'option'))
                                || ($key eq 'title'    && $name eq 'form'));

        # see if we have a special tag name (experimental)
        $key = $TAGNAMES{$key} if $TAGNAMES{$key};
        $html{$key} = $val;
    }
    # "double-name" fields with an id for easier DOM scripting
    # do not override explictly set id attributes
    $html{id} = tovar($html{name}) if exists $html{name} and not exists $html{id};

    return wantarray ? %html : \%html; 
}

=head2 toname($string)

This is responsible for the auto-naming functionality of B<FormBuilder>.
Since you know Perl, it's easiest to just show what it does:

    $name =~ s!\.\w+$!!;                # lose trailing ".suf"
    $name =~ s![^a-zA-Z0-9.-/]+! !g;    # strip non-alpha chars
    $name =~ s!\b(\w)!\u$1!g;           # convert _ to space/upper

This results in something like "cgi_script.pl" becoming "Cgi Script".

=cut

sub toname ($) {
    # creates a name from a var/file name (like file2name)
    my $name = shift;
    $name =~ s!\.\w+$!!;                # lose trailing ".suf"
    $name =~ s![^a-zA-Z0-9.-/]+! !g;    # strip non-alpha chars
    $name =~ s!\b(\w)!\u$1!g;           # convert _ to space/upper
    return $name;
}

=head2 tovar($string)

Turns a string into a variable name. Basically just strips C<\W>,
and prefixes "fb_" on the front of it.

=cut

sub tovar ($) {
    my $name = shift;
    $name =~ s#\W+#_#g;
    $name =~ tr/_//s;   # squish __ accidentally
    $name =~ s/_$//;    # trailing _ on "[Yo!]"
    return $name;
}

=head2 ismember($el, @array)

Returns true if C<$el> is in C<@array>

=cut

sub ismember ($@) {
    # returns 1 if is in set, undef otherwise
    # do so case-insensitively
    my $test = lc shift;
    for (@_) {
        return 1 if $test eq lc $_;
    }
    return;
}

=head1 USELESS FUNCTIONS

These are totally useless outside of B<FormBuilder> internals.

=head2 autodata($ref)

This dereferences C<$ref> and returns the underlying data. For example:

    %hash  = autodata($hashref);
    @array = autodata($arrayref);

=cut

sub autodata ($) {
    # auto-derefs appropriately
    my $data = shift;
    return unless defined $data;
    if (my $ref = ref $data) {
        if ($ref eq 'ARRAY') {
            return wantarray ? @{$data} : $data;
        } elsif ($ref eq 'HASH') {
            return wantarray ? %{$data} : $data;
        } else {
            puke "Sorry, can't handle odd data ref '$ref' (only ARRAY or HASH)";
        }
    }
    return $data;   # return as-is
}

=head2 arghash(@_)

This returns a hash of options passed into a sub:

    sub field {
        my $self = shift;
        my %opt  = arghash(@_);
    }

It will return a hashref in scalar context.

=cut

sub arghash (;@) {
    return $_[0] if ref $_[0] && ! wantarray;

    belch "Odd number of arguments passed into ", (caller(1))[3]
       if @_ && @_ % 2 != 0;

    return wantarray ? @_ : { @_ };   # assume scalar hashref
}

=head2 arglist(@_)

This returns a list of args passed into a sub:

    sub value {
        my $self = shift;
        $self->{value} = arglist(@_);

It will return an arrayref in scalar context.

=cut

sub arglist (;@) {
    return $_[0] if ref $_[0] && ! wantarray;
    return wantarray ? @_ : [ @_ ];   # assume scalar arrayref
}

=head2 indent($num)

A simple sub that returns 4 spaces x C<$num>. Used to indent code.

=cut

sub indent (;$) {
    # return proper spaces to indent x 4 (code prettification)
    return '    ' x shift();
}

=head2 optalign(\@opt)

This returns the options specified as an array of arrayrefs, which
is what B<FormBuilder> expects internally.

=cut

sub optalign ($) {
    # This creates and returns the options needed based
    # on an $opt array/hash shifted in
    my $opt = shift;

    # "options" are the options for our select list
    my @opt = ();
    if (my $ref = ref $opt) {
        if ($ref eq 'CODE') {
            # exec to get options
            $opt = &$opt;
        }
        # we turn any data into ( ['key', 'val'], ['key', 'val'] )
        # have to check sub-data too, hence why this gets a little nasty
        @opt = ($ref eq 'HASH')
                  ? map { (ref $opt->{$_} eq 'ARRAY')
                            ? [$_, $opt->{$_}[0]] : [$_, $opt->{$_}] } keys %{$opt}
                  : map { (ref $_ eq 'HASH')  ? [ %{$_} ] : $_ } autodata $opt;
    } else {
        # this code should not be reached, but is here for safety
        @opt = ($opt);
    }

    return @opt;
}

=head2 optsort($sortref, @opt)

This sorts and returns the options based on C<$sortref>. It expects
C<@opt> to be in the format returned by C<optalign()>. The C<$sortref>
spec can be the string C<NAME>, C<NUM>, or a reference to a C<&sub>
which takes pairs of values to compare.

=cut

sub optsort ($@) {
    # pass in the sort and ref to opts
    my $sort = shift;
    my @opt  = @_;

    debug 2, "optsort($sort) called for field";

    # Currently any CODEREF can only sort on the value, which sucks if the
    # value and label are substantially different. This is caused by the fact
    # that options as specified by the user only have one element, not two
    # as hashes or generated options do. This should really be an option,
    # since sometimes you want the labels sorted too. Patches welcome.
    if ($sort eq 'alpha' || $sort eq 'name' || $sort eq 'NAME' || $sort eq 1) {
        @opt = sort { (autodata($a))[0] cmp (autodata($b))[0] } @opt;
    } elsif ($sort eq 'numeric' || $sort eq 'num' || $sort eq 'NUM') {
        @opt = sort { (autodata($a))[0] <=> (autodata($b))[0] } @opt;
    } elsif ($sort eq 'LABELNAME' || $sort eq 'LABEL') {
        @opt = sort { (autodata($a))[1] cmp (autodata($b))[1] } @opt;
    } elsif ($sort eq 'LABELNUM') {
        @opt = sort { (autodata($a))[1] <=> (autodata($b))[1] } @opt;
    } elsif (ref $sort eq 'CODE') {
        @opt = sort { eval &{$sort}((autodata($a))[0], (autodata($b))[0]) } @opt;
    } else {
        puke "Unsupported sort type '$sort' specified - must be 'NAME' or 'NUM'";
    }

    # return our options
    return @opt;
}

=head2 optval($opt)

This takes one of the elements of C<@opt> and returns it split up.
Useless outside of B<FormBuilder>.

=cut

sub optval ($) {
    my $opt = shift;
    my @ary = (ref $opt eq 'ARRAY') ? @{$opt} : ($opt);
    return wantarray ? @ary : $ary[0];
}

=head2 rearrange($ref, $name)

Rearranges arguments designed to be per-field from the global inheritor.

=cut

sub rearrange {
    my $from = shift;
    my $name = shift;
    my $ref  = ref $from;
    my $tval;
    if ($ref && $ref eq 'HASH') {
        $tval = $from->{$name}; 
    } elsif ($ref && $ref eq 'ARRAY') {
        $tval = ismember($name, @$from) ? 1 : 0;
    } else {
        $tval = $from;
    }
    return $tval;
}

=head2 basename

Returns the script name or $0 hacked up to the first dir

=cut

sub basename () {
    # Windows sucks so bad it's amazing to me.
    my $prog = File::Basename::basename($ENV{SCRIPT_NAME} || $0);
    $prog =~ s/\?.*//;     # lose ?p=v
    belch "Script basename() undefined somehow" unless $prog;
    return $prog;
}

1;
__END__

=head1 SEE ALSO

L<CGI::FormBuilder>

=head1 REVISION

$Id: Util.pm 100 2007-03-02 18:13:13Z nwiger $

=head1 AUTHOR

Copyright (c) L<Nate Wiger|http://nateware.com>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut

