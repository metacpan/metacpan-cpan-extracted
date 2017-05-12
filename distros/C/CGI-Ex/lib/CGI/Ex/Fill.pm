package CGI::Ex::Fill;

=head1 NAME

CGI::Ex::Fill - Fast but compliant regex based form filler

=cut

###----------------------------------------------------------------###
#  Copyright 2003-2015 - Paul Seamons                                #
#  Distributed under the Perl Artistic License without warranty      #
###----------------------------------------------------------------###

use strict;
use vars qw($VERSION
            @EXPORT @EXPORT_OK
            $REMOVE_SCRIPT
            $REMOVE_COMMENT
            $MARKER_SCRIPT
            $MARKER_COMMENT
            $OBJECT_METHOD
            $_TEMP_TARGET
            );
use base qw(Exporter);

BEGIN {
    $VERSION   = '2.44';
    @EXPORT    = qw(form_fill);
    @EXPORT_OK = qw(fill form_fill html_escape get_tagval_by_key swap_tagval_by_key);
};

### These directives are used to determine whether or not to
### remove html comments and script sections while filling in
### a form.  Default is on.  This may give some trouble if you
### have a javascript section with form elements that you would
### like filled in.
BEGIN {
    $REMOVE_SCRIPT  = 1;
    $REMOVE_COMMENT = 1;
    $MARKER_SCRIPT  = "\0SCRIPT\0";
    $MARKER_COMMENT = "\0COMMENT\0";
    $OBJECT_METHOD  = "param";
};

###----------------------------------------------------------------###

### Regex based filler - as opposed to HTML::Parser based HTML::FillInForm
### arguments are positional
### pos1 - text or textref - if textref it is modified in place
### pos2 - hash or cgi obj ref, or array ref of hash and cgi obj refs
### pos3 - target - to be used for choosing a specific form - default undef
### pos4 - boolean fill in password fields - default is true
### pos5 - hashref or arrayref of fields to ignore
sub form_fill {
    my $text          = shift;
    my $ref           = ref($text) ? $text : \$text;
    my $form          = shift;
    my $target        = shift;
    my $fill_password = shift;
    my $ignore        = shift || {};

    fill({
        text          => $ref,
        form          => $form,
        target        => $target,
        fill_password => $fill_password,
        ignore_fields => $ignore,
    });

    return ref($text) ? 1 : $$ref;
}

sub fill {
    my $args          = shift;
    my $ref           = $args->{'text'};
    my $form          = $args->{'form'};
    my $target        = $args->{'target'};
    my $ignore        = $args->{'ignore_fields'};
    my $fill_password = $args->{'fill_password'};

    my $forms = UNIVERSAL::isa($form, 'ARRAY') ? $form : [$form];
    $ignore = {map {$_ => 1} @$ignore} if UNIVERSAL::isa($ignore, 'ARRAY');
    $fill_password = 1 if ! defined $fill_password;


    ### allow for optionally removing comments and script
    my @comment;
    my @script;
    if (defined($args->{'remove_script'}) ? $args->{'remove_script'} : $REMOVE_SCRIPT) {
        $$ref =~ s|(<script\b.+?</script>)|push(@script, $1);$MARKER_SCRIPT|egi;
    }
    if (defined($args->{'remove_comment'}) ? $args->{'remove_comment'} : $REMOVE_COMMENT) {
        $$ref =~ s|(<!--.*?-->)|push(@comment, $1);$MARKER_COMMENT|eg;
    }

    ### if there is a target - focus in on it
    ### possible bug here - name won't be found if
    ### there is nested html inside the form tag that comes before
    ### the name field - if no close form tag - don't swap in anything
    if ($target) {
        local $_TEMP_TARGET = $target;
        $$ref =~ s{(<form            # open form
                    [^>]+            # some space
                    \bname=([\"\']?) # the name tag
                    $target          # with the correct name (allows for regex)
                    \2               # closing quote
                    .+?              # as much as there is
                    (?=</form>))     # then end
                   }{
                       my $str = $1;
                       local $args->{'text'} = \$str;
                       local $args->{'remove_script'}  = 0;
                       local $args->{'remove_comment'} = 0;
                       local $args->{'target'}         = undef;
                       fill($args);
                       $str; # return of the s///;
                   }sigex;

        ### put scripts and comments back and return
        $$ref =~ s/$MARKER_COMMENT/shift(@comment)/eg if $#comment != -1;
        $$ref =~ s/$MARKER_SCRIPT/ shift(@script) /eg if $#script  != -1;
        return 1;
    }

    ### build a sub to get a value from the passed forms on a request basis
    my %indexes = (); # store indexes for multivalued elements
    my $get_form_value = sub {
        my $key = shift;
        my $all = $_[0] && $_[0] eq 'all';
        if (! defined $key || ! length $key) {
            return $all ? [] : undef;
        }

        my $val;
        my $meth;
        foreach my $form (@$forms) {
            next if ! ref $form;
            if (UNIVERSAL::isa($form, 'HASH') && defined $form->{$key}) {
                $val = $form->{$key};
                last;
            } elsif ($meth = UNIVERSAL::can($form, $args->{'object_method'} || $OBJECT_METHOD)) {
                $val = $form->$meth($key);
                last if defined $val;
            } elsif (UNIVERSAL::isa($form, 'CODE')) {
                $val = $form->($key, $_TEMP_TARGET);
                last if defined $val;
            }
        }
        if (! defined $val) {
            return $all ? [] : undef;
        }

        ### fix up the value some
        if (UNIVERSAL::isa($val, 'CODE')) {
            $val = $val->($key, $_TEMP_TARGET);
        }
        if (UNIVERSAL::isa($val, 'ARRAY')) {
            $val = [@$val]; # copy the values
        } elsif (ref $val) {
            # die "Value for $key is not an array or a scalar";
            $val = "$val";  # stringify anything else
        }

        ### html escape them all
        html_escape(\$_) foreach (ref($val) ? @$val : $val);

        ### allow for returning all elements
        ### or one at a time
        if ($all) {
            return ref($val) ? $val : [$val];
        } elsif (ref($val)) {
            $indexes{$key} ||= 0;
            my $ret = $val->[$indexes{$key}];
            $ret = '' if ! defined $ret;
            $indexes{$key} ++; # don't wrap - if we run out of values - we're done
            return $ret;
        } else {
            return $val;
        }
    };


    ###--------------------------------------------------------------###

    ### First pass
    ### swap <input > form elements if they have a name
    $$ref =~ s{
        (<input \s (?: ([\"\'])(?:|.*?[^\\])\2 | [^>] )+ >) # nested html ok
        }{
            ### get the type and name - intentionally exlude names with nested "'
            my $tag   = $1;
            my $type  = uc(get_tagval_by_key(\$tag, 'type') || '');
            my $name  = get_tagval_by_key(\$tag, 'name');

            if ($name && ! $ignore->{$name}) {
                if (! $type
                    || $type eq 'HIDDEN'
                    || $type eq 'TEXT'
                    || $type eq 'FILE'
                    || ($type eq 'PASSWORD' && $fill_password)) {

                    my $value = $get_form_value->($name, 'next');
                    if (defined $value) {
                        swap_tagval_by_key(\$tag, 'value', $value);
                    } elsif (! defined get_tagval_by_key(\$tag, 'value')) {
                        swap_tagval_by_key(\$tag, 'value', '');
                    }

                } elsif ($type eq 'CHECKBOX'
                         || $type eq 'RADIO') {
                    my $values = $get_form_value->($name, 'all');
                    if (@$values) {
                        $tag =~ s{\s+\bCHECKED\b(?:=([\"\']?)checked\1)?(?=\s|>|/>)}{}ig;

                        my $fvalue = get_tagval_by_key(\$tag, 'value');
                        $fvalue = 'on' if ! defined $fvalue;
                        if (defined $fvalue) {
                            foreach (@$values) {
                                next if $_ ne $fvalue;
                                $tag =~ s|(\s*/?>\s*)$| checked="checked"$1|;
                                last;
                            }
                        }
                    }
                }

            }
            $tag; # return of swap
        }sigex;


    ### Second pass
    ### swap select boxes (must be done in such a way as to allow no closing tag)
    my @start = ();
    my @close = ();
    push @start, pos($$ref) - length($1) while $$ref =~ m|(<\s*select\b)|ig;
    push @close, pos($$ref) - length($1) while $$ref =~ m|(</\s*select\b)|ig;
    for (my $i = 0; $i <= $#start; $i ++) {
        while (defined($close[$i]) && $close[$i] < $start[$i]) {
            splice (@close,$i,1,());
        }
        if ($i == $#start) {
            $close[$i] = length($$ref) if ! defined $close[$i]; # set to end of string if no closing
        } elsif (! defined($close[$i]) || $close[$i] > $start[$i + 1]) {
            $close[$i] = $start[$i + 1]; # set to start of next select if no closing or > next select
        }
    }
    for (my $i = $#start; $i >= 0; $i --) {
        my $opts = substr($$ref, $start[$i], $close[$i] - $start[$i]);
        $opts =~ s{
            (<select \s                                 # opening
             (?: "" | '' | ([\"\']).*?[^\\]\2 | [^>] )+ # nested html ok
             >)                                         # end of tag
            }{}sxi || next;
        next if ! $opts;
        my $tag    = $1;
        my $name   = get_tagval_by_key(\$tag, 'name');
        my $values = $ignore->{$name} ? [] : $get_form_value->($name, 'all');
        if ($#$values != -1) {
            my $n = $opts =~ s{
                (<option[^>]*>)           # opening tag - no embedded > allowed
                    (.*?)                   # the text value
                    (?=<option|$|</option>) # the next tag
                }{
                    my ($tag2, $opt) = ($1, $2);
                    $tag2 =~ s%\s+\bSELECTED\b(?:=([\"\']?)selected\1)?(?=\s|>|/>)%%ig;

                    my $fvalues = get_tagval_by_key(\$tag2, 'value', 'all');
                    my $fvalue  = @$fvalues ? $fvalues->[0]
                        : $opt =~ /^\s*(.*?)\s*$/ ? $1 : "";
                    foreach (@$values) {
                        next if $_ ne $fvalue;
                        $tag2 =~ s|(\s*/?>\s*)$| selected="selected"$1|;
                        last;
                    }
                    "$tag2$opt"; # return of the swap
                }sigex;
            if ($n) {
                substr($$ref, $start[$i], $close[$i] - $start[$i], "$tag$opts");
            }
        }
    }


    ### Third pass
    ### swap textareas (must be done in such a way as to allow no closing tag)
    @start = ();
    @close = ();
    push @start, pos($$ref) - length($1) while $$ref =~ m|(<\s*textarea\b)|ig;
    push @close, pos($$ref) - length($1) while $$ref =~ m|(</\s*textarea\b)|ig;
    for (my $i = 0; $i <= $#start; $i ++) {
        while (defined($close[$i]) && $close[$i] < $start[$i]) {
            splice (@close,$i,1,()); # get rid of extra closes
        }
        if ($i == $#start) {
            $close[$i] = length($$ref) if ! defined $close[$i]; # set to end of string if no closing
        } elsif (! defined($close[$i]) || $close[$i] > $start[$i + 1]) {
            splice(@close, $i, 0, $start[$i + 1]); # set to start of next select if no closing or > next select
        }
    }
    my $offset = 0;
    for (my $i = 0; $i <= $#start; $i ++) {
        my $oldval = substr($$ref, $start[$i] + $offset, $close[$i] - $start[$i]);
        $oldval =~ s{
            (<textarea \s                               # opening
             (?: "" | '' | ([\"\']).*?[^\\]\2 | [^>] )+ # nested html ok
             >)                                         # end of tag
            }{}sxi || next;
        my $tag  = $1;
        my $name = get_tagval_by_key(\$tag, 'name');
        if ($name && ! $ignore->{$name}) {
            my $value = $get_form_value->($name, 'next');
            next if ! defined $value;
            substr($$ref, $start[$i] + $offset, $close[$i] - $start[$i], "$tag$value");
            $offset += length($value) - length($oldval);
        }
    }

    ### put scripts and comments back and return
    $$ref =~ s/$MARKER_COMMENT/shift(@comment)/eg if $#comment != -1;
    $$ref =~ s/$MARKER_SCRIPT/ shift(@script) /eg if $#script  != -1;
    return 1;
}


### yet another html escaper
### allow pass by value or by reference (reference is modified inplace)
sub html_escape {
    my $str = shift;
    return $str if ! $str;
    my $ref = ref($str) ? $str : \$str;

    $$ref =~ s/&/&amp;/g;
    $$ref =~ s/</&lt;/g;
    $$ref =~ s/>/&gt;/g;
    $$ref =~ s/\"/&quot;/g;

    return ref($str) ? 1 : $$ref;
}

### get a named value for key="value" pairs
### usage: my $val     = get_tagval_by_key(\$tag, $key);
### usage: my $valsref = get_tagval_by_key(\$tag, $key, 'all');
sub get_tagval_by_key {
    my $tag = shift;
    my $ref = ref($tag) ? $tag : \$tag;
    my $key = lc(shift);
    my $all = $_[0] && $_[0] eq 'all';
    my @all = ();
    pos($$ref) = 0; # fix for regex below not resetting and forcing order on key value pairs

    ### loop looking for tag pairs
    while ($$ref =~ m{
        (?<![\w\.\-])                  # 0 - not proceded by letter or .
            ([\w\.\-]+)                  # 1 - the key
            \s*=                         # equals
            (?: \s*([\"\'])(|.*?[^\\])\2 # 2 - a quote, 3 - the quoted
             |  ([^\s/]*? (?=\s|>|/>))   # 4 - a non-quoted string
             )
        }sigx) {
        next if lc($1) ne $key;
        my ($val,$quot) = ($2) ? ($3,$2) : ($4,undef);
        $val =~ s/\\$quot/$quot/ if $quot;
        return $val if ! $all;
        push @all, $val;
    }
    return undef if ! $all;
    return \@all;
}

### swap out values for key="value" pairs
### usage: my $count  = &swap_tagval_by_key(\$tag, $key, $val);
### usage: my $newtag = &swap_tagval_by_key($tag, $key, $val);
sub swap_tagval_by_key {
    my $tag = shift;
    my $ref = ref($tag) ? $tag : \$tag;
    my $key = lc(shift);
    my $val = shift;
    my $n   = 0;

    ### swap a key/val pair at time
    $$ref =~ s{(^\s*<\s*\w+\s+ | \G\s+)         # 1 - open tag or previous position
                   ( ([\w\-\.]+)                  # 2 - group, 3 - the key
                     (\s*=)                       # 4 - equals
                     (?: \s* ([\"\']) (?:|.*?[^\\]) \5 # 5 - the quote mark, the quoted
                      |  [^\s/]*? (?=\s|>|/>)    # a non-quoted string (may be zero length)
                      )
                     | ([^\s/]+?) (?=\s|>|/>)      # 6 - a non keyvalue chunk (CHECKED)
                     )
               }{
                   if (defined($3) && lc($3) eq $key) { # has matching key value pair
                       if (! $n ++) {  # only put value back on first match
                           "$1$3$4\"$val\""; # always double quote
                       } else {
                           $1; # second match
                       }
                   } elsif (defined($6) && lc($6) eq $key) { # has matching key
                       if (! $n ++) {  # only put value back on first match
                           "$1$6=\"$val\"";
                       } else {
                           $1; # second match
                       }
                   } else {
                       "$1$2"; # non-keyval
                   }
               }sigex;

    ### append value on if none were swapped
    if (! $n) {
        $$ref =~ s|(\s*/?>\s*)$| value="$val"$1|;
        $n = -1;
    }

    return ref($tag) ? $n : $$ref;
}

1;

__END__

###----------------------------------------------------------------###

=head1 SYNOPSIS

    use CGI::Ex::Fill qw(form_fill fill);

    my $text = my_own_template_from_somewhere();

    my $form = CGI->new;
    # OR
    # my $form = {key => 'value'}
    # OR
    # my $form = [CGI->new, CGI->new, {key1 => 'val1'}, CGI->new];


    form_fill(\$text, $form); # modifies $text

    # OR
    # my $copy = form_fill($text, $form); # copies $text

    # OR
    fill({
        text => \$text,
        form => $form,
    });


    # ALSO

    my $formname = 'formname';     # form to parse (undef = anytable)
    my $fp = 0;                    # fill_passwords ? default is true
    my $ignore = ['key1', 'key2']; # OR {key1 => 1, key2 => 1};

    form_fill(\$text, $form, $formname, $fp, $ignore);

    # OR
    fill({
        text          => \$text,
        form          => $form,
        target        => 'my_formname',
        fill_password => $fp,
        ignore_fields => $ignore,
    });

    # ALSO

    ### delay getting the value until we find an element that needs it
    my $form = {key => sub {my $key = shift; # get and return value}};


=head1 DESCRIPTION

form_fill is directly comparable to HTML::FillInForm.  It will pass
the same suite of tests (actually - it is a little bit kinder on the
parse as it won't change case, reorder your attributes, or alter
miscellaneous spaces and it won't require the HTML to be well formed).

HTML::FillInForm is based upon HTML::Parser while CGI::Ex::Fill is
purely regex driven.  The performance of CGI::Ex::Fill will be better
on HTML with many markup tags because HTML::Parser will parse each tag
while CGI::Ex::Fill will search only for those tags it knows how to
handle.  And CGI::Ex::Fill generally won't break on malformed html.

On tiny forms (< 1 k) form_fill was ~ 13% slower than FillInForm.  If
the html document incorporated very many entities at all, the
performance of FillInForm goes down (adding 360 <br> tags pushed
form_fill to ~ 350% faster).  However, if you are only filling in one
form every so often, then it shouldn't matter which you use - but
form_fill will be nicer on the tags and won't balk at ugly html and
will decrease performance only at a slow rate as the size of the html
increases.  See the benchmarks in the t/samples/bench_cgix_hfif.pl
file for more information (ALL BENCHMARKS SHOULD BE TAKEN WITH A GRAIN
OF SALT).

There are two functions, fill and form_fill.  The function fill takes
a hashref of named arguments.  The function form_fill takes a list
of positional parameters.

=head1 ARGUMENTS TO form_fill

The following are the arguments to the main function C<fill>.

=over 4

=item text

A reference to an html string that includes one or more forms.

=item form

A form hash, CGI object, or an array of hashrefs and objects.

=item target

The name of the form to swap.  Default is undef which means
to swap all form entities in all forms.

=item fill_password

Default true.  If set to false, fields of type password will
not be refilled.

=item ignore_fields

Hashref of fields to be ignored from swapping.

=item remove_script

Defaults to the package global $REMOVE_SCRIPT which defaults to true.
Removes anything in <script></script> tags which often cause problems for
parsers.

=item remove_comment

Defaults to the package global $REMOVE_COMMENT which defaults to true.
Removes anything in <!-- --> tags which can sometimes cause problems for
parsers.

=item object_method

The method to call on objects passed to the form argument.  Default value
is the package global $OBJECT_METHOD which defaults to 'param'.  If a
CGI object is passed, it would call param on that object passing
the desired keyname as an argument.

=back

=head1 ARGUMENTS TO form_fill

The following are the arguments to the legacy function C<form_fill>.

=over 4

=item C<\$html>

A reference to an html string that includes one or more forms or form
entities.

=item C<\%FORM>

A form hash, or CGI query object, or an arrayref of multiple hash refs
and/or CGI query objects that will supply values for the form.

=item C<$form_name>

The name of the form to fill in values for.  The default is undef
which indicates that all forms are to be filled in.

=item C<$swap_pass>

Default true.  Indicates that C<<lt>input type="password"<gt>> fields
are to be swapped as well.  Set to false to disable this behavior.

=item C<\%IGNORE_FIELDS> OR C<\@IGNORE_FIELDS>

A hash ref of key names or an array ref of key names that will be
ignored during the fill in of the form.

=back

=head1 BEHAVIOR

fill and form_fill will attempt to DWYM when filling in values.  The following behaviors
are used on the following types of form elements.

=over 4

=item C<E<lt>input type="text"E<gt>>

The following rules are used when matching this type:

   1) Get the value from the form that matches the input's "name".
   2) If the value is defined - it adds or replaces the existing value.
   3) If the value is not defined and the existing value is not defined,
      a value of "" is added.

For example:

   my $form = {foo => "FOO", bar => "BAR", baz => "BAZ"};

   my $html = '
       <input type=text name=foo>
       <input type=text name=foo>
       <input type=text name=bar value="">
       <input type=text name=baz value="Something else">
       <input type=text name=hem value="Another thing">
       <input type=text name=haw>
   ';

   form_fill(\$html, $form);

   $html eq   '
       <input type=text name=foo value="FOO">
       <input type=text name=foo value="FOO">
       <input type=text name=bar value="BAR">
       <input type=text name=baz value="BAZ">
       <input type=text name=hem value="Another thing">
       <input type=text name=haw value="">
   ';


If the value returned from the form is an array ref, the values of the array ref
will be sequentially used for each input found by that name until the values
run out.  If the value is not an array ref - it will be used to fill in any values
by that name.  For example:

   $form = {foo => ['aaaa', 'bbbb', 'cccc']};

   $html = '
       <input type=text name=foo>
       <input type=text name=foo>
       <input type=text name=foo>
       <input type=text name=foo>
       <input type=text name=foo>
   ';

   form_fill(\$html, $form);

   $html eq  '
       <input type=text name=foo value="aaaa">
       <input type=text name=foo value="bbbb">
       <input type=text name=foo value="cccc">
       <input type=text name=foo value="">
       <input type=text name=foo value="">
   ';

=item C<E<lt>input type="hidden"E<gt>>

Same as C<E<lt>input type="text"E<gt>>.

=item C<E<lt>input type="password"E<gt>>

Same as C<E<lt>input type="text"E<gt>>.

=item C<E<lt>input type="file"E<gt>>

Same as C<E<lt>input type="text"E<gt>>.  (Note - this is subject
to browser support for pre-population)

=item C<E<lt>input type="checkbox"E<gt>>

As each checkbox is found the following rules are applied:

    1) Get the values from the form (do nothing if no values found)
    2) Remove any existing "checked=checked" or "checked" markup from the tag.
    3) Compare the "value" field to the values and mark with checked="checked"
    if there is a match.

If no "value" field is found in the html, a default value of "on" will be used (which is
what most browsers will send as the default value for checked boxes without
"value" fields).

   $form = {foo => 'FOO', bar => ['aaaa', 'bbbb', 'cccc'], baz => 'on'};

   $html = '
       <input type=checkbox name=foo value="123">
       <input type=checkbox name=foo value="FOO">
       <input type=checkbox name=bar value="aaaa">
       <input type=checkbox name=bar value="cccc">
       <input type=checkbox name=bar value="dddd" checked="checked">
       <input type=checkbox name=baz>
   ';

   form_fill(\$html, $form);

   $html eq  '
       <input type=checkbox name=foo value="123">
       <input type=checkbox name=foo value="FOO" checked="checked">
       <input type=checkbox name=bar value="aaaa" checked="checked">
       <input type=checkbox name=bar value="cccc" checked="checked">
       <input type=checkbox name=bar value="dddd">
       <input type=checkbox name=baz checked="checked">
   ';


=item C<E<lt>input type="radio"E<gt>>

Same as C<E<lt>input type="checkbox"E<gt>>.

=item C<E<lt>selectE<gt>>

As each select box is found the following rules are applied (these rules are
applied regardless of if the box is a select-one or a select-multi - if multiple
values are selected on a select-one it is up to the browser to choose which one
to highlight):

    1) Get the values from the form (do nothing if no values found)
    2) Remove any existing "selected=selected" or "selected" markup from the tag.
    3) Compare the "value" field to the values and mark with selected="selected"
    if there is a match.
    4) If there is no "value" field - use the text in between the "option" tags.

    (Note: There does not need to be a closing "select" tag or closing "option" tag)


   $form = {foo => 'FOO', bar => ['aaaa', 'bbbb', 'cccc']};

   $html = '
       <select name=foo><option>FOO<option>123<br>

       <select name=bar>
         <option>aaaa</option>
         <option value="cccc">cccc</option>
         <option value="dddd" selected="selected">dddd</option>
       </select>
   ';

   form_fill(\$html, $form);

   ok(
   $html eq  '
       <select name=foo><option selected="selected">FOO<option>123<br>

       <select name=bar>
         <option selected="selected">aaaa</option>
         <option value="cccc" selected="selected">cccc</option>
         <option value="dddd">dddd</option>
       </select>
   ', "Perldoc example 4 passed");


=item C<E<lt>textareaE<gt>>

The rules for swapping textarea are as follows:

   1) Get the value from the form that matches the textarea's "name".
   2) If the value is defined - it adds or replaces the existing value.
   3) If the value is not defined, the text area is left alone.

   (Note - there does not need to be a closing textarea tag.  In the case of
    a missing close textarea tag, the contents of the text area will be
    assumed to be the start of the next textarea of the end of the document -
    which ever comes sooner)

If the form returned an array ref of values, then these values will be
used sequentially each time a textarea by that name is found.  If a single value
(not array ref) is found, that value will be used for each textarea by that name.

For example.

   $form = {foo => 'FOO', bar => ['aaaa', 'bbbb']};

   $html = '
       <textarea name=foo></textarea>
       <textarea name=foo></textarea>

       <textarea name=bar>
       <textarea name=bar></textarea><br>
       <textarea name=bar>dddd</textarea><br>
       <textarea name=bar><br><br>
   ';

   form_fill(\$html, $form);

   $html eq  '
       <textarea name=foo>FOO</textarea>
       <textarea name=foo>FOO</textarea>

       <textarea name=bar>aaaa<textarea name=bar>bbbb</textarea><br>
       <textarea name=bar></textarea><br>
       <textarea name=bar>';

=item C<E<lt>input type="submit"E<gt>>

Does nothing.  The value for submit should typically be set by the
templating system or application system.

=item C<E<lt>input type="button"E<gt>>

Same as submit.

=back

=head1 HTML COMMENT / JAVASCRIPT

Because there are too many problems that could occur with html
comments and javascript, form_fill temporarily removes them during the
fill.  You may disable this behavior by setting $REMOVE_COMMENT and
$REMOVE_SCRIPT to 0 before calling form_fill.  The main reason for
doing this would be if you wanted to have form elements inside the
javascript and comments get filled.  Disabling the removal only
results in a speed increase of 5%. The function uses \0COMMENT\0 and
\0SCRIPT\0 as placeholders so it would be good to avoid these in your
text (Actually they may be reset to whatever you'd like via
$MARKER_COMMENT and $MARKER_SCRIPT).

=head1 UTILITY FUNCTIONS

=over 4

=item C<html_escape>

Very minimal entity escaper for filled in values.

    my $escaped = html_escape($unescaped);

    html_escape(\$text_to_escape);

=item C<get_tagval_by_key>

Get a named value for from an html tag (key="value" pairs).

    my $val     = get_tagval_by_key(\$tag, $key);
    my $valsref = get_tagval_by_key(\$tag, $key, 'all'); # get all values

=item C<swap_tagval_by_key>

Swap out values in an html tag (key="value" pairs).

    my $count  = swap_tagval_by_key(\$tag, $key, $val); # modify ref
    my $newtag = swap_tagval_by_key($tag, $key, $val);  # copies tag

=back

=head1 LICENSE

This module may distributed under the same terms as Perl itself.

=head1 AUTHOR

Paul Seamons <perl at seamons dot com>

=cut
