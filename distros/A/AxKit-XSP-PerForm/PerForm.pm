# $Id: PerForm.pm,v 1.24 2003/08/10 16:43:56 matt Exp $

package AxKit::XSP::PerForm;

$VERSION = "1.83";

use AxKit 1.4;
use Apache;
use Apache::AxKit::Language::XSP::TaglibHelper;
use AxKit::XSP::WebUtils 1.5;

$NS = 'http://axkit.org/NS/xsp/perform/v1';

@ISA = qw(Apache::AxKit::Language::XSP);

@EXPORT_TAGLIB = (
    'textfield($name;$default,$width,$maxlength,$index,$onvalidate,$onload,$disabled,$onchange)',
    'password($name;$default,$width,$maxlength,$index,$onvalidate,$onload,$disabled,$onchange)',
    'submit($name;$value,$image,$alt,$border,$align,$goto,$index,$onsubmit,$disabled,$onclick)',
    'cancel($name;$value,$image,$alt,$border,$align,$goto,$index,$oncancel,$disabled,$onclick)',
    'checkbox($name;$value,$checked,$label,$index,$onvalidate,$onload,$disabled,$onclick)',
    'file_upload($name;$value,$accept,$onvalidate,$onload,$disabled,$onclick)',
    'hidden($name;$value,$index,$onload)',
    'textarea($name;$cols,$rows,$wrap,$default,$index,$onvalidate,$onload,$disabled,$onchange)',
    'single_select($name;$default,$index,$onvalidate,$onload,$disabled,$onchange,*options):itemtag=option',
    'multi_select($name;@default,$index,$onvalidate,$onload,$disabled,$onclick,*option):itemtag=option',
);

use strict;

sub parse_char  { 
    Apache::AxKit::Language::XSP::TaglibHelper::parse_char(@_);
}

sub parse_start {
    my ($e, $tag, %attribs) = @_;
    
    if ($tag eq 'form') {
        $e->manage_text(0);
        
        my $form_el = {
            Name => "form",
            NamespaceURI => "",
            Attributes => [
                { Name => "name", Value => $attribs{name} },
                { Name => "method", Value => "POST" },
                { Name => "enctype", Value => "multipart/form-data" },
            ],
        };
#MSS
#        if (Apache->args) {
#	    $form_el->{Attributes}[1]{Value} .='?'.Apache->args;
#        }
#end MSS
        
        $e->start_element($form_el);
        
        my $submitting = {
            Name => "hidden",
            NamespaceURI => "",
            Attributes => [
                { Name => "name", Value => "__submitting_$attribs{name}" },
                { Name => "value", Value => "1" },
            ],
        };
        $e->start_element($submitting);
        $e->end_element($submitting);
        
        return <<EOT
{        
use vars qw(\$_form_ctxt \@_submit_buttons \%_submit_goto \%_submit_index \@_cancel_buttons \%_cancel_goto \%_cancel_index );
local \$_form_ctxt = { Form => \$cgi->parms, Apache => \$r, Name => '$attribs{name}' };
local \@_submit_buttons;
local \@_cancel_buttons;
local \%_submit_goto;
local \%_cancel_goto;
local \%_submit_index;
local \%_cancel_index;
start_form_$attribs{name}(\$_form_ctxt, \$cgi->param('__submitting_$attribs{name}'))
          if defined \&start_form_$attribs{name};
EOT
    }
    else {
        return Apache::AxKit::Language::XSP::TaglibHelper::parse_start(@_);
    }
}

sub end_element {
    my ($e, $element) = @_;
    
    if ($element->{Name} eq 'form') {
        my $form_el = {
            Name => "form",
            NamespaceURI => "",
            Attributes => [],
        };
        
        my $name;
        my $onsubmit;
        my $oncancel;
        my $onformend;
        
        for my $attr (@{$element->{Attributes}}) {
            if ($attr->{Name} eq 'name') {
                $name = $attr->{Value};
            }
            elsif ($attr->{Name} eq 'onformend') {
                $onformend = $attr->{Value};
            }
            elsif ($attr->{Name} eq 'onsubmit') {
                $onsubmit = $attr->{Value};
            }
            elsif ($attr->{Name} eq 'oncancel') {
                $oncancel = $attr->{Value};
            }
        }
        
        $e->end_element($form_el);
        return <<EOT;
my \$package = __PACKAGE__;
if (my \$sub = \$package->can('$onformend' || 'end_form_$name')) {
    \$sub->(\$_form_ctxt, \$cgi->param('__submitting_$name'));
}

# warn("submitting? ".(\$cgi->param('__submitting_$name')?"yes":"no").", failed? ".(\$_form_ctxt->{_Failed}?"yes":"no"));

if (\$cgi->param('__submitting_$name')) {
    foreach my \$cancel (\@_cancel_buttons) {
        if (\$cgi->param(\$cancel)) {
            no strict 'refs';
            my \$redirect;
            \$redirect = \$_cancel_goto{\$cancel};
            if (my \$sub = \$package->can(\$_cancel_index{\$cancel}{oncancel} || '$oncancel' || "cancel_\$_cancel_index{\$cancel}{name}")) {
                \$redirect = \$sub->(\$_form_ctxt, \$_cancel_index{\$cancel}{'index'});
            }
            if (\$redirect) {
                return AxKit::XSP::WebUtils::redirect(\$redirect,undef,undef,1);
            }
        }
    }
}

if (\$cgi->param('__submitting_$name') && !\$_form_ctxt->{_Failed}) {
     foreach my \$submit (\@_submit_buttons) {
        if (\$cgi->param(\$submit)) {
            no strict 'refs';
            my \$redirect;
            \$redirect = \$_submit_goto{\$submit};
            if (my \$sub = \$package->can(\$_submit_index{\$submit}{onsubmit} || '$onsubmit' || "submit_\$_submit_index{\$submit}{name}")) {
                \$redirect = \$sub->(\$_form_ctxt, \$_submit_index{\$submit}{'index'});
            }
            if (\$redirect) {
                return AxKit::XSP::WebUtils::redirect(\$redirect,undef,undef,1);
            }
        }
    }
}

# catch the case where IE submitted the form without any buttons used
if (\$cgi->param('__submitting_$name') && !\$_form_ctxt->{_Failed}) {
    no strict 'refs';
    my \$redirect;
    if (my \$sub = \$package->can('$onsubmit')) {
        \$redirect = \$sub->(\$_form_ctxt);
    }
    if (\$redirect) {
        return AxKit::XSP::WebUtils::redirect(\$redirect, undef, undef, 1);
    }
}

}
EOT
    }
    else {
        return Apache::AxKit::Language::XSP::TaglibHelper::parse_end($e, $element->{Name});
    }
}

sub textfield ($;$$$$$$$$) {
    my ($name, $default, $width, $maxlength, $index, $onval, $onload,
        $disabled, $onchange) = @_;
    my ($package) = caller;
    
    no strict 'refs';
    
    my $ctxt = ${"${package}::_form_ctxt"};
    
    my $params = $ctxt->{Form};
    my $fname = $ctxt->{Name};
    
    my $error;
    
    # validate
    if ($params->{"__submitting_$fname"}) {
        # warn("Checking if $package can " . ($onval || "validate_${name}") . "\n");
        if (my $sub = $package->can($onval || "validate_${name}")) {
            eval {
                $sub->($ctxt, ($params->get($name.$index))[-1], $index);
                $params->{$name.$index} = ($params->get($name.$index))[-1];
            };
            $error = $@;
            $ctxt->{_Failed}++ if $error;
            $error =~ s/(.*) at .*? line \d+\.$/$1/;
        }
    }
    # load
    elsif (my $sub = $package->can($onload || "load_${name}")) {
        $params->{$name.$index} = $sub->($ctxt, $default, ($params->get($name.$index))[-1], $index);
    }
    else{ 
        $params->{$name.$index} = $default;
    }
    
    return {
        textfield => { 
            width => $width,
            maxlength => $maxlength,
            name => $name,
            value => ($params->get($name.$index))[-1],
	    index => $index,
            ($disabled ? (disabled => $disabled) : ()),
            ($onchange ? (onchange => $onchange) : ()),
            ($error ? (error => $error) : ()),
            }
        };
}

sub submit ($;$$$$$$$$$$) {
    my ($name, $value, $image, $alt, $border, $align, $goto, $index,
        $onsubmit, $disabled, $onclick) = @_;
    my ($package) = caller;
    
    no strict 'refs';
    
    my $ctxt = ${"${package}::_form_ctxt"};
    my $params = $ctxt->{Form};
    
    push @{"${package}::_submit_buttons"}, "$name$index";
    ${"${package}::_submit_goto"}{$name.$index} = $goto if $goto;
    ${"${package}::_submit_index"}{$name.$index}{'index'} = $index;
    ${"${package}::_submit_index"}{$name.$index}{'name'} = $name;
    ${"${package}::_submit_index"}{$name.$index}{'onsubmit'} = $onsubmit;
    
    # save
    if ($image) {
        return {
            image_button => {
                name => $name,
                value => $value,
                src => $image,
                alt => $alt,
                border => $border || 0,
                align => $align || "bottom",
                ($disabled ? (disabled => $disabled) : ()),
                ($onclick ? (onclick => $onclick) : ()),
		index => $index,
            }
        };
    }
    else {
        return {
            submit_button => {
                name => $name,
                value => $value,
		index => $index,
                ($disabled ? (disabled => $disabled) : ()),
                ($onclick ? (onclick => $onclick) : ()),
            }
        };
    }
}

sub cancel ($;$$$$$$$$$$) {
    my ($name, $value, $image, $alt, $border, $align, $goto, $index,
        $oncancel, $disabled, $onclick) = @_;
    my ($package) = caller;
    
    no strict 'refs';
    
    my $ctxt = ${"${package}::_form_ctxt"};
    my $params = $ctxt->{Form};
    
    push @{"${package}::_cancel_buttons"}, $name.$index;
    ${"${package}::_cancel_goto"}{$name.$index} = $goto if $goto;
    ${"${package}::_cancel_index"}{$name.$index}{'index'} = $index;
    ${"${package}::_cancel_index"}{$name.$index}{'name'} = $name;
    ${"${package}::_cancel_index"}{$name.$index}{'oncancel'} = $oncancel;
    
    # save
    if ($image) {
        return {
            image_button => {
                name => $name,
                value => $value,
                src => $image,
                alt => $alt,
                border => $border || 0,
                align => $align || "bottom",
		index => $index,
                ($disabled ? (disabled => $disabled) : ()),
                ($onclick ? (onclick => $onclick) : ()),
            }
        };
    }
    else {
        return {
            submit_button => {
                name => $name,
                value => $value,
		index => $index,
                ($disabled ? (disabled => $disabled) : ()),
                ($onclick ? (onclick => $onclick) : ()),
            }
        };
    }
}

sub button ($;$$) {
    my ($name, $value, $index) = @_;
    
    my ($package) = caller;
    
    no strict 'refs';
    
    my $ctxt = ${"${package}::_form_ctxt"};
    my $params = $ctxt->{Form};
    
    # TODO: What do we want buttons to do?
}

sub checkbox ($;$$$$$$$$) {
    my ($name, $value, $checked, $label, $index, $onval, $onload,
        $disabled, $onclick) = @_;

    my ($package) = caller;
    $value = 1 unless $value;
    
    no strict 'refs';
    
    my $ctxt = ${"${package}::_form_ctxt"};
    
    my $params = $ctxt->{Form};
    my $fname = $ctxt->{Name};
    
    my $error;
    
    # validate
    if ($params->{"__submitting_$fname"}) {
        if (my $sub = $package->can($onval || "validate_${name}")) {
            eval {
                $sub->($ctxt, ($params->get($name.$index))[-1], $index);
                $params->{$name.$index} = ($params->get($name.$index))[-1];
            };
            $error = $@;
            $ctxt->{_Failed}++ if $error;
            $error =~ s/(.*) at .*? line \d+\.$/$1/;
        }
    }
    # load
    elsif (my $sub = $package->can($onload || "load_${name}")) {
        my @vals = $sub->($ctxt, $value, ($params->get($name.$index))[-1], $index);
        $checked = shift @vals;
        $value = shift @vals if @vals;
    }
    else {
        $checked = 1 if defined(($params->get($name.$index))[-1]);
    }
    
    if ($checked && $checked eq 'yes') {
        $checked = 1;
    }
    elsif ($checked && $checked eq 'no') {
        $checked = 0;
    }
    
    return {
        checkbox => {
            name => $name,
            value => $value,
            ( $checked ? (checked => "checked") : () ),
            label => $label,
            ( $error ? (error => $error) : () ),
	    index => $index,
            ($disabled ? (disabled => $disabled) : ()),
            ($onclick ? (onclick => $onclick) : ()),
        }
    };
}

sub file_upload ($;$$$$$$) {
    my ($name, $value, $accept, $onval, $onload, $disabled, $onclick) = @_;
    my ($package) = caller;
    
    no strict 'refs';
    
    my $ctxt = ${"${package}::_form_ctxt"};
    
    my $params = $ctxt->{Form};
    my $fname = $ctxt->{Name};
    
    my $error;
    
    # validate
    if ($params->{"__submitting_$fname"}) {
        if (my $sub = $package->can($onval || "validate_${name}")) {
            my $upload = Apache::Request->instance(Apache->request)->upload($name);
            
            my $filename;
            if ($upload) {
                $filename = $upload->filename;
                $filename =~ s/.*[\\\/]//; # strip to just a filename
                $filename =~ s/[^\w\.-]//g; # strip non-word chars
            }
    
            eval {
               $sub->($ctxt, 
                       ($upload ? 
                            (   $filename,
                                $upload->fh, 
                                $upload->size, 
                                $upload->type, 
                                $upload->info
                            ) : 
                            ()
                       )
                   );
            };
            $error = $@;
            $ctxt->{_Failed}++ if $error;
            $error =~ s/(.*) at .*? line \d+\.$/$1/;
        }
    }
    # load
    elsif (my $sub = $package->can($onload || "load_${name}")) {
        $params->{$name} = $sub->($ctxt, $value, $params->{$name});
    }
    else {
        $params->{$name} = $value;
    }
    
    return {
        file_upload => {
            name => $name,
            value => $params->{$name},
            accept => $accept,
            ($disabled ? (disabled => $disabled) : ()),
            ($onclick ? (onclick => $onclick) : ()),
            ($error ? (error => $error) : ()),
        }
    };
}

sub hidden ($;$$$) {
    my ($name, $value, $index, $onload) = @_;
    my ($package) = caller;
    
    no strict 'refs';
    
    my $ctxt = ${"${package}::_form_ctxt"};
    my $params = $ctxt->{Form};
    my $fname = $ctxt->{Name};

    if (!defined($value) && $package->can($onload || "load_${name}")) {
	# load value if not defined
        my $sub = $package->can($onload || "load_${name}");
	$value = $sub->($ctxt, $value, $index);
    }
    if ($params->{"__submitting_$fname"} && ($value ne ($params->get($name.$index))[-1])) {
	die "Someone tried to change your hidden form value!";
    }

    return {
	hidden => {
            name => $name,
            value => $value,
	    index => $index,
        }
    };
}

sub multi_select ($;$$$$$$$) {
    my ($name, $default, $index, $onval, $onload, $disabled, $onclick, $option) = @_;
    my ($package) = caller;
    
    no strict 'refs';
    
    my $ctxt = ${"${package}::_form_ctxt"};
    
    my $params = $ctxt->{Form};
    my $fname = $ctxt->{Name};
    
    my $error;
    my ($selected, @options);
    
    # validate
    if ($params->{"__submitting_$fname"}) {
        if (my $sub = $package->can($onval || "validate_${name}")) {
            eval {
                $sub->($ctxt, [$params->get($name.$index)], $index);
            };
            $error = $@;
            $ctxt->{_Failed}++ if $error;
            $error =~ s/(.*) at .*? line \d+\.$/$1/;
        }
    }
    # load
    if (my $sub = $package->can($onload || "load_${name}")) {
        ($selected, @options) = $sub->($ctxt, [$params->get($name.$index)], $default, $index);
    }
    else {
        $selected = [@{$default}];
        @options = map { $$_{name}, $$_{value} } @{$option};
    }
    
    my %selected = map { $_ => 1 } @$selected;
    
    my (@keys, @vals);
    while (@options) {
        my ($val, $key) = splice(@options, 0, 2);
        push @keys, $key;
        push @vals, $val;
    }
    
    return {
        multi_select => {
            name => $name,
            ($error ? ( error => $error ) : ()),
	    index => $index,
            ($disabled ? (disabled => $disabled) : ()),
            ($onclick ? (onclick => $onclick) : ()),
            options => [
                map {
                  { 
                    ( ( $selected{$_} ) ? (selected => "selected") : () ),
                    value => $_,
                    text => shift(@vals),
                  }
                } @keys,
            ],
        }
    };
}

sub password ($;$$$$$$$$) {
    my ($name, $default, $width, $maxlength, $index, $onval, $onload,
        $disabled, $onchange) = @_;
    my ($package) = caller;
    
    no strict 'refs';
    
    my $ctxt = ${"${package}::_form_ctxt"};
    
    my $params = $ctxt->{Form};
    my $fname = $ctxt->{Name};
    
    my $error;
    
    # validate
    if ($params->{"__submitting_$fname"}) {
        if (my $sub = $package->can($onval || "validate_${name}")) {
            eval {
                $sub->($ctxt, ($params->get($name.$index))[-1], $index);
                $params->{$name.$index} = ($params->get($name.$index))[-1];
            };
            $error = $@;
            $ctxt->{_Failed}++ if $error;
            $error =~ s/(.*) at .*? line \d+\.$/$1/;
        }
    }
    # load
    elsif (my $sub = $package->can($onload || "load_${name}")) {
        $params->{$name.$index} = $sub->($ctxt, $default, ($params->get($name.$index))[-1], $index);
    }
    else {
        $params->{$name.$index} = $default;
    }
    
    return {
        password => { 
            width => $width,
            maxlength => $maxlength,
            name => $name,
            value => ($params->get($name.$index))[-1],
            ($error ? (error => $error) : ()),
	    index => $index,
            ($disabled ? (disabled => $disabled) : ()),
            ($onchange ? (onchange => $onchange) : ()),
            }
        };
}

sub radio {
    die "NOT YET IMPLEMENTED";
}

sub reset ($;$) {
    my ($name, $value) = @_;
    
    return {
        reset => {
            name => $name,
            ( $value ? (value => $value) : () ),
        }
    };
}

sub single_select ($;$$$$$$$) {
    my ($name, $default, $index, $onval, $onload,
        $disabled, $onchange, $option) = @_;

    my ($package) = caller;
    
    no strict 'refs';
    
    my $ctxt = ${"${package}::_form_ctxt"};
    
    my $params = $ctxt->{Form};
    my $fname = $ctxt->{Name};
    
    my $error;
    my ($selected, @options);
    
    # validate
    if ($params->{"__submitting_$fname"}) {
        if (my $sub = $package->can($onval || "validate_${name}")) {
            eval {
                $sub->($ctxt, ($params->get($name.$index))[-1], $index);
                $params->{$name.$index} = ($params->get($name.$index))[-1];
            };
            $error = $@;
            $ctxt->{_Failed}++ if $error;
            $error =~ s/(.*) at .*? line \d+\.$/$1/;
        }
    }
    # load
    if (my $sub = $package->can($onload || "load_${name}")) {
        ($selected, @options) = $sub->($ctxt, ($params->get($name.$index))[-1], $default, $index);
    }
    else {
        $selected = $default;
        @options = map { $$_{name}, $$_{value} } @{$option};
    }
    
    my (@keys, @vals);
    while (@options) {
        my ($val, $key) = splice(@options, 0, 2);
        push @keys, $key;
        push @vals, $val;
    }
    
    return {
        single_select => {
            name => $name,
            ($error ? ( error => $error ) : ()),
	    index => $index,
            ($disabled ? (disabled => $disabled) : ()),
            ($onchange ? (onchange => $onchange) : ()),
            options => [
                map {
                  { 
                    ( ($selected eq $_) ? (selected => "selected") : () ),
                    value => $_,
                    text => shift(@vals),
                  }
                } @keys,
            ],
        }
    };
}

sub textarea ($;$$$$$$$$$) {
    my ($name, $cols, $rows, $wrap, $default, $index, $onval, $onload,
        $disabled, $onchange) = @_;
    
    my ($package) = caller;
    
    no strict 'refs';
    
    my $ctxt = ${"${package}::_form_ctxt"};
    
    my $params = $ctxt->{Form};
    my $fname = $ctxt->{Name};
    
    my $error;
    
    # validate
    if ($params->{"__submitting_$fname"}) {
        if (my $sub = $package->can($onval || "validate_${name}")) {
            eval {
                $sub->($ctxt, ($params->get($name.$index))[-1], $index);
                $params->{$name.$index} = ($params->get($name.$index))[-1];
            };
            $error = $@;
            $ctxt->{_Failed}++ if $error;
            $error =~ s/(.*) at .*? line \d+\.$/$1/;
        }
    }
    # load
    elsif (my $sub = $package->can($onload || "load_${name}")) {
        $params->{$name.$index} = $sub->($ctxt, $default, ($params->get($name.$index))[-1], $index);
    }
    else {
        $params->{$name.$index} = $default;
    }
    
    if ($wrap) {
        if ($wrap eq 'no') {
            undef $wrap;
        }
        if ($wrap ne 'yes' && $wrap ne 'y') {
            undef $wrap;
        }
    }
    
    return {
        textarea => { 
            cols => $cols,
            rows => $rows,
            ($wrap ? (wrap => 'wrap') : ()),
            name => $name,
            value => $params->{$name.$index},
            ($error ? (error => $error) : ()),
	    index => $index,
            ($disabled ? (disabled => $disabled) : ()),
            ($onchange ? (onchange => $onchange) : ()),
            }
        };
}

1;
__END__

=head1 NAME

AxKit::XSP::PerForm - XSP Taglib for making complex forms easy

=head1 SYNOPSIS

  AxAddXSPTaglib AxKit::XSP::PerForm

=head1 DESCRIPTION

PerForm is a large and complex taglib for AxKit XSP that facilitates
creating large and complex HTML, WML, or other types of data-entry forms.
PerForm tends to make life easier for you if your form data is coming from
different data sources, such as DBI, or even XML.

PerForm works as an XSP taglib, meaning you simply add some custom XML tags
to your XSP page, and PerForm does the rest. Well, almost... PerForm works
mainly by callbacks, as you will see below.

=head1 EXAMPLE FORM

Ignoring the outside XSP and namespace declarations, assuming the prefix "f"
is bound to the PerForm namespace:

  <f:form name="add_user">
   First name: <f:textfield name="firstname" width="30" maxlength="50"/>
   <br />
   Last name: <f:textfield name="lastname" width="30" maxlength="50"/>
   <br />
   <f:submit name="save" value="Save" goto="users.xsp" />
   <f:cancel name="cancel" value="Cancel" goto="home.html" />
  </f:form>

Now it is important to bear in mind that this is just the form, and alone it
is fairly useless. You also need to add callbacks. You'll notice with each
of these callbacks you recieve a C<$ctxt> object. This is simply an empty
hash-ref that you can use in the callbacks to maintain state. Actually
"empty" is an exhageration - it contains two entries always: C<Form> and
C<Apache>. "Form" is a simply a hashref of the entries in the form (actually
it is an Apache::Table object, which allows for supporting multi-valued
parameters). So for example, the firstname below is in
C<$ctxt->{Form}{firstname}>. "Apache" is the C<$r> apache request object for
the current request, which is useful for access to the URI or headers.

  sub validate_firstname {
      my ($ctxt, $value) = @_;
      $value =~ s/^\s*//;
      $value =~ s/\s*$//;
      die "No value" unless $value;
      die "Invalid firstname - non word character not allowed"
                if $value =~ /\W/;
  }
  
  sub validate_lastname {
      return validate_firstname(@_);
  }
  
  sub submit_save {
      my ($ctxt) = @_;
      # save values to a database
      warn("User: ", $ctxt->{Form}{firstname}, " ", $ctxt->{Form}{lastname}, "\n");
  }

Now these methods need to be global to your XSP page, rather than "closures"
within the XSP page's main handler routine. How do you do that? Well it's
simple. Just put them within a <xsp:logic> section before any user defined
tags. For example, if your XSP page happens to use XHTML as it's basic
format (something I do a lot), your page might be constructed as follows
(namespace declarations omitted for brevity):

  <xsp:page>
    <xsp:logic>
    ... form logic here ...
    </xsp:logic>
    
    <html>
    <head><title>An Example Form</title></head>
    <body>
     <h1>An Example Form</h1>
     <f:form>
      ... form definition here ...
     </f:form>
    </body>
    </html>
  </xsp:page>

[Note that the page-global methods is a useful technique in other
situations, because unlike Apache::Registry scripts, this won't create a
closure from methods defined there].

=head1 SUBMISSION PROCEDURE

In PerForm, all forms submit back to themselves. This allows us to implement
the callback system. Of course with most forms, you want to go somewhere
else once you've processed the form. So for this, we issue redirects once
the form has been processed. This has the advantage that you can't hit
reload by accident and have the form re-submitted.

To define where you go on hitting submit, you can either return set the
I<goto> attribute on the submit or cancel button, or implement a callback
and return a URI to redirect to.

=head1 THE CONTEXT OBJECT

Each of the form callbacks is passed a context object. This is a hashref you
are allowed to use to maintain state between your callbacks. There is a new
context object created for every form on your XSP page. There are two
entries filled in automatically into the hashref for you:

=over 4

=item Form

This is actually an Apache::Table object, so it looks and works just like an
ordinary hashref, and contains the values submitted from the form, or is
perhaps empty if the form hasn't been submitted yet. It may also contain any
parameters passed in the querystring. For multi-value parameters, they can
be accessed via Apache::Table's get, add and set methods. See
L<Apache::Table>.

=item Apache

The Apache entry is the apache request object for the current request. You
can use this, for example, to get the current URI, or to get something out
of dir_config, or perhaps to send a header. See L<Apache>.

=back

To add an entry to the context object, simply use it as a hashref:

  $ctxt->{my_key} = $my_value;

And you can later get at that in another callback via C<$ctxt->{my_key}>.

=head1 ARRAYED FORM ELEMENTS

Sometimes you need to display a list of items in your form where the number
of items is not known until runtime.  Use arrayed form elements to trigger
the same callback for each item in the list.  When setting up each element,
use an index to identify each member of the list.  The callbacks will be
passed the index as a parameter.  e.g.

Your form may have a section like this:

  <xsp:logic>
  for $index (0..$#shoppinglist) {
    <p>
        <xsp:expr>$shoppinglist[$index]</xsp:expr>
        <f:submit name="SubmitBuy" value="Buy me">
            <f:index><xsp:expr>$index</xsp:expr></f:index>
        </f:submit>
    </p>
  }
  </xsp:logic>

The submit callback might be:

  sub submit_SubmitBuy {
    my ($ctxt, $index) = @_;
    return "purchase.xsp?item=$index";
  }

This example produces a list of items with a 'Buy me' button next to each
one.  Each button has an index that corresponds an array index of an item in
the shopping list. When one of the submit buttons is pressed, the
submit_SubmitBuy callback will be triggered (as part of the submission
procedure) and the browser will redirect to a page that handles the purchase
of the associated item.

NOTE: arrays not supported for file-upload elements.

=head1 XSP INHERITANCE

Starting with AxKit 1.6.1 it is possible to specify a class which your XSP
page inherits from. All the validate, load, submit and cancel functions can
be in the class you inherit from, reducing code duplication, memory usage,
and complexity.

=head1 SPECIFYING CALLBACKS

All of the documentation here uses the default callbacks which are implied
by the name of the form element you give. Unfortunately this makes it
difficult to have multiple elements with the same validation logic without
duplicating code. In order to get around this you can manually specify the
callbacks to use.

Every main tag supports both C<onvalidate> and C<onload> attributes which
specify perl function names to validate and load respectively. Submit
buttons support C<onsubmit> attributes. Cancel buttons support C<oncancel>
attributes. Forms themselves support both C<oncancel> and C<onsubmit>
attributes.

If a form is submitted without pressing a button (such as via JavaScript,
or by hitting <Enter>, then the form tag's C<onsubmit> callback will be
used. It is always sensible to define this to be one of your button's
submit callbacks.

All tags allow a C<disabled> attribute. Set this to a true value (i.e.
C<disabled="1">) to set the control to disabled. This will be interpreted
as a HTML 4.0 feature in the default perform stylesheet.

=head1 TAG DOCUMENTATION

The following documentation uses the prefix I<f:> for all PerForm tags. This
assumes you have a namespace declaration
C<xmlns:f="http://axkit.org/NS/xsp/perform/v1"> in your XSP file.

Please note that for all of the widget tags, PerForm uses TaglibHelper. This
has the advantage that you can define attributes either as XML attributes in
the tag, or as child tags in the PerForm namespace. So:

  <f:textfield name="foo" default="bar"/>

Is exactly equivalent to:

  <f:textfield name="foo">
    <f:default>bar</f:default>
  </f:textfield>

The advantage of this is that child tags can get their content from other
XSP tags.

=head2 <f:form>

This tag has to be around the main form components. It does not have to have
any ACTION or METHOD attributes, as that is all sorted out internally. Note
that you can have as many f:form tags on a page as you want, but it probably
doesn't make sense to nest them.

B<Attributes:>

=over 4

=item name

The name of the form. This name is used to call start_form_<name>, and
end_form_<name>.

=back

B<Callbacks:>

=over 4

=item start_form_<name>

Passed a single parameter: C<$ctxt>, the context object. This callback is
called before processing the form contents.

=item end_form_<name>

Passed a single parameter: C<$ctxt>, the context object. This callback is
called after processing the form contents, but before processing any submit
or cancel buttons.

=back

Note that <f:form> is the B<only> tag (besides <f:single-select/> and
<f:multi-select/>) in PerForm that has content. All other tags are empty,
unless you define the attributes in child tags, as documented above.

=head2 <f:submit/>

A submit button. Every form should have one, otherwise there is little point
in having a form!

B<Attributes:>

=over 4

=item name (mandatory)

The name of the submit button. Used for the submit callbacks.

=item value

The text on the button, if you are using a browser generated button.

=item image

A URI to the image, if you instead wish to use an image for the button.

=item alt

Alternate text for an image button.

=item border

The width of the border around an image button. Default is zero.

=item align

The alignment of the button

=item goto

If you do not wish to implement the callback below, you can set the goto
attribute to a URI to redirect to when the user hits the button. Normally
you won't use this unless you happen to not want to save the form values in
any way.

=item index

If your button is a member of an array, then set the index attribute to the
corresponding array index.

=item onclick

This attribute is intended to be passed through to the generated
output for client-side onClick routines (usually written in javascript).
Simply specify a string as you would if writing dynamic html
forms in plain HTML.

=back

B<Callbacks:>

=over 4

=item submit_<name> ( $ctxt , $index )

This callback is used to "do something" with the submitted form values. You
might write them to a database or a file, or change something in your
application.

The $index parameter identifies which button was pressed in an array of
buttons.

The return value from submit_<name> is used to redirect the user to the
"next" page, whatever that might be.

=back

=head2 <f:cancel/>

A cancel button. This is similar to the submit button, but instead of being
used to save the form values (or "do something" with them), should be used
to cancel the use of this particular form and go somewhere else. The most
common use of this is to simply set the I<goto> attribute to redirect to
another page.

B<Attributes:>

All attributes are the same as for <f:submit/>.

B<Callbacks:>

=over 4

=item cancel_<name> ( $ctxt, $index )

Implement this method to override the goto attribute. Return the URI you
want to redirect to. This can be used to dynamically generate the URI to
redirect to.

=back

=head2 <f:textfield/>

A text entry field.

B<Attributes:>

=over 4

=item name (mandatory)

The name of the textfield. Should be unique to the entire XSP page, as
callbacks only use the widget name. Can also be used in
C<$ctxt-E<gt>{Form}{E<lt>nameE<gt>}> to retrieve the value.

=item default

A default value for the textfield.

=item width

The width of the textfield on the screen. Units are dependant on the final
rendering method - for HTML this would be em characters.

=item maxlength

The maximum number of characters you can enter into this text field.

=item index

If your text field is a member of an array, then set the index attribute to
the corresponding array index.

=item onchange

This is a javascript callback implemented on the client side in HTML 4.0
capable browsers. It simply passes the value through to the generated
HTML.

=back

B<Callbacks:>

=over 4

=item load_<name> ( $ctxt, $default, $current, $index )

Used to load a value into the edit box. The default is from the attributes
above. The current value is only set if this form has been submitted once
already, and contains the value submitted.

Simply return the value you want to appear in the textfield.

If the text field is a memeber of an array, then $index will be the array
index.

If you do not implement this method, the value in the textfield defaults to
C<$current || $default>.

=item validate_<name> ( $ctxt, $value, $index )

Implement this method to validate the contents of the textfield. If the
value is valid, you don't need to do anything. However if it invalid, throw
an exception with the reason why it is invalid. Example:

  sub validate_username {
      my ($ctxt, $value) = @_;
      # strip leading/trailing whitespace
      $value =~ s/^\s*//;
      $value =~ s/\s*$//;
      die "No value" unless length $value;
      die "Invalid characters" if $value =~ /\W/;
  }

If the text field is a memeber of an array, then $index will be the array
index.

=back

=head2 <f:password/>

A password entry field. This works B<exactly> the same way as a textfield,
so we don't duplicate the documentation here

=head2 <f:checkbox/>

A checkbox.

B<Attributes:>

=over 4

=item name (mandatory)

The name of the checkbox, used to name the callback methods.

=item value

The value that gets sent to the server when this checkbox is checked.

=item checked

Set to 1 or yes to have this checkbox checked by default. Set to 0, no, or
leave off altogether to have it unchecked.

=item label

Used in HTML 4.0, the label for the checkbox. Use this with care as most
browsers don't support it.

=item index

Use this to identify the array index when using arrayed form elements.

=item onclick

This attribute is intended to be passed through to the generated
output for client-side onClick routines (usually written in javascript).
Simply specify a string as you would if writing dynamic html
forms in plain HTML.

=back

B<Callbacks:>

=over 4

=item load_<name> ( $ctxt, $current, $index )

If you implement this method, you can change the default checked state of
the checkbox, and the value returned by the checkbox if you need to.

Return one or two values. The first value is whether the box is checked or
not, and the second optional value is what value is sent to the server when
the checkbox is checked and submitted.

=item validate_<name> ( $ctxt, $value, $index )

Validate the value in the checkbox. Throw an exception to indicate
validation failure.

=back

=head2 <f:file-upload/>

A file upload field (normally in HTML, a text entry box, and a "Browse..."
button).

B<Attributes:>

=over 4

=item name (mandatory)

The name of the file upload field.

=item value

A default filename to put in the box. Use with care because putting
something in here is not very user friendly!

=item accept

A list of MIME types to accept in this dialog box. Some browsers might use
this in the Browse dialog to restrict the list of files to show.

=item onclick

This attribute is intended to be passed through to the generated
output for client-side onClick routines (usually written in javascript).
Simply specify a string as you would if writing dynamic html
forms in plain HTML.

=back

B<Callbacks:>

=over 4

=item load_<name> ( $ctxt, $default, $current )

Load a new value into the file upload field. Return the value to go in the
field.

=item validate_<name> ( $ctxt, $filename, $fh, $size, $type, $info )

Validate the uploaded file. This is also actually the place where you would
save the file to disk somewhere, by reading from $fh and writing to
somewhere else, or using File::Copy to do that for you. It is much harder to
access the file from the submit callback.

If the file is somehow invalid, throw an exception with the text of why it
is invalid.

=back

=head2 <f:hidden/>

A hidden form field, for storing persistent information across submits.

PerForm hidden fields are quite useful because they are self validating
against modification between submits, so if a malicious user tries to change
the value by editing the querystring or changing the form value somehow, the
execution of your script will die with an exception.

B<Attributes:>

=over 4

=item name (mandatory)

The name of the hidden field

=item value

The value stored in the hidden field

=item index

Use this to identify the array index when using arrayed form elements.

=back

B<Callbacks:>

=over 4

=item load_<name> ( $ctxt, $default, $index )

If you wish the value to be dynamic somehow, implement this callback and
return a new value for the hidden field.

=back

There is no validate callback for hidden fields.

=head2 <f:textarea/>

A large box of editable text.

B<Attributes:>

=over 4

=item name (mandatory)

A name for the textarea

=item cols

The number of columns (width) of the box.

=item rows

The number of rows of text to display.

=item wrap

Set this to "yes" or "1" to have the textarea wrap the text automatically.
Set to "no" or leave blank to not wrap. Default is to not wrap.

=item default

The default text to put in the textarea.

=item index

Use this to identify the array index when using arrayed form elements.

=item onchange

This is a javascript callback implemented on the client side in HTML 4.0
capable browsers. It simply passes the value through to the generated
HTML.

=back

B<Callbacks:>

=over 4

=item load_<name> ( $ctxt, $default, $current, $index )

Load a new value into the widget. Return the string you want to appear in
the box.

=item validate_<name> ( $ctxt, $value, $index )

Validate the contents of the textarea. If the contents are somehow invalid,
throw an exception in your code with the string of the error. One use for
this might be validating a forums posting edit box against a small DTD of
HTML-like elements. You can use XML::LibXML to do this, like this:

  sub validate_body {
    my ($ctxt, $value) = @_;
    $value =~ s/\A\s*//;
    $value =~ s/\s*\Z//;
    die "No content" unless length($value);
    my $dtdstr = <<EOT;
  <!ELEMENT root (#PCDATA|p|b|i|a)*>
  <!ELEMENT p (#PCDATA|b|i|a)*>
  <!ELEMENT b (#PCDATA|i|a)*>
  <!ELEMENT i (#PCDATA|b|a)*>
  <!ELEMENT a (#PCDATA|b|i)*>
  <!ATTLIST a
        href CDATA #REQUIRED
        >
  EOT
    my $dtd = XML::LibXML::Dtd->parse_string($dtdstr);
    my $xml = XML::LibXML->new->parse_string(
                "<root>$value</root>"
                );
    eval {
        $xml->validate($dtd);
    };
    if ($@) {
        die "Invalid markup in body text: $@";
    }
    
  }

=back

=head2 <f:single-select/>

A drop-down select list of items.

The single-select and multi-select (below) elements can be populated either
by callbacks or through embedded elements.

B<Attributes:>

=over 4

=item name (mandatory)

The name of the single select widget.

=item default

The default value that is to be selected.

=item index

Use this to identify the array index when using arrayed form elements.

=item onchange

This is a javascript callback implemented on the client side in HTML 4.0
capable browsers. It simply passes the value through to the generated
HTML.

=back

B<Elements:>

=over 4

=item <f:options>

Child to a <f:single-select> element, this wraps around a listing of
populated options

=item <option>

Child to <f:options>, this is an individual option

=item <name>

This is the name for a given option, to which it is a child

=item <value>

Similar to <name>, this indicates the value for an option

=back

B<Callbacks:>

=over 4

=item load_<name> ( $ctxt, $currently_selected )

The return values for this callback both populate the list, and define which
value is selected.

The return set is a simple list: selected, text, value, text, value, ...

Where selected matches a B<value> from that list. So, for example, it might
be:

  sub load_list {
      my ($ctxt, $current) = @_;
      return $current || "#FF0000", 
        "Blue" => "#0000FF", 
        "Red" => "#FF0000",
        "Green" => "#00FF00",
        ;
  }

=item validate_<name> ( $ctxt, $value )

Validate the value. Throw an exception with the text of the error if
something is wrong.

=back

=head2 <f:multi-select/>

A multiple select box, with a scrollable list of values.

B<Attributes:>

=over 4

=item name (mandatory)

The name of the multiple select widget.

=item default

The default value that is to be selected.  This can be specified as a child
element (e.g. <f:default>) in order to indicate multiple default values.

=item index

Use this to identify the array index when using arrayed form elements.

=item onclick

This attribute is intended to be passed through to the generated
output for client-side onClick routines (usually written in javascript).
Simply specify a string as you would if writing dynamic html
forms in plain HTML.

=back

B<Elements:>

The available child elements are identical to <f:single-select> so they will
not be repeated here.

B<Callbacks:>

=over 4

=item load_<name> ( $ctxt, $currently_selected )

This works very similarly to the load callback for single selects (above),
except that both the $currently_selected, and the returned selected value
are array refs.

=item validate_<name> ( $ctxt, $values )

Here $values is an array ref of the selected values. As usual, if one is in
error somehow, throw an exception containing the text of the error.

=back

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

=head1 SEE ALSO

L<AxKit>, L<Apache::AxKit::Language::XSP>

=cut
