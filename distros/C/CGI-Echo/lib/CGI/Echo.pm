package CGI::Echo;

# Name:
#	CGI::Echo.
#
# Purpose:
#	Let students input data to a form, and echo it back to them.
#
# Documentation:
#	POD-style documentation is at the end. Extract it with pod2html.*.
#
# Note:
#	o tab = 4 spaces || die
#
# V 1.00 1-Oct-2002
# -----------------
# o Original version
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	http://savage.net.au/index.html

use warnings;
use strict;

use Carp;

require 5.005_62;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use CGI::DBI ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '1.08';

# -----------------------------------------------

# Preloaded methods go here.

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(
		_css	=> '',
		_q		=> '',
		_title	=> 'Echo Test',
	);

	sub _clean_form_data
	{
		my($self)		= @_;
		$$self{'_data'}	= {};
		my(@param)		= $$self{'_q'} -> param();

		for my $field (@param)
		{
			@{$$self{'_data'}{$field} }	= $$self{'_q'} -> param($field);
			$$self{'_data'}{$field}[$_]	= $self -> _clean_form_field($$self{'_data'}{$field}[$_], 200, 0) for (0 .. $#{$$self{'_data'}{$field} });
		}

		scalar keys %{$$self{'_data'} };

	}	# End of _clean_form_data.

	sub _clean_form_field
	{
		my($self, $data, $max_length, $integer) = @_;
		$data = '' if (! defined($data) || ($data !~ /^([^`\x00-\x1F\x7F-\x9F]+)$/) || (length($1) == 0) || (length($1) > $max_length) );
		$data = '' if ($data =~ /<script\s*>.+<\s*\/?\s*script\s*>/i);	# http://www.perl.com/pub/a/2002/02/20/css.html.
		$data = '' if ($data =~ /<(.+)\s*>.*<\s*\/?\s*\1\s*>/i);		# Ditto, but much more strict.
		$data = 0 if ($integer && (! $data || ($data !~ /^[0-9]+$/) ) );

		$data;

	}	# End of _clean_form_field.

	sub _default_for
	{
		my($self, $attr_name) = @_;

		$_attr_data{$attr_name};
	}

	sub _standard_keys
	{
		sort keys %_attr_data;
	}

	sub _validate_options
	{
		my($self)			= @_;
		$$self{'_title'}	||= 'Echo Test';

		croak(__PACKAGE__ . ". You must supply a value for the parameter 'q'") if (! $$self{'_q'});

#		# Reset empty parameters to their defaults.
#		# This could be optional, depending on another option.
#
#		for my $attr_name ($self -> _standard_keys() )
#		{
#			$$self{$attr_name} = $self -> _default_for($attr_name) if (! $$self{$attr_name});
#		}

	}	# End of _validate_options.

}	# End of Encapsulated class data.

# -----------------------------------------------

sub new
{
	my($class, %arg)	= @_;
	my($self)			= bless({}, $class);

	for my $attr_name ($self -> _standard_keys() )
	{
		my($arg_name) = $attr_name =~ /^_(.*)/;

		if (exists($arg{$arg_name}) )
		{
			$$self{$attr_name} = $arg{$arg_name};
		}
		else
		{
			$$self{$attr_name} = $self -> _default_for($attr_name);
		}
	}

	return $self;

}	# End of new.

# -----------------------------------------------

sub print
{
	my($self, %arg) = @_;

	# Give the user one last chance to set some parameters.

	$self -> set(%arg);
	$self -> _validate_options();

	my(@html);

	push(@html, $$self{'_q'} -> th('Title') . $$self{'_q'} -> td($$self{'_title'}) );
	push(@html, $$self{'_q'} -> th('&nbsp;') . $$self{'_q'} -> td('&nbsp;') );

	if ($self -> _clean_form_data() )
	{
		my($param, $index);

		for $param (sort keys %{$$self{'_data'} })
		{
			push(@html, $$self{'_q'} -> th('Parameter') . $$self{'_q'} -> th('Value') );

			for $index (0 .. $#{$$self{'_data'}{$param} })
			{
				push(@html, $$self{'_q'} -> th( ($index + 1) . ": $param") . $$self{'_q'} -> td($$self{'_data'}{$param}[$index]) );
			}

			push(@html, $$self{'_q'} -> th('&nbsp;') . $$self{'_q'} -> td('&nbsp;') );
		}
	}
	else
	{
		push(@html, $$self{'_q'} -> th('Status') . $$self{'_q'} -> td('Form does not contain any data') );
		push(@html, $$self{'_q'} -> th('&nbsp;') . $$self{'_q'} -> td('&nbsp;') );
	}

	my($style)	= {};
	$style		= {style => {src => $$self{'_css'} } } if ($$self{'_css'});

	print	$$self{'_q'} -> header({type => 'text/html;charset=ISO-8859-1'}) .
			$$self{'_q'} -> start_html($style, title => $$self{'_title'}) .
			$$self{'_q'} -> h1({align => 'center'}, $$self{'_title'}) .
			$$self{'_q'} -> table
			(
				{align => 'center', border => 1, class => 'submit'},
				$$self{'_q'} -> Tr([@html])
			) .
			$$self{'_q'} -> end_html();

}	# End of print.

# -----------------------------------------------

sub set
{
	my($self, %arg) = @_;

	for my $arg (keys %arg)
	{
		$$self{"_$arg"} = $arg{$arg} if (exists($$self{"_$arg"}) );
	}

}	# End of set.

# -----------------------------------------------

1;

__END__

=head1 NAME

C<CGI::Echo> - Echo form data to test form design.

=head1 Synopsis

This is complete, tested program:

	#!/usr/bin/perl -wT

	use lib '.';
	use strict;

	use CGI;
	use CGI::Echo;

	# -----------------------------------------------

	my($q) = CGI -> new();

	CGI::Echo -> new(q => $q) -> print();

=head1 Description

This module accepts form data, cleans it, and echos it.

It is designed for a HTML/CGI student enviroment. It lets, indeed encourages,
students to design forms and gives their long-suffering instructors a simple
way to provide a CGI script which accepts the form data, and just echos it.

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Usage

See the synopsis.

=head1 Options

Here, in alphabetical order, are the options accepted by the constructor,
together with their default values.

=over 4

=item css => ''

This is the name of a CSS file which makes the sample form and the echoed
data look pretty.

See examples/default.css for a sample CSS file.

=item q => ''

This is the CGI object used by C<CGI::Echo> to do the work.

=item title => 'Echo Test'

This is the text used in the page title and as a heading when the form
data is echoed.

=back

=head1 Methods

=over 4

=item new(%arg): The constructor

See the previous section for details.

=item print(%arg): Display the form data

Call this to output a table containing the form data.

print(%arg) takes the same parameters as new().

=item set(%arg): Set class member options

Call this to set options after calling new().

set(%arg) takes the same parameters as new().

=back

=head1 A Sample Form

The synopsis in Echo.pm contains the only script you'll need. You'll find
the code in examples/echo.cgi.

A sample form, examples/test-echo.html, is shipped to bootstrap the design process.

=head1 Author

C<CGI::Echo> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2002.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2002, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
