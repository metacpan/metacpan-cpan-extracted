
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

package CGI::FormBuilder::Field;

=head1 NAME

CGI::FormBuilder::Field - Base class for FormBuilder fields

=head1 SYNOPSIS

    use CGI::FormBuilder::Field;

    # delegated straight from FormBuilder
    my $f = CGI::FormBuilder::Field->new($form, name => 'whatever');

    # attribute functions
    my $n = $f->name;         # name of field
    my $n = "$f";             # stringify to $f->name

    my $t = $f->type;         # auto-type
    my @v = $f->value;        # auto-stickiness
    my @o = $f->options;      # options, aligned and sorted

    my $l = $f->label;        # auto-label
    my $h = $f->tag;          # field XHTML tag (name/type/value)
    my $s = $f->script;       # per-field JS validation script

    my $m = $f->message;      # error message if invalid
    my $m = $f->jsmessage;    # JavaScript error message

    my $r = $f->required;     # required?
    my $k = $f->validate;     # run validation check

    my $v = $f->tag_value;    # value in tag (stickiness handling)
    my $v = $f->cgi_value;    # CGI value if any
    my $v = $f->def_value;    # manually-specified value

    $f->field(opt => 'val');  # FormBuilder field() call

=cut

use Carp;   # confess used manually in this pkg
use strict;
use warnings;
no  warnings 'uninitialized';

use CGI::FormBuilder::Util;

our $VERSION = '3.10';
our $AUTOLOAD;

# what to generate for tag
our @TAGATTR = qw(name type multiple jsclick);

# Catches for special validation patterns
# These are semi-Perl patterns; they must be usable by JavaScript
# as well so they do not take advantage of features JS can't use
# If the value is an arrayref, then the second arg is a tag to
# spit out at the person after the field label to help with format

our %VALIDATE = (
    WORD     => '/^\w+$/',
    NAME     => '/^[a-zA-Z]+$/',
    NUM      => '/^-?\s*[0-9]+\.?[0-9]*$|^-?\s*\.[0-9]+$/',    # 1, 1.25, .25
    INT      => '/^-?\s*[0-9]+$/',
    FLOAT    => '/^-?\s*[0-9]+\.[0-9]+$/',
    PHONE    => '/^\d{3}\-\d{3}\-\d{4}$|^\(\d{3}\)\s+\d{3}\-\d{4}$/',
    INTPHONE => '/^\+\d+[\s\-][\d\-\s]+$/',
    EMAIL    => '/^[\w\-\+\._]+\@[a-zA-Z0-9][-a-zA-Z0-9\.]*\.[a-zA-Z]+$/',
    CARD     => '/^\d{4}[\- ]?\d{4}[\- ]?\d{4}[\- ]?\d{4}$|^\d{4}[\- ]?\d{6}[\- ]?\d{5}$/',
    MMYY     => '/^(0?[1-9]|1[0-2])\/?[0-9]{2}$/',
    MMYYYY   => '/^(0?[1-9]|1[0-2])\/?[0-9]{4}$/',
    DATE     => '/^(0?[1-9]|1[0-2])\/?(0?[1-9]|[1-2][0-9]|3[0-1])\/?[0-9]{4}$/',
    EUDATE   => '/^(0?[1-9]|[1-2][0-9]|3[0-1])\/?(0?[1-9]|1[0-2])\/?[0-9]{4}$/',
    TIME     => '/^[0-9]{1,2}:[0-9]{2}$/',
    AMPM     => '/^[0-9]{1,2}:[0-9]{2}\s*([aA]|[pP])[mM]$/',
    ZIPCODE  => '/^\d{5}$|^\d{5}\-\d{4}$/',
    STATE    => '/^[a-zA-Z]{2}$/',
    COUNTRY  => '/^[a-zA-Z]{2}$/',
    IPV4     => '/^([0-1]??\d{1,2}|2[0-4]\d|25[0-5])\.([0-1]??\d{1,2}|2[0-4]\d|25[0-5])\.([0-1]??\d{1,2}|2[0-4]\d|25[0-5])\.([0-1]??\d{1,2}|2[0-4]\d|25[0-5])$/',
    NETMASK  => '/^([0-1]??\d{1,2}|2[0-4]\d|25[0-5])\.([0-1]??\d{1,2}|2[0-4]\d|25[0-5])\.([0-1]??\d{1,2}|2[0-4]\d|25[0-5])\.([0-1]??\d{1,2}|2[0-4]\d|25[0-5])$/',
    FILE     => '/^[\/\w\.\-_]+$/',
    WINFILE  => '/^[a-zA-Z]:\\[\\\w\s\.\-]+$/',
    MACFILE  => '/^[:\w\.\-_]+$/',
    USER     => '/^[-a-zA-Z0-9_]{4,8}$/',
    HOST     => '/^[a-zA-Z0-9][-a-zA-Z0-9]*$/',
    DOMAIN   => '/^[a-zA-Z0-9][-a-zA-Z0-9\.]*\.[a-zA-Z]+$/',
    ETHER    => '/^[\da-f]{1,2}[\.:]?[\da-f]{1,2}[\.:]?[\da-f]{1,2}[\.:]?[\da-f]{1,2}[\.:]?[\da-f]{1,2}[\.:]?[\da-f]{1,2}$/i',
    # Many thanks to Mark Belanger for these additions
    FNAME    => '/^[a-zA-Z]+[- ]?[a-zA-Z]*$/',
    LNAME    => '/^[a-zA-Z]+[- ]?[a-zA-Z]+\s*,?([a-zA-Z]+|[a-zA-Z]+\.)?$/',
    CCMM     => '/^0[1-9]|1[012]$/',
    CCYY     => '/^[1-9]{2}$/',
);

# stringify to name
use overload '""'   => sub { $_[0]->name },
            #'.'    => sub { $_[0]->name },
             '0+'   => sub { $_[0]->name },
             'bool' => sub { $_[0]->name },
             'eq'   => sub { $_[0]->name eq $_[1] };

sub new {
    puke "Not enough arguments for Field->new()" unless @_ > 1;
    my $self = shift;

    my $form = shift;       # need for top-level attr
    my $opt  = arghash(@_);
    $opt->{_form} = $form;    # parental ptr
    puke "Missing name for field() in Field->new()"
        unless $opt->{name};

    my $class = ref($self) || $self;
    my $f = bless $opt, $class;

    # Note that at this point, the object is a generic field
    # without a type. Not until it's called via $f->type does
    # it get a type, which affects its HTML representation.
    # Everything else is inherited from this module.

    return $f;
}

sub field {
    my $self = shift;

    if (ref $_[0] || @_ > 1) {
        my $opt = arghash(@_);
        while (my($k,$v) = each %$opt) {
            next if $k eq 'name';   # segfault??
            $self->{$k} = $v;
        }
    }
    return $self->value;    # needed for @v = $form->field('name')
}

*override = \&force;    # CGI.pm
sub force {
    my $self = shift;
    $self->{force} = shift if @_;
    return $self->{force} || $self->{override};
}

# grab the field_other field if other => 1 specified
sub other {
    my $self = shift;
    $self->{other} = shift if @_;
    return unless $self->{other};
    $self->{other} = {} unless ref $self->{other};
    $self->{other}{name} = $self->othername;
    return wantarray ? %{$self->{other}} : $self->{other};
}

sub othername {
    my $self = shift;
    return $self->{_form}->othername . '_' . $self->name;
}

sub othertag {
    my $self = shift;
    return '' unless $self->other;

    # add an additional tag for our _other field
    my $oa = $self->other;  # other attr

    # default settings
    $oa->{type}  ||= 'text';
    my $v = $self->{_form}->cgi_param($self->othername);
    #$v = $self->tag_value unless defined $v;
    if ($self->sticky and defined $v) {
        $oa->{value} = $v;
    }

    $oa->{disabled} = 'disabled' if $self->javascript && ! defined $v;   # fanciness
    return htmltag('input', $oa);
}

sub growname {
    my $self = shift;
    return $self->{_form}->growname . '_' . $self->name;
}

sub cgi_value {
    my $self = shift;
    debug 2, "$self->{name}: called \$field->cgi_value";
    puke "Cannot set \$field->cgi_value manually" if @_;
    if (my @v = $self->{_form}{params}->can('multi_param') ? $self->{_form}{params}->multi_param($self->name) : $self->{_form}{params}->param($self->name)) {
        for my $v (@v) {
            if ($self->other && $v eq $self->othername) {
                debug 1, "$self->{name}: redoing value from _other field";
                $v = $self->{_form}{params}->param($self->othername);
            }
        }
        local $" = ',';
        debug 2, "$self->{name}: cgi value = (@v)";
        return wantarray ? @v : $v[0];
    }
    return;
}

sub def_value {
    my $self = shift;
    debug 2, "$self->{name}: called \$field->def_value";
    if (@_) {
        $self->{value} = arglist(@_);  # manually set
        delete $self->{_cache}{type};    # clear auto-type
    }
    my @v = autodata $self->{value};
    local $" = ',';
    debug 2, "$self->{name}: def value = (@v)";
    $self->inflate_value(\@v);
    return wantarray ? @v : $v[0];
}

sub inflate_value {
    my ($self, $v_aref) = @_;

    debug 2, "$self->{name}: called \$field->inflate_value";

    # trying to inflate?
    return unless exists $self->{inflate};
    debug 2, "$self->{name}: inflate routine exists";

    # must return real values to the validate() routine:
    return if grep { ((caller($_))[3] eq 'CGI::FormBuilder::Field::validate') } 
                1..2;
    debug 2, "$self->{name}: made sure inflate not called via validate";

    # must be valid:
    #return unless exists $self->{invalid} && ! $self->{invalid};
    return if $self->invalid;
    debug 2, "$self->{name}: valid field, inflate proceeding";

    my $cache = $self->{inflated_values};

    if ($cache && ref $cache eq 'ARRAY' && @{$cache}) {
        # could have been cached by validate() check
        @{ $v_aref } = @{ $self->{inflated_values} };
        debug 2, "$self->{name}: using cached inflate "
               . "value from validate()";
    }
    else {
        debug 2, "$self->{name}: new inflate";

        puke("Field $self->{name}: inflate must be a reference to a \\&sub")
            if ref $self->{inflate} ne 'CODE';

        eval { @{ $v_aref } = map $self->{inflate}->($_), @{ $v_aref } };

        # no choice but to die hard if didn't validate() first
        puke("Field $self->{name}: inflate failed: $@") if $@;

        # cache the result:
        @{ $self->{inflated_values} } = @{ $v_aref };
    }
    return;
}

# CGI.pm happiness
*default  = \&value;
*defaults = \&value;
*values   = \&value;
sub value {
    my $self = shift;
    debug 2, "$self->{name}: called \$field->value(@_)";
    if (@_) {
        $self->{value} = arglist(@_);  # manually set
        delete $self->{_cache}{type};    # clear auto-type
    }
    unless ($self->force) {
        # CGI wins if stickiness is set
        debug 2, "$self->{name}: sticky && ! force";
        if (my @v = $self->cgi_value) {
            local $" = ',';
            debug 1, "$self->{name}: returning value (@v)";
            $self->inflate_value(\@v);
            return wantarray ? @v : $v[0];
        }
    }
    debug 2, "no cgi found, returning def_value";
    # no CGI value, or value was forced, or not sticky
    return $self->def_value;
}

# The value in the <tag> may be different than in code (sticky)
sub tag_value {
    my $self = shift;
    debug 2, "$self->{name}: called \$field->tag_value";
    if (@_) {
        # setting the tag_value manually is odd...
        $self->{tag_value} = arglist(@_);
        delete $self->{_cache}{type};
    }
    return $self->{tag_value} if $self->{tag_value};

    if ($self->sticky && ! $self->force) {
        # CGI wins if stickiness is set
        debug 2, "$self->{name}: sticky && ! force";
        if (my @v = $self->cgi_value) {
            local $" = ',';
            debug 1, "$self->{name}: returning value (@v)";
            return wantarray ? @v : $v[0];
        }
    }
    debug 2, "no cgi found, returning def_value";
    # no CGI value, or value was forced, or not sticky
    return $self->def_value;
}

# Handle "b:select" and "b:option"
sub tag_name {
    my $self = shift;
    $self->{tag_name} = shift if @_;
    return $self->{tag_name} if $self->{tag_name};
    # Try to guess
    my($tag) = ref($self) =~ /^CGI::FormBuilder::Field::(.+)/;
    puke "Can't resolve tag for untyped field '$self->{name}'"
        unless $tag;
    return $tag;
}

sub type {
    local $^W = 0;    # -w sucks
    my $self = shift;
    if (@_) {
        $self->{type} = lc shift;
        delete $self->{_cache}{type};   # forces rebless
        debug 2, "setting field type to '$self->{type}'";
    }

    #
    # catch for new way of saying static => 1
    #
    # confirm() will set ->static but not touch $self->{type},
    # so make sure it's not a field the user hid themselves
    #
    if ($self->static && $self->{type} ne 'hidden') {
        $self->{type} = 'static';
        delete $self->{_cache}{type};   # forces rebless
        debug 2, "setting field type to '$self->{type}'";
    }

    # manually set
    debug 2, "$self->{name}: called \$field->type (manual = '$self->{type}')";

    # The $field->type method is called so often that it really slows
    # things down. As such, we cache the type and use it *unless* the
    # value has been updated manually (we assume one CGI instance).
    # See value() for its deletion of this cache
    return $self->{_cache}{type} if $self->{_cache}{type};

    my $name = $self->{name};
    my $type;
    unless ($type = lc $self->{type}) {
        #
        # Unless the type has been set explicitly, we make a guess 
        # based on how many items there are to display, which is 
        # basically, how many options we have. Our 'jsclick' option
        # is now changed down in the javascript section, fixing a bug
        #
        if ($self->{_form}->smartness) {
            debug 1, "$name: input type not set, checking for options"; 
            if (my $n = $self->options) {
                debug 2, "$name: has options, so setting to select|radio|checkbox";
                if ($n >= $self->selectnum) {
                    debug 2, "$name: has more than selectnum (", $self->selectnum, 
                             ") options, setting to 'select'";
                    $type = 'select';
                } else {
                    # Something is a checkbox if it is a multi-valued box.
                    # However, it is *also* a checkbox if only single-valued options,
                    # otherwise you can't unselect it.
                    my @v = $self->def_value;   # only on manual, not dubious CGI
                    if ($self->multiple || @v > 1 || $n == 1) {
                        debug 2, "$name: has multiple select < selectnum, setting to 'checkbox'";
                        $type = 'checkbox';
                    } else {
                        debug 2, "$name: has singular select < selectnum, setting to 'radio'";
                        $type = 'radio';
                    }
                }
            } elsif ($self->{_form}->smartness > 1) {
                debug 2, "$name: smartness > 1, auto-inferring type based on value";
                # only autoinfer field types based on values with high smartness
                my @v = $self->def_value;   # only on manual, not dubious CGI
                if ($name =~ /passw(or)?d/i) {
                    $type = 'password';
                } elsif ($name =~ /(?:details?|comments?)$/i
                        || grep /\n|\r/, @v || $self->cols || $self->rows) {
                    $type = 'textarea';
                } elsif ($name =~ /\bfile/i) {
                    $type = 'file';
                }
            } else {
                debug 2, "no options found";
            }
        }
        $type ||= 'text';   # default if no fancy settings matched or no smartness
    }
    debug 1, "$name: field set to type '$type' (reblessing)";

    # Store type in cache for speediness
    $self->{_cache}{type} = $type;

    # Re-bless into the appropriate package
    my $pkg = __PACKAGE__ . '::' . $type;
    $pkg =~ s/\-/_/g;  # handle HTML5 type names ala 'datetime-local'
    eval "require $pkg";
    puke "Can't load $pkg for field '$name' (type '$type'): $@" if $@;
    bless $self, $pkg;

    return $type;
}

sub label {
    my $self = shift;
    $self->{label} = shift if @_;
    return $self->{label} if defined $self->{label};    # manually set
    return toname($self->name);
}

sub attr {
    my $self = shift;
    if (my $k = shift) {
        $self->{$k} = shift if @_;
        return exists $self->{$k} ? $self->{$k} : $self->{_form}->$k;
    } else {
        # exhaustive expansion, but don't invoke validate().
        my %ret;
        for my $k (@TAGATTR, keys %$self) {
            my $v;
            next if $k =~ /^_/ || $k eq 'validate';   # don't invoke validate
            if ($k eq 'jsclick') {
                # always has to be a special fucking case
                $v = $self->{$k};
                $k = $self->jstype;
            } elsif (exists $self->{$k}) {
                # flat val
                $v = $self->{$k};
                $v = lc $v if $k eq 'type';
            } else {
                $v = $self->$k;
            }
            next unless defined $v;

            debug 3, "$self->{name}: \$attr{$k} = '$v'";
            $ret{$k} = $v;
        }

        # More special cases
        # 1. disabled field/form
        $self->disabled ? $ret{disabled} = 'disabled' 
                        : delete $ret{disabled};

        # 2. setup class for stylesheets and JS vars
        $ret{class} ||= $self->{_form}->class('_'.
                                            ($ret{type} eq 'text' ? 'input' : $ret{type})
                                        );

        # 3. useless in all tags
        delete $ret{value};

        return wantarray ? %ret : \%ret;
    }
}

sub multiple {
    my $self = shift;
    if (@_) {
        $self->{multiple} = shift;       # manually set
        delete $self->{_cache}{type};    # clear auto-type
    }
    return 'multiple' if $self->{multiple};         # manually set
    my @v = $self->tag_value;
    return 'multiple' if @v > 1;
    return;
}

sub options {
    my $self = shift;
    if (@_) {
        $self->{options} = shift;        # manually set
        delete $self->{_cache}{type};    # clear auto-type
    }
    return unless $self->{options};

    # align options per internal settings
    my @opt = optalign($self->{options});

    # scalar is just counting length, so skip sort
    return @opt unless wantarray;

    # sort if requested
    @opt = optsort($self->sortopts, @opt) if $self->sortopts;

    return @opt;
}

# per-field messages
sub message {
    my $self = shift;
    $self->{message} = shift if @_;
    my $mess = $self->{message};
    unless ($mess) {
        my $type = shift || $self->type;
        my $et = 'form_invalid_' . ($type eq 'text' ? 'input' : $type);
        $et    = 'form_invalid_input' if $self->other;     # other fields assume text
        $mess  = sprintf(($self->{_form}{messages}->$et
                    || $self->{_form}{messages}->form_invalid_default), $self->label);
    }
    return $self->{_form}{stylesheet}
           ? qq(<span class="$self->{_form}{styleclass}_message">$mess</span>)
           : $mess;
}

sub jsmessage {
    my $self = shift;
    $self->{jsmessage} = shift if @_;
    my $mess = $self->{jsmessage} || $self->{message};
    unless ($mess) {
        my $type = shift || $self->type;
        my $et = 'js_invalid_' . ($type eq 'text' ? 'input' : $type);
        $et    = 'js_invalid_input' if $self->other;       # other fields assume text
        $mess  =  sprintf(($self->{_form}{messages}->$et
                          || $self->{_form}{messages}->js_invalid_default),
                             $self->label);
    }
    return $mess
}

sub comment {
    my $self = shift;
    $self->{comment} = shift if @_;
    my $mess = $self->{comment} || return '';
    return $self->{_form}{stylesheet}
           ? qq(<span class="$self->{_form}{styleclass}_comment">$mess</span>)
           : $mess;
}

# simple error wrapper (why wasn't this here?)
sub error {
    my $self = shift;
    return $self->invalid ? $self->message : '';
}

sub jstype {
    my $self = shift;
    my $type = shift || $self->type;
    return ($type eq 'radio' || $type eq 'checkbox') ? 'onclick' : 'onchange';
}

sub script {
    my $self = shift;
    #
    # An unfortunate hack. Sometimes (often?) we don't know the field
    # type until render(), in which Javascript is generated first. So,
    # the grandfather (this) of all script() methods just sets the type
    # by calling $self->type in a void context (which reblesses the object)
    # and then calling $self->script again. I think this sucks, but then
    # again this code shouldn't be called that often. Maybe.
    #
    $self->type;
    $self->script;
}

sub jsfield {
    my $self = shift;
    my $name = $self->name;
    my $pattern = $self->{validate};
    debug 2, "return '' unless ".$self->javascript." && ($pattern || ".$self->required.")";
    return '' unless $self->javascript && ($pattern || $self->required);

    # First arg is the script that our children should've included
    my($jsfunc, $close_brace, $in) = @_;
    unless ($jsfunc) {
        belch "Missing generated \$jsfunc string for $name->jsfield";
        return '';
    }

    debug 1, "$name: generating JavaScript validation code";

    # Special catch, since many would assume this would work
    if (ref $pattern eq 'Regexp') {
        puke "To use a regex in a 'validate' option you must specify ".
             "it in single quotes, like '/^\\w+\$/' - failed on '$name' field";
    }

    # hashref is a grouping per-language
    if (ref $pattern eq 'HASH') {
        $pattern = $pattern->{javascript} || return '';
    }

    # Check our hash to see if it's a special pattern
    $pattern = $VALIDATE{$pattern} if $VALIDATE{$pattern};

    # Make field name JS-safe
    my $jsfield = tovar($name);

    # Note we have to use form.elements['name'] instead of just form.name
    # as the JAPH using this module may have defined fields like "u.type"
    my $alertstr = escapejs($self->jsmessage);  # handle embedded '
    $alertstr .= '\n';

    # Our fields are only required if the required option is set
    # So, if not set, add a not-null check to the if below
    my $notnull = $self->required 
                     ? qq[$jsfield == null ||]                     # must have or error
                     : qq[$jsfield != null && $jsfield != "" &&];  # only care if filled in

    if ($pattern =~ m#^m?(\S)(.*)\1$#) {
        # JavaScript regexp
        ($pattern = $2) =~ s/\\\//\//g;
        $pattern =~ s/\//\\\//g;
        $jsfunc .= qq[${in}if ($notnull ! $jsfield.match(/$pattern/)) {\n];
    }
    elsif (ref $pattern eq 'ARRAY') {
        # Must be w/i this set of values
        # Can you figure out how this piece of Perl works? No, seriously, I forgot.
        $jsfunc .= qq[${in}if ($notnull ($jsfield != ']
                 . join("' && $jsfield != '", @{$pattern}) . "')) {\n";
    }
    elsif (ref $pattern eq 'CODE' || $pattern eq 'VALUE' || ($self->required && ! $pattern)) {
        # Not null (for required sub refs, just check for a value)
        $jsfunc .= qq[${in}if ($notnull $jsfield === "") {\n];
    }
    else {
        # Literal string is literal code to execute, but provide
        # a warning just in case
        belch "Validation string '$pattern' may be a typo of a builtin pattern"
            if $pattern =~ /^[A-Z]+$/;
        $jsfunc .= qq[${in}if ($notnull $jsfield $pattern) {\n];
    }

    # add on our alert message, but only if it's required
    $jsfunc .= <<EOJS;
$in    alertstr += '$alertstr';
$in    invalid++;
$in    invalid_fields.push('$jsfield');
$in}$close_brace
EOJS

    return $jsfunc;
}

*render = \&tag;
sub tag {
    my $self = shift;
    $self->type;
    return $self->tag(@_);
}

sub validate () {

    # This function does all the validation on the Perl side.
    # It doesn't generate JavaScript; see render() for that...

    my $self  = shift;
    my $form  = $self->{_form};   # alias for examples (paint-by-numbers)
    local $^W = 0;               # -w sucks

    my $pattern = shift || $self->{validate};
    my $field   = $self->name;

    # inflation subref?
    my $inflate = (exists $self->{inflate}) ? $self->{inflate} : undef;
    puke("$field: inflate attribute must be subroutine reference")
        if defined $inflate && ref $inflate ne 'CODE';
    puke("$field: inflate requires a validation pattern")
        if defined $inflate && !defined $pattern;
    $self->{inflated_values} = [ ] if $inflate;

    debug 1, "$self->{name}: called \$field->validate(@_) for field '$field'";

    # Check our hash to see if it's a special pattern
    ($pattern) = autodata($VALIDATE{$pattern}) if $VALIDATE{$pattern};

    # Hashref is a grouping per-language
    if (ref $pattern eq 'HASH') {
        $pattern = $pattern->{perl} || return 1;
    }

    # Counter for fail or success
    my $bad = 0;

    # Loop thru, and if something isn't valid, we tag it
    my $atleastone = 0;
    $self->{invalid} ||= 0;
    for my $value ($self->value) {
        my $thisfail = 0;

        # only continue if field is required or filled in
        if ($self->required) {
            debug 1, "$field: is required per 'required' param";
        } else {
            debug 1, "$field: is optional per 'required' param";
            next unless length($value) && defined($pattern);
            debug 1, "$field: ...but is defined, so still checking";
        }

        $atleastone++;
        debug 1, "$field: validating ($value) against pattern '$pattern'";

        if ($pattern =~ m#^m(\S)(.*)\1$# || $pattern =~ m#^(/)(.*)\1$#) {
            # it be a regexp, handle / escaping
            (my $tpat = $2) =~ s#\\/#/#g;
            $tpat =~ s#/#\\/#g;
            debug 2, "$field: does '$value' =~ /$tpat/ ?";
            unless ($value =~ /$tpat/) {
                $thisfail = ++$bad;
            }
        } elsif (ref $pattern eq 'ARRAY') {
            # must be w/i this set of values
            debug 2, "$field: is '$value' in (@{$pattern}) ?";
            unless (ismember($value, @{$pattern})) {
                $thisfail = ++$bad;
            }
        } elsif (ref $pattern eq 'CODE') {
            # eval that mofo, which gives them $form
            my $extra = $form->{c} || $form;
            debug 2, "$field: does $pattern($value, $extra) ret true ?";
            unless (&{$pattern}($value, $extra)) {
                $thisfail = ++$bad;
            }
        } elsif ($pattern eq 'VALUE') {
            # Not null
            debug 2, "$field: length '$value' > 0 ?";
            unless (defined($value) && length($value)) {
                $thisfail = ++$bad;
            }
        } elsif (! defined $pattern) {
            debug 2, "$field: length('$value') > 0";
            $thisfail = ++$bad unless length($value) > 0;
        } else {
            # literal string is a literal comparison, but warn of typos...
            belch "Validation string '$pattern' may be a typo of a builtin pattern"
                if ($pattern =~ /^[A-Z]+$/); 
            # must reference to prevent serious problem if $value = "'; system 'rm -f /'; '"
            debug 2, "$field: '$value' $pattern ? 1 : 0";
            unless (eval qq(\$value $pattern ? 1 : 0)) {
                $thisfail = ++$bad;
            }
            belch "Literal code eval error in validate: $@" if $@;
        }

        # Just for debugging's sake
        $thisfail ? debug 2, "$field: pattern FAILED"
                  : debug 2, "$field: pattern passed";
        
        # run inflation subref if defined, trap errors and warn
        if (defined $inflate) {
            debug 1, "trying to inflate value '$value'";
            my $inflated_value = eval { $inflate->($value) };
            if ($@) {
                belch "Field $field: inflate failed on value '$value' due to '$@'";
                $thisfail = ++$bad;
            }
            # cache for value():
            push @{$self->{inflated_values}}, $inflated_value;

            # debugging:
            $thisfail ? debug 2, "$field: inflate FAILED"
                      : debug 2, "$field: inflate passed";
        }
    }

    # If not $atleastone and they asked for validation, then we
    # know that we have an error since this means no values
    if ($bad || (! $atleastone && $self->required)) {
        debug 1, "$field: validation FAILED";
        $self->{invalid} = $bad || 1;
        $self->{missing} = $atleastone;  
        return;
    } else {
        debug 1, "$field: validation passed";
        delete $self->{invalid};    # in case of previous run
        delete $self->{missing};    # ditto
        return 1;
    }
}

sub static () {
    my $self = shift;
    $self->{static} = shift if @_;
    return $self->{static} if exists $self->{static};
    # check parent for this as well
    return $self->{_form}{static};
}

sub disabled () {
    my $self = shift;
    $self->{disabled} = shift if @_;
    return ($self->{disabled} ? 'disabled' : undef)
        if exists $self->{disabled};
    # check parent for this as well
    return $self->{_form}->disabled;
}

sub javascript () {
    my $self = shift;
    $self->{javascript} = shift if @_;
    return $self->{javascript} if exists $self->{javascript};
    # check parent for this as well
    return $self->{_form}{javascript};
}

sub growable () {
    my $self = shift;
    $self->{growable} = shift if @_;
    return unless $self->{growable};
    # check to make sure we're only a text or file type
    unless ($self->type eq 'text' || $self->type eq 'file') {
        belch "The 'growable' option only works with 'text' or 'file' fields";
        return;
    }
    return $self->{growable};
}

sub name () {
    my $self = shift;
    $self->{name} = shift if @_;
    confess "[".__PACKAGE__."::name] Fatal: Attempt to manipulate unnamed field"
        unless exists $self->{name};
    return $self->{name};
}

sub DESTROY { 1 }

sub AUTOLOAD {
    # This allows direct addressing by name, for quicker usage
    my $self = shift;
    my($name) = $AUTOLOAD =~ /.*::(.+)/;

    debug 3, "-> dispatch to \$field->{$name} = @_";
    croak "self not ref in AUTOLOAD" unless ref $self; # nta

    $self->{$name} = shift if @_;
    return $self->{$name};
}

1;
__END__

=head1 DESCRIPTION

This module is internally used by B<FormBuilder> to create and maintain
field information. Usually, you will not want to directly access this
set of data structures. However, one big exception is if you are going
to micro-control form rendering. In this case, you will need to access
the field objects directly.

To do so, you will want to loop through the fields in order:

    for my $field ($form->field) {

        # $field holds an object stringified to a field name
        if ($field =~ /_date$/) {
            $field->sticky(0);  # clear CGI value
            print "Enter $field here:", $field->tag;
        } else {
            print $field->label, ': ', $field->tag;
        }
    }

As illustrated, each C<$field> variable actually holds a stringifiable
object. This means if you print them out, you will get the field name,
allowing you to check for certain fields. However, since it is an object,
you can then run accessor methods directly on that object.

The most useful method is C<tag()>. It generates the HTML input tag
for the field, including all option and type handling, and returns a 
string which you can then print out or manipulate appropriately.

Second to this method is the C<script> method, which returns the appropriate
JavaScript validation routine for that field. This is useful at the top of
your form rendering, when you are printing out the leading C<< <head> >> section
of your HTML document. It is called by the C<$form> method of the same name.

The following methods are provided for each C<$field> object.

=head1 METHODS

=head2 new($form, %args)

This creates a new C<$field> object. The first argument must be a reference
to the top-level C<$form> object, for callbacks. The remaining arguments
should be hash, of which one C<key/value> pair must specify the C<name> of
the field. Normally you should not touch this method. Ever.

=head2 field(%args)

This is a delegated field call. This is how B<FormBuilder> tweaks its fields.
Once you have a C<$field> object, you call this method the exact same way
that you would call the main C<field()> method, minus the field name. Again
you should use the top-level call instead.

=head2 inflate($subref)

This sets the inflate attribute: subroutine reference used to inflate values 
returned by value() into objects or whatever you want.  If no parameter, 
returns the inflate subroutine reference that is set.  For example:
    
 use DateTime::Format::Strptime;
 my $date_format = DateTime::Format::Strptime->new(
    pattern   => '%D',    # for MM/DD/YYYY american dates
    locale    => 'en_US',
    time_zone => 'America/Los_Angeles',
 );
 $field->inflate( sub { return $date_format->format_datetime(shift) } );

=head2 invalid

This returns the opposite value that C<validate()> would return, with
some extra magic that keeps state for form rendering purposes.

=head2 jsfunc()

Returns the appropriate JavaScript validation code (see above).

=head2 label($str)

This sets and returns the field's label. If unset, it will be generated
from the name of the field.

=head2 tag($type)

Returns an XHTML form input tag (see above). By default it renders the
tag based on the type set from the top-level field method:

    $form->field(name => 'poetry', type => 'textarea');

However, if you are doing custom rendering you can override this temporarily
by passing in the type explicitly. This is usually not useful unless you
have a custom rendering module that forcibly overrides types for certain
fields.

=head2 type($type)

This sets and returns the field's type. If unset, it will automatically 
generate the appropriate field type, depending on the number of options and
whether multiple values are allowed:

    Field options?
        No = text (done)
        Yes:
            Less than 'selectnum' setting?
                No = select (done)
                Yes:
                    Is the 'multiple' option set?
                    Yes = checkbox (done)
                    No:
                        Have just one single option?
                            Yes = checkbox (done)
                            No = radio (done)

For an example, view the inside guts of this module.

=head2 validate($pattern)

This returns 1 if the field passes the validation pattern(s) and C<required>
status previously set via required() and (possibly) the top-level new()
call in FormBuilder. Usually running per-field validate() calls is not
what you want. Instead, you want to run the one on C<$form>, which in
turn calls each individual field's and saves some temp state.

=head2 value($val)

This sets the field's value. It also returns the appropriate value: CGI if
set, otherwise the manual default value. Same as using C<field()> to
retrieve values.

=head2 tag_value()

This obeys the C<sticky> flag to give a different interpretation of CGI
values. B<Use this to get the value if generating your own tag.> Otherwise,
ignore it completely.

=head2 cgi_value()

This always returns the CGI value, regardless of C<sticky>.

=head2 def_value()

This always returns the default value, regardless of C<sticky>.

=head2 tag_name()

This returns the tag name of the current item. This was added so you could
subclass, say, C<CGI::FormBuilder::Field::select> and change the HTML tag
to C<< <b:select> >> instead. This is an experimental feature and subject
to change wildly (suggestions welcome).

=head2 accessors

In addition to the above methods, accessors are provided for directly 
manipulating values as if from a C<field()> call:

    Accessor                Same as...                        
    ----------------------- -----------------------------------
    $f->force(0|1)          $form->field(force => 0|1)
    $f->options(\@opt)      $form->field(options => \@opt)
    $f->multiple(0|1)       $form->field(multiple => 0|1)
    $f->message($mesg)      $form->field(message => $mesg)
    $f->jsmessage($mesg)    $form->field(jsmessage => $mesg)
    $f->jsclick($code)      $form->field(jsclick => $code)
    $f->sticky(0|1)         $form->field(sticky => 0|1);
    $f->force(0|1)          $form->field(force => 0|1);
    $f->growable(0|1)       $form->field(growable => 0|1);
    $f->other(0|1)          $form->field(other => 0|1);

=head1 SEE ALSO

L<CGI::FormBuilder>

=head1 REVISION

$Id: Field.pm 100 2007-03-02 18:13:13Z nwiger $

=head1 AUTHOR

Copyright (c) L<Nate Wiger|http://nateware.com>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut
