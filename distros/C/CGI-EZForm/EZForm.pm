package CGI::EZForm;

# Pod-style documentation is at the end of this file.

use Carp qw(carp croak);

use Exporter();
@ISA = Exporter;

$CGI::EZForm::VERSION = "2002.0403";
sub Version { $VERSION; }

%default = (

    # field receive defaults
    multivalue_sep => ';',	# separator for multiple values of a field

    # table formatting defaults
    table => 1,			# draw fields within a table
    table_border => 0,		# table border is invisible
    table_width  => '80%',	# table is 80% of window wide
    table_align  => 'center',	# table is centered
    cellspacing  => 0,
    cellpadding  => 10,
    label_width  => '20%',	# label column is 20% of table width
    label_align  => 'right',	# label alignment
    td_valign    => 'top',		# table cell vertical alignment

    # field defaults
    type => 'text',		# default field type is text
    size => 30,			# default text/textarea width is 30 chars
    checkbox => 'Y',		# default value for checkbox
    rows => 3,			# default textarea rows

    # form header defaults
    method  => 'POST',
    enctype => 'application/x-www-form-urlencoded'
);

sub default {
    # change default value(s) to those specified
    my ($form) = shift;
    my %params = @_;
    foreach my $key (keys %params) {
        $default{$key} = $params{$key};
    }
}

sub new { return bless {}; }

sub set {
    # set one or more form values
    my $form   = shift;
    my %params = @_;
    foreach my $key (keys %params) {
        $form->{$key} = $params{$key};
    }
}

sub clear {
    # clear (delete) all form fields, or just those named in parameters
    my $form = shift;
    my @keys;
    my $key;
    if (@_ == 0) { # no params -- clear all
        @keys = keys(%$form);
    } else {
        @keys = @_;
    }
    foreach $key (@keys) {
	delete $form->{$key};
    }
}

sub get {
    my $form = shift;
    my $key = shift;
    return ($form->{$key} ? $form->{$key} : undef);
}

sub receive {
    my $form = shift;

    if (defined $ENV{'CONTENT_TYPE'}
    and $ENV{'CONTENT_TYPE'} =~ m#multipart/form-data#) {
	&_parse_multipart($form, &_receive());
    } else {
	&_parse_regular($form, &_receive());
    }
}

sub _receive {
    my ($incoming);

    # get the form data ...

    if (defined $ENV{'REQUEST_METHOD'} and $ENV{'REQUEST_METHOD'} eq "POST") {
        read(STDIN, $incoming, $ENV{'CONTENT_LENGTH'});
    }
    elsif (defined $ENV{'REQUEST_METHOD'} and $ENV{'REQUEST_METHOD'} eq "GET") {
        $incoming = $ENV{'QUERY_STRING'};
    }
    else { # for testing, allow input from command line
        $incoming = join('&',@ARGV);
    }

    return $incoming;
}

sub _parse_regular {
    my ($form, $incoming) = @_;

    # ... and decode it into %FORM

    my @pairs = split(/&/, $incoming);

    foreach (@pairs) {
        my ($name, $value) = split(/=/, $_);

	# un-escape any characters 'escaped' for http
        $name  =~ tr/+/ /;
        $value =~ tr/+/ /;
        $name  =~ s/%([A-F0-9][A-F0-9])/chr(hex($1))/gie;
        $value =~ s/%([A-F0-9][A-F0-9])/chr(hex($1))/gie;

        # Skip blank text entry fields
        next if ($value eq "");

        # Check for "assign-dynamic" field names
        # Mainly for on-the-fly input names, especially checkboxes
        if ($name =~ /^assign-dynamic/) {
            $name = $value;
            $value = "on";
        }

	# Allow for multiple values of a single name
	if (defined $form->{$name}) {
	    $form->{$name} .= $default{multivalue_sep};
	    $form->{$name} .= $value;
	} else {
	    $form->{$name} = $value;
	}
    }
}

sub _parse_multipart {
    croak 'Sorry, cannot deal with multipart forms yet.';
}

sub dump {
    my $form = shift;
    my @keys;
    my $key;
    if (@_ == 0) {
        @keys = sort keys(%$form);
    } else {
        @keys = @_;
    }
    foreach $key (@keys) {
       print $key, '=', $form->{$key}, "\n";
    }
}

sub use_table {
    my $form = shift;	# actually ignored for this function
    my $thing = shift;
    $default{table} = $thing; 
}

sub draw {
    # draws a form input field or button
    my $form = shift;
    my %params = @_;
    my @keys = keys %params;
    my $key;
    my $html = '';

    # make sure anything required exists
    unless (defined $params{type}) {$params{type} = $default{type};}
    unless (defined $params{label}) {$params{label} = '&nbsp;';}

    # name is optional, but if not specified will assign the value as
    # a name when the data is received.
    unless (defined $params{name}) {$params{name} = 'assign-dynamic';}

    # provide for a label;
    # if we're  doing table formatting, this means putting it into
    # column one
    unless ($params{type} eq 'hidden') {
	if ($default{table}) {
	    $html .= _tr_start($params{label});
	} else {
	    $html .= $params{label};
	}
    }

    TYPE_CASE: {
        if ($params{type} eq 'select') {
	    $html .= qq|<select|;
	    $html .= qq| name="$params{name}"| if $params{name};
	    $html .= qq| multiple| if $params{multiple};
	    $html .= &_add_extras(\%params,
		grep !/^(type|label|name|multiple|options|values|selected)$/,
		     (keys %params));
	    $html .= qq|>\n|;
	    $html .= &_select(
		$params{options},
		$params{'values'},
		($params{selected} or [($form->{$params{name}} or '')])
		);
	    $html .= qq|</select>\n|;
	    last;
	}

        if ($params{type} =~ /submit|reset|image/) {
	    $html .= "<input type=$params{type}";
	    $html .= &_add_extras(\%params,
		grep !/^(type|label)$/, (keys %params));
	    $html .= ">\n";
	    last;
	}

        if ($params{type} eq 'radio') {
	    $html .= &_radio(
		$params{name},
		($form->{$params{name}} or ''),
		($params{vertical} or 0),
		$params{captions}, $params{'values'});
	    last;
	}

        if ($params{type} eq 'checkbox') {
	    # checkbox gotta have value
	    unless (exists $params{value}) {
		if (defined $form->{$params{name}}) {
		    $params{value} = $form->{$params{name}};
		} else {
		    $params{value} = $default{checkbox};
		}
	    }
	    $html .= sprintf qq|<input type="checkbox" name="%s" value="%s"|,
		$params{name},
		$params{value};
	    if (defined $form->{$params{name}}
	    and ($params{value} eq $form->{$params{name}}) ) {
		$html .= ' checked';
	    }
	    $html .= &_add_extras(\%params,
		grep !/^(type|label|name|value|caption)$/, (keys %params));
	    $html .= ">\n";
	    $html .= ($params{caption} or '');
	    last;
	}

        if ($params{type} eq 'textarea') {
	    $html .= sprintf
		qq|<textarea name="%s" rows="%s" cols="%s" wrap="%s"|,
		$params{name},
		($params{rows} || $default{rows}),
		($params{cols} || $default{size}),
		($params{wrap} || 'virtual');
	    $html .= ' readonly' if $params{readonly};
	    $html .= ' disabled' if $params{disabled};
	    $html .= &_add_extras(\%params,
	     grep !/^(type|label|name|value|cols|rows|wrap|readonly|disabled)$/,
	      (keys %params));
	    $html .= sprintf qq|>\n%s</textarea>\n|,
		($params{value} or $form->{$params{name}} or '');
	    last;
	}

        if ($params{type} eq 'hidden') {
	    $html .= sprintf qq|<input type="hidden" name="%s" value="%s">\n|,
		$params{name},
		($params{value} || $form->{$params{name}});
	    last;
	}

	# default case is an input field (text or password)
	$html .= sprintf qq|<input type="%s" name="%s" size="%s" value="%s"|,
	    ($params{type} or $default{type}),
	    $params{name},
	    ($params{size} || $default{size}),
	    ($params{value} or $form->{$params{name}} or '');
	$html .= ' readonly' if $params{readonly};
	$html .= ' disabled' if $params{disabled};
	$html .= &_add_extras(\%params,
	    grep !/^(type|label|name|size|value|readonly|disabled)$/,
		(keys %params));
	$html .= ">\n";
    }
    unless ($params{type} eq 'hidden') {
	if ($default{table}) {
	    $html .= &_tr_end;
	}
    }
    return $html;
}

sub _select {
    my ($options, $values, $selected) = @_;
    my ($i, $count);

    my $html = '';

    $count = @$options;
    for ($i = 0; $i < $count; $i++) {
	$html .= &_option($$options[$i],
	    (defined $values ? $$values[$i] : ''),
	    @$selected);
    }

    return $html;
}

sub _option {
    my ($option, $value, @selected) = @_;
    my $html = '';
    $html .= qq|<option|;
    $html .= qq| value="$value"| if defined $value;
    # the option should be selected if it matches a list of options to
    # be selected
    if ( (defined $value and (grep /$value/, @selected))
    or   (defined $option and (grep /$option/, @selected)) ) {
	$html .= qq| selected|
    }
    $html .= qq|>$option</option>\n|;
}

sub _radio {
    my ($name, $selected, $vertical, $captions, $values) = @_;
    my ($i, $count);

    my $html = '';

    $count = @$captions;
    for ($i = 0; $i < $count; $i++) {
	$html .= qq|<input type="radio" name="$name"|;
	$html .= qq| value="$$values[$i]"| if defined $values;
	$html .= qq| checked|
	    if (defined $selected and ($selected eq $$values[$i]));
	$html .= qq|>$$captions[$i]|;
	if ($vertical) {
	$html .= "<br>\n"; } else { $html .= "&nbsp;\n"; }
    }

    return $html;
}

sub _add_extras {
    # add attributes from a list of param keys
    # this usefully allows you to include any attributes you like,
    # such as javascript.
    # Less usefully, you can include attributes which are not valid,
    # so be careful.
    $params = shift;	# hash ref.
    my $html = '';
    foreach my $key (@_) {
	$html .= qq| $key="$$params{$key}"|;
    }
    return $html;
}

sub hidden {
    my $form = shift;
    my @names = @_;
    my $html = '';
    foreach my $name (@names) {
	$html .= sprintf qq|<input type="hidden" name="%s" value="%s">\n|,
	    $name,
	    $form->{$name};
    }
    return $html;
}

sub form_start {
    my $form = shift;
    my %params = @_;

    my $html =
    sprintf qq|<form action="%s" method="%s" enctype="%s"|,
	($params{action} || $ENV{SCRIPT_NAME}),
	($params{method} || $default{method}),
	($params{enctype} || $default{enctype});
	$html .= &_add_extras(\%params,
	    grep !/^(action|method|enctype)$/, (keys %params));
	$html .= ">\n";
    if ($default{table}) {
        $html .= &table_start();
    }
}


sub form_end {
    my $html = '';
    if ($default{table}) {
        $html .= &table_end();
    }
    $html .= "</form>\n";
}

sub table_start {
    my $form = shift;
    my %params = @_;
    $default{table} = 1;
    return sprintf
	qq|<table border="%s" width="%s" cellspacing="%s" cellpadding="%s" align="%s">\n|,
	($params{border} || $default{table_border}),
	($params{width} || $default{table_width}),
	($params{cellspacing} || $default{cellspacing}),
	($params{cellpadding} || $default{cellpadding}),
	($params{table_align} || $default{table_align});
}

sub table_end {
    $default{table} = 0;
    return "</table>\n";
}


sub _tr_start {
    my ($label) = @_;
    $label = '' unless $label;
    return sprintf
	qq|<tr><td valign="%s" align="%s" width="%s">%s</td><td valign="%s">\n|,
	$default{td_valign},
	$default{label_align},
	$default{label_width},
	$label,
	$default{td_valign};
}


sub _tr_end {
    # prints closing tags for a table row.
    return "</td></tr>\n";
}

1;

__END__

=head1 NAME

CGI::EZForm.pm

=head1 SYNOPSIS

    use CGI::EZForm;
    $form = CGI::EZForm->new;

    $form->set(parameters);
    $form->clear(keys);
    $form->get(key);
    $form->dump(keys);

    $form->receive();

    $form->draw(parameters);
    $form->hidden(list);

    $form->form_start (parameters);
    $form->form_end();
    $form->table_start (parameters);
    $form->table_end();

    $form->default(parameters);
    $form->use_table(true|false);

=head1 DESCRIPTION

CGI::EZForm.pm provides basic functionality for CGI web form processing.

Yes, you could use the commonly used CGI.pm module by Lincoln Stein, but
for many tasks this seems like overkill -- rather like driving a
Formula-1 racing car to the supermarket. I wrote CGI::EZForm.pm because I
wanted something simple and easy to use.

Some advantages of EZForm are:

=over

=item Defaults

EZForm provides intelligent and reasonable (IMHO) defaults for
most things. This means that there's a lot of stuff you can leave out 
if you want minimal typing. E.g. there's a default field type of "text"
which means you can omit that for all your text boxes.

All defaults can be changed if you want.

=item Formatting

By default, your form input fields are drawn in a 2-column table format,
with a label in the left column and the input fields in the right.
EZForm will draw all this for you. You only need supply the field
definitions, not the formatting. (You DO still need to provide all the
other HTML around the form, though. USe CGI.pm if you want something
which does everything.

=back

Here's a sample script to demonstrate its use:

    #!/usr/local/bin/perl -w
    #
    # test script for CGI module
    #

    use CGI::EZForm qw(form_start form_end draw);

    # Create somewhere to put the form data
    $form = new CGI::EZForm;

    # Pre-set some form values
    $form->{station} = 'JJJ';

    # Get any form data provided from the browser
    $form->receive;

    # Start our web page to be returned to the browser ...
    print "Content-type: text/html\r\n\r\n";
    # probably good practice to add some HTML header etc. here

    # Now let's print a form ...

    print
	$form->form_start(action => '/cgi-bin/test.pl'),
	$form->draw(type => 'text', name => 'account',
	    label => 'Account number', size => 30),
	$form->draw(type => 'radio', name => 'station',
	    values => ['JJJ', 'MMM'],
	    captions => ['Triple-J', 'Triple-M']),
	$form->draw(type => 'select', name => 'choice', label => 'Choose',
	    selected => 'one',
	    options => ['First', 'Second', 'Third'],
	    values => ['one', 'two', 'three']),
	$form->draw(type => 'submit', value => 'Send'),
	$form->form_end;

    exit;

=head1 METHODS

Available methods are:

=over

=item $form = CGI::EZForm->new;

Creates a new form:

In reality, this just creates a reference to a hash which will hold
the field values, so you can access particular form field values
directly, as in

    $xyz = $form->{xyz};

providing you are not an OOP purist, I guess. (If you are, use the get
method.)

=item $form->set(PARAMS);

allows you to set value on one or more form fields. E.g.

    $form->set(me => 'Tarzan', you => 'Jane');

Of course, you can just set individual fields using 

    $xyz = $form->{xyz};

which is probably faster.

=item $form->clear(KEYS);

clears form field values from the form. If called with no parameters,
clears all fields, otherwise clears only the named fields. E.g.

    $form->clear;			# clears all fields
    $form->clear('name', 'addr');	# clears only the name and addr fields

=item $form->get(KEY);

returns the value of KEY. Included only for the OOP fanatic.
Utilitarians will use $form->{KEY} instead to retrieve values
directly.

=item $form->receive();

Probably the first call you'll want to make after new, receive will
check for incoming data by various methods, and fill your hash with
any values it finds.

=item form_start(PARAMS);

returns HTML for a form header:

    $form->form_start( action => '/cgi/myscript.pl', method => 'POST', 
		       enctype => $encoding, name => $name);

Everything can be defaulted except name. 'action' defaults to the
current script, which is common enough to be useful, so that you can
get away with just

    $form->form_start();

This will produce the equivalent of this HTML:

    <form action="$ENV{SCRIPT_NAME}" method="POST"
          enctype="application/x-www-form-urlencoded">

=item $form->form_end();

returns the form end tag. If table formatting is on, then it also
returns html to close the table.

=item $form->draw(PARAMS);

returns a string of HTML to display a particular form "object"
(using the term loosly). draw expects to receive parameters as a
hash, probably anonymous. The hash keys should correspond with the
attribute names for the html tag being requested, with the addition
of "label" to specify a text label for the field, and "caption" for
radio and checkbox. Radio and select types are a bit special, in that
some of their parameters are lists.

All attributes have reasonable defaults, so you only need to specify
those where you want something different from the default.

Note that "value" will always default to the current value for the
field name, if any.

Note that every field requires a name (except reset buttons). But,
if you omit name, CGI::EZForm will use "assign-dynamic". The request
function will detect this and replace it with the value of the
field. E.g. "assign-dynamic=fred" will transform into "fred=fred".
This may or may not be useful.

Note that you can include any attribute that you think is useful,
even if it is not valid HTML. CGI::EZForm.pm doesn't validate these,
it just assumes you know what you are doing. Usefully, you can add
additional, _valid_ HTML, as in:

    $form->draw( ..., onSubmit => 'javascript:...');

Some examples:

Input fields:

    $form->draw( type => 'text',
	name => 'boris', value => 'natasha', size => 30, 
	readonly => 1,
	label => 'field description'
    );

    will draw an input text field. Note that if you don't specify a
    value, the current value in $form{boris} will be used.

    type can be one of 'text', 'password' or 'hidden' (in which case
    size will be ignored, if present).

Checkbox fields:

    $form->draw( type => 'checkbox',
	name => 'spam', value => 'yes',
	caption = 'click to receive junk mail',
	label => 'Tell me more?'
    );

Radio buttons are a bit more complex, since they usually come in
groups:

    $form->draw( type => 'radio', name => 'station',
	values => [ 'JJJ', 'MMM' ],
	captions => [ 'Triple-J', 'Triple-M' ],
	vertical = 1,
	label => 'Choose your station'
    );

    captions appear to the right of the radio button.
    values are what get returned if the button is "on".
    vertical will place your radio buttons in a vertical list,
    otherwise they'll be drawn horizontally.

Selection lists are like radio groups, only different. Aside from
the actual formatting, one difference is that select lists allow for
multiple values to be selected:

    $form->draw( type => 'select', name => 'boris',
	options => [ 'First', 'Second', 'Third' ],
	values => [ 'one', 'two', 'three' ],
	selected => [ 'First', 'Third' ],
	multiple => 'true',
	label => 'Choose one or more'
    );

    options is a reference to a list of options
    values is a reference to a list of values to be returned.
    selected is a reference to a list of values to be pre-selected.
    If selected is not specified, a value will be selected if it
    matches $form->{name}

Buttons:

    $form->draw( type => 'image', src => 'file.jpg',
		 name => 'next', value => 'Next');
    $form->draw( type => 'submit', name => 'next', value => 'Next');
    $form->draw( type => 'reset');

=item $form->hidden(LIST);

returns html for all your hidden fields, specified in LIST, which should
be a list of form field names. This is useful if you have a bunch of
hidden fields. It is assumed that $form contains values for all the
fields named in LIST. E.g.

    $form->set( return_to => $ENV{HTTP_REFERRER}, code => '987');
    ...
    $form->hidden('return_to', 'code');

produces

    <input type="hidden" name="return_to" value="some url">
    <input type="hidden" name="code" value="987">

To draw hidden fields without pre-setting form values, use the draw
function instead. But you'll have to draw them one at a time.

=item $form->use_table(PARAMS);

Input fields often look better when laid out in a table, with a
label in column 1 and the input field in column 2.
use_table can be called to turn table-formatting on or off. E.g.

    $form->use_table(0);

You can also call default to toggle table formatting:

    $form->default(table => 0);

Note that in neither case, if a table is already started, does the
function close the table. You need to call table_start and table_end 
to explicitly start/end a table.

=item $form->table_start(PARAMS);

=item $form->table_end();

If desired, you can call these routines to start and end tables as
and when. If table formatting is turned on, a table is automatically
started when you call form_start, and terminated when you call
form_end.

table_start can also be called to change the defaults for borders
(0), and width (80%).

=item $form->default(PARAMS);

The module supplies defaults for most parameters, but you can change
any default(s) with this function. E.g. this will set all the
defaults to their default values:

    $form->default(

	# field receive defaults
	multivalue_sep => ';',	# separator for multiple values of a field

	# table formatting defaults
	table => 1,			# draw fields within a table
	table_border => 0,		# table border is invisible
	table_width  => '80%',		# table is 80% of window wide
	table_align  => 'center',	# table is centered
	cellspacing  => 0,
	cellpadding  => 10,
	label_width  => '20%',		# label column is 20% of table width
	label_align  => 'right',	# label alignment
	td_valign    => 'top',		# table cell vertical alignment

	# field defaults
	type => 'text',		# default field type is text
	size => 30,		# default text/textarea width is 30 chars
	checkbox => 'Y',	# default value for checkbox
	rows => 3,		# default textarea rows

	# form header defaults
	method  => 'POST',
	enctype => 'application/x-www-form-urlencoded'
    );

=item $form->dump(LIST);

will dump out the values in your hash, sorted by key. This is
provided mainly for debugging purposes.

dump optionally takes a list a keys to be dumped. With no options,
it dumps all keys.

=back

=head1 NOTES

CGI::EZForm.pm does not produce pretty HTML. Generally, only a browser
sees the HTML, and it doesn't care.

CGI::EZForm.pm doesn't do (much) validation of input parameters. If you
want to break rules, go ahead. Generally, it is assumed that you know
enough HTML to know what's required.

=head1 VERSION

Version 2002.0403

The latest version of this script should be found at:
http://www.library.adelaide.edu.au/~sthomas/scripts/EZForm/

=head1 AUTHOR

Steve Thomas <stephen.thomas@adelaide.edu.au>

=head1 LICENCE

Copyright (C) 2002 Steve Thomas. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. 

=cut
