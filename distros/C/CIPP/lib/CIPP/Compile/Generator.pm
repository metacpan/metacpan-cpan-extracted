# $Id: Generator.pm,v 1.40 2006/05/19 08:03:37 joern Exp $

package CIPP::Compile::Generator;

@ISA = qw ( CIPP::Compile::Parser );

use strict;
use Carp;
use Config;
use CIPP::Compile::Parser;
use IO::String;
use FileHandle;

#---------------------------------------------------------------------
# These methods the skeleton of CIPP programs, Includes and Modules,
# so they are not directly related to CIPP commands.
#---------------------------------------------------------------------

sub generate_start_program {
	croak "generate_start_program not implemented";
}

sub generate_project_handler {
	croak "generate_project_handler not implemented";
}

sub generate_open_exception_handler {
	my $self = shift; $self->trace_in;
	
	$self->write (
		"# generic exception handler eval\n",
		"eval {\n\n"
	);
	
	1;
}

sub generate_open_request {
	my $self = shift; $self->trace_in;
	
	$self->write (
		'$_cipp_project->new_request ('."\n",
		'    program_name => "'.$self->get_program_name.'"'."\n",
		');'."\n"
	);

	1;
}

sub generate_close_exception_handler {
	my $self = shift; $self->trace_in;
	
	$self->writef (
		"\n".
		"}; # end of generic exception handler eval\n\n".
		'# check for an exception (filters <?EXIT> exception)'."\n".
		'if ( $@ and $@ !~ /_cipp_exit_command/ ) {'."\n".
		'    $CIPP::request->error ('."\n".
		'        message      => $@,'."\n".
		'    ) if defined $CIPP::request;'."\n".
		'}'."\n\n",
		$self->get_program_name,
	);
	
	1;
}

sub generate_close_request {
	my $self = shift; $self->trace_in;
	
	$self->write (
		'$CIPP::request->close if defined $CIPP::request;'."\n"
	);

	1;
}

sub generate_debugging_code {
	my $self = shift; $self->trace_in;
	
	# no debugging code für closed tags, var context and the <?>
	# expression tag (which is the tag with the empty name).
	return if $self->context =~ /^var/ or
		  $self->get_current_tag_closed or
		  $self->get_current_tag eq '';

	$self->write (
		'# cipp_line_nr='.
		$self->get_current_tag_line_nr." ".
		$self->get_current_tag."\n"
	);
	
	1;
}

sub generate_include_open {
	my $self = shift; $self->trace_in;
	
	my $package = $self->get_program_name;
	my $i = 0;
	$package =~ s/\./_/g;
	$package =~ s/\W/++$i/ge;

	$package = "main";
	
	# An Include is a subroutine
	$self->writef (
		'package %s;'."\n\n".
		'use strict;'."\n".
		'sub {'."\n",
		$package
	);

	my $interface = $self->get_state->{incinterface};

	# code for input parameters
	foreach my $var ( values %{$interface->{input}} ) {
		my $name = $var;
		$name =~ s/^(.)//;
		my $deref = $1;
		
		if ( $deref eq '$' ) {
			$self->write ("    my $var = ".'$_[0]->{'.$name.'};'."\n");
		} else {
			$self->write ("    my $var = $deref\{".'$_[0]->{'.$name.'}};'."\n");
		}
	}
	
	# code for optional parameters
	foreach my $var ( values %{$interface->{optional}}) {
		my $name = $var;
		$name =~ s/^(.)//;
		my $deref = $1;
		
		if ( $deref eq '$' ) {
			$self->write ("    my $var = ".'$_[0]->{'.$name.'};'."\n");
		} else {
			# don't write: my $var = ${$foo} if defined $foo
			# this produce strange behaviour (at least unter Perl 5.6.0)
			# The dereferenced memory seems to live outside the
			# scope of this subroutine.
			$self->write ("    my $var;\n");
			$self->write ("    $var = $deref\{".'$_[0]->{'.$name.'}} if defined $_[0]->{'.$name.'};'."\n");
		}
	}

	# declaration of output parameters
	if ( keys %{$interface->{output}} ) {
		my $code;
		foreach my $var ( values %{$interface->{output}} ) {
			$code .= "$var,";
		}
		$code =~ s/,$//;
		$self->write ("    my ($code);\n");
	}

	1;
}

sub generate_include_close {
	my $self = shift; $self->trace_in;
	
	my $interface = $self->get_state->{incinterface};

	# return output parameter
	if ( values %{$interface->{output}} ) {
		my $code;
		my $name;
		foreach my $var ( values %{$interface->{output}} ) {
			$name = $var;
			$name =~ s/^(.)//;
			$code .= "$name => \\$var, ";
		}
		$code =~ s/,$//;
		$self->write ("    return { $code};\n");
	}
	
	# close subroutine
	$self->write (
		'}'."\n"
	);

	1;
}

sub generate_module_open {
	my $self = shift; $self->trace_in;
	
	$self->write (
		"use strict;\n",
#		'my $_cipp_line_nr;'."\n",
	);
	
	1;
}

sub generate_module_close {
	my $self = shift; $self->trace_in;

	$self->write (
		'1;'."\n",
	);
	
	1;
}

#---------------------------------------------------------------------
# This method processes all text blocks between tags
#---------------------------------------------------------------------

sub process_text {
	my $self = shift; $self->trace_in;
	my ($text) = @_;

	$self->debug("GOT TEXT: '$$text'\n");

	$self->set_last_text_block($$text);
	
	my $context   = $self->context;
	my $autoprint = $self->get_state->{autoprint};

	if ( ($autoprint and $context eq 'html') or $context eq 'force_html' ) {
		if ( $$text ne '' and $$text =~ /\S/ ) {
			# print only if the chunk isn't empty or contains
			# not only whitespace
			$self->generate_debugging_code;

			# escape § sign (which is the qouting delimiter)
			$$text =~ s/§/\\§/g;

			# truncate whitespace
			if ( $self->get_trunc_ws ) {
				$$text =~ s/^\s+//;
				if ( not $$text =~ s/\s*\n\s*$/\n/ ) {
					$$text =~ s/\s+$/ /;
				}
			}

			# generate print() command
			$self->write ("print qq§$$text§;\n");
		}

	} elsif ( $autoprint and $context eq 'html_exact' ) {
		$$text =~ s/§/\\§/g;
		$self->write ( "print qq§$$text§;\n");
	
	} elsif ( $context eq 'perl' ) {
		$self->write ($$text);

	} elsif ( $context eq 'var_quote' ) {
		$$text =~ s/\^/\\^/g;
		$self->write ($$text);

	} elsif ( $context eq 'var_noquote' ) {
		$self->write ($$text);
	}

	1;
}

#---------------------------------------------------------------------
# Process method for each CIPP command
#---------------------------------------------------------------------

sub cmd_perl {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

	if ( $self->get_current_tag_closed ) {
		$self->pop_context;
		
		$self->check_options (
			mandatory => {},
			optional  => {},
		) || return $RC;

		$self->write (";}\n");

		return $RC;
	}

	$self->check_options (
		mandatory => {},
		optional  => { 'cond' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	$self->write ("if ($options->{cond}) ") if defined $options->{cond};
	$self->write ("{");

	$self->push_context('perl');

	return $RC;
}

sub cmd_expression {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

	if ( $self->get_current_tag_closed ) {
		my $buffer = $self->get_last_text_block;
		$self->add_tag_message (
			message => "Expression must not have trailing semicolon"
		) if $buffer =~ /;\s*$/;

		$self->pop_context;
		
		$self->check_options (
			mandatory => {},
			optional  => {},
		) || return $RC;

		$self->write (");\n");

		return $RC;
	}

	$self->check_options (
		mandatory => {},
		optional  => {},
	) || return $RC;

	$self->write ("print (");

	$self->push_context('perl');

	return $RC;
}

sub cmd_html {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

	if ( $self->get_current_tag_closed ) {
		$self->pop_context;
		
		$self->check_options (
			mandatory => {},
			optional  => {},
		);

		return $RC;
	}

	$self->check_options (
		mandatory => {},
		optional  => {},
	) || return $RC;

	$self->push_context('force_html');

	return $RC;
}

sub cmd_if {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

	if ( $self->get_current_tag_closed ) {
		$self->check_options (
			mandatory => {},
			optional  => {},
		) || return $RC;
		$self->write ("}\n");
		return $RC;
	}

	$self->check_options (
		mandatory => { 'cond' => 1 },
		optional  => {},
	) || return $RC;

	my $options = $self->get_current_tag_options;

	$self->write ("if ($options->{cond}) {\n");

	return $RC;
}

sub cmd_while {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

	if ( $self->get_current_tag_closed ) {
		$self->check_options (
			mandatory => {},
			optional  => {},
		) || return $RC;
		$self->write ("}\n");
		return $RC;
	}
	
	$self->check_options (
		mandatory => { 'cond' => 1 },
		optional  => {},
	) || return $RC;

	my $options = $self->get_current_tag_options;

	$self->write("while ($options->{cond}) {\n");

	return $RC;
}

sub cmd_do {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

	if ( $self->get_current_tag_closed ) {
		$self->check_options (
			mandatory => { 'cond' => 1 },
			optional  => {},
		) || return $RC;
		
		my $options = $self->get_current_tag_options;

		$self->write ("} while ($options->{cond});\n");
		
		return $RC;
	}

	$self->check_options (
		mandatory => {},
		optional  => {},
	) || return $RC;

	$self->write ("do {\n");

	return $RC;
}

sub cmd_var {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

	my $tag_data;
	
	if ( $tag_data = $self->get_current_tag_closed ) {
		$self->pop_context;

		$self->check_options (
			mandatory => {},
			optional  => {},
		) || return $RC;

		my $quote_char = $tag_data->{quote} ? '^' : '';

		$self->write($quote_char);

		if ( $tag_data->{default} ) {
			my ($open_quote, $close_quote);
			($open_quote, $close_quote) = ("qq^","^")
				if $tag_data->{quote};
			$self->write(
				qq{|| $open_quote$tag_data->{default}$close_quote}
			);
		}

		$self->write(";\n");
		return $RC;
	}

	my ($var_quote, $var_default);

	$self->check_options (
		mandatory => { 'name' => 1 },
		optional  => { 'default' => 1,
			       'type'    => 1,
			       'my'      => 1,
			       'noquote' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	my $name = $self->parse_variable_option (
		option => 'name'
	) || return $RC;

	if ( $name =~ /^[\@\%]/ ) {
		if ( defined $options->{default} ) {
			$self->add_tag_message (
				message => "DEFAULT is invalid for non scalar variables"
			);
			return $RC;
		}
		$var_quote = 0;
	} else {
        	$var_quote = 1;
	}

        if ( defined ($options->{type}) ) {
		$options->{type} =~ tr/A-Z/a-z/;
		if ( $options->{type} eq "num" ) {
			$self->{var_quote} = 0;
		} else {
			$self->add_tag_message (
				message => "Invalid TYPE."
			);
			return $RC;
		}
	}

	$var_quote = 0 if defined $options->{noquote};

	my $quote_char     = $var_quote ? 'qq^' : '';
	my $quote_end_char = $var_quote ? '^' : '';

	$self->write("my ") if defined $options->{'my'};

        if ( defined ($options->{default}) ) {
		$var_default = $options->{default};
	}

	$self->write("$name=".$quote_char);

	if ( $var_quote ) {
		$self->push_context('var_quote');
	} else {
		$self->push_context('var_noquote');
	}

	return $self->RC_BLOCK_TAG (
		quote   => $var_quote,
		default => $var_default
	);
}

sub cmd_else {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => {},
		optional  => {},
	) || return $RC;

	$self->write ("} else {\n");

	return $RC;
}

sub cmd_elsif {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => { 'cond' => 1 },
		optional  => {},
	) || return $RC;

	my $options = $self->get_current_tag_options;

	$self->write ("} elsif ($options->{cond}) {\n");

	return $RC;
}

sub cmd_try {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

	$self->check_options (
		mandatory => {},
		optional  => {},
	) || return $RC;

	if ( $self->get_current_tag_closed ) {
		$self->write (
			"};\n".
			"(\$_cipp_exception, \$_cipp_exception_msg)=".
			"split(\"\\t\",\$\@,2);\n".
			'$_cipp_exception_msg=$_cipp_exception '.
			'if $@ and $_cipp_exception_msg eq "";'."\n".
			'die "_cipp_exit_command" if $_cipp_exception eq "_cipp_exit_command";'."\n"
		);
		return $RC;
	}

	$self->write (
		"my (\$_cipp_exception,\$_cipp_exception_msg)=(undef,undef);\n".
		"eval {\n"
	);

	return $RC;
}

sub cmd_catch {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

	$self->check_options (
		mandatory => {},
		optional  => { 'throw' => 1,
			       'my' => 1,
			       'excvar' => 1,
			       'msgvar' => 1 },
	) || return $RC;

	if ( $self->get_current_tag_closed ) {
		$self->write ("}\n");
		return $RC;
	}

	my $options = $self->get_current_tag_options;

	my $my = '';
	$my = 'my ' if defined $options->{'my'};
	
	my $excvar = $self->parse_variable_option (
		option => 'excvar', types => [ 'scalar' ]
	);
	my $msgvar = $self->parse_variable_option (
		option => 'msgvar', types => [ 'scalar' ]
	);
	
	$self->write ("$my$excvar = \$_cipp_exception;\n")     if $excvar;
	$self->write ("$my$msgvar = \$_cipp_exception_msg;\n") if $msgvar;

	if ( defined $options->{throw} ) {
		$self->write (
			'if ( $_cipp_exception eq "'.$options->{throw}.'" ) {'."\n"
		);
	} else {
		$self->write (
			"if ( defined \$_cipp_exception ) {\n"
		);
	}

	return $RC;
}

sub cmd_log {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => { 'msg'  => 1 },
		optional  => { 'type' => 1, 'filename' => 1, 'throw' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	$options->{type}     ||= "APP";
	$options->{filename} ||= "";
	$options->{throw}    ||= "LOG";

	$self->writef (
		'$CIPP::request->log ('."\n".
		'   type     => "%s",'."\n".
		'   message  => "%s",'."\n".
		'   filename => "%s",'."\n".
		'   throw    => "%s",'."\n".
		');'."\n",
		
		$options->{type}, $options->{msg},
		$options->{filename}, $options->{throw}
	);

	return $RC;
}

sub cmd_throw {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => { 'throw' => 1 },
		optional  => { 'msg' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	if ( defined $options->{msg} ) {
		$self->write (
			qq{die "$options->{throw}\t$options->{msg}";\n}
		);
	} else {
		$self->write (
			qq{die "$options->{throw}\t";\n}
		);
	}

	return $RC;
}

sub cmd_dump {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => {},
		optional  => { '*' => 1 },
	) || return $RC;

	my $options_order = $self->get_current_tag_options_order;

	my $options = $self->get_current_tag_options;

	my $stderr = delete $options->{stderr};
	my $log    = delete $options->{log};

	$self->write ("use Data::Dumper;\n");

	my $dumper_code =
		"join('',Data::Dumper->Dump ([".
		join(', ', grep !/^stderr|log$/i, @{$options_order}).
		"], [qw(".
		join(' ', grep !/^stderr|log$/i, @{$options_order}).
		")]))";

	if ( $stderr ) {
		$self->writef (
			"print STDERR %s;\n",
			$dumper_code
		);
	}
	
	if ( $log ) {
		$self->writef (
			'$CIPP::request->log(type=>"dump",message=>"\n".%s);'."\n",
			$dumper_code
		);
	}

	if ( not $stderr and not $log ) {
		$self->writef (
			'print "<pre>".%s."</pre>\n";',
			$dumper_code
		);
	}

	return $RC;
}

sub cmd_block {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

	$self->check_options (
		mandatory => {},
		optional  => {},
	) || return $RC;

	if ( $self->get_current_tag_closed ) {
		$self->write ("}\n");
		return $RC;
	}

	$self->write ("{\n");

	return $RC;
}

sub cmd_my {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	my $options      = $self->get_current_tag_options;
	my $options_case = $self->get_current_tag_options_case;
	my $options_list = $self->get_current_tag_options_order;

	if ( not scalar @{$options_list} ) {
		$self->add_tag_message (
			message => "No variables given."
		);
		return $RC;
	}

	# copy all options into the VAR option, so we
	# can use $self->parse_variable_option_hash
	delete $options_case->{var};
	$options->{var} .=
		( defined $options->{var} ? ',' : '' ).
		join (",", map { s/,$//; $_ } values %{$options_case});

	# now parse the 'var' option
	my $var = $self->parse_variable_option_hash (
		option => 'var'
	);
	
	# generate my statement
	my $varlist = join (",", keys %{$var});
	$self->write ("my ($varlist);\n");

	return $RC;
}

sub cmd_htmlquote {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => { 'var' => 1 },
		optional  => { 'htmlvar' => 1, 'my' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	my $var = $self->parse_variable_option (
		option => 'var', types => [ 'scalar' ]
	) || return $RC;

	my $htmlvar;
	if ( defined $options->{htmlvar} ) {
		$htmlvar = $self->parse_variable_option (
			option => 'htmlvar', types => [ 'scalar' ]
		) || return $RC;
	}

	($htmlvar = $var) =~ s/^\$(.*)$/\$html_$1/ if not $htmlvar;

	my $my_cmd = $options->{'my'} ? 'my ' : '';
	
	$self->write (
		"$my_cmd$htmlvar=\$CIPP::request->html_quote($var);\n"
	);

	return $RC;
}

sub cmd_urlencode {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => { 'var'    => 1 },
		optional  => { 'encvar' => 1, 'my' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	my $var = $self->parse_variable_option (
		option => 'var', types => [ 'scalar' ]
	) || return $RC;

	my $encvar;
	if ( defined $options->{encvar} ) {
		$encvar = $self->parse_variable_option (
			option => 'encvar', types => [ 'scalar' ]
		) || return $RC;
	}

	($encvar = $var) =~ s/^\$(.*)$/\$enc_$1/ if not $encvar;

	my $my_cmd = $options->{'my'} ? 'my ' : '';
	
	$self->write (
		"$my_cmd$encvar=\$CIPP::request->url_encode($var);\n"
	);

	return $RC;
}

sub cmd_foreach {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

	if ( $self->get_current_tag_closed ) {
		$self->check_options (
			mandatory => {},
			optional  => {},
		) || return $RC;
		$self->write ("}\n");
		return $RC;
	}

	$self->check_options (
		mandatory => { 'var' => 1, 'list' => 1 },
		optional  => { 'my' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	my $var = $self->parse_variable_option (
		option => 'var', types => [ 'scalar' ]
	) || return $RC;

	$self->write ("my $var;\n") if $options->{'my'};
	$self->write ("foreach $var ($options->{list}) {\n");

	return $RC;
}

sub cmd_textarea {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

	if ( $self->get_current_tag_closed ) {
		$self->pop_context;
		$self->check_options (
			mandatory => {},
			optional  => {},
		) || return $RC;
		$self->write ('}); print "</textarea>\n";'."\n");
		return $RC;
	}

	my $options = $self->get_current_tag_options;

	my $options_text = '';
	my ($par, $val);
	while ( ($par,$val) = each %{$options} ) {
		$par =~ tr/A-Z/a-z/;
		$options_text .= qq[ $par="$val"];
	}

	$self->write (
		qq[print qq{<textarea$options_text>},\$CIPP::request->html_quote (qq{]
	);

	$self->push_context('var_quote');
	
	return $RC;
}

sub cmd_sub {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

	my $data;
	if ( $data = $self->get_current_tag_closed ) {
		$self->check_options (
			mandatory => {},
			optional  => {},
		) || return $RC;

		my $buffer_sref = $self->close_output_buffer;

		$self->write ( $buffer_sref );
		$self->write ("}\n");

		# now a Perl Syntax check for the subroutine
		my $var_decl;
		if ( $data->{import} and @{$data->{import}} ) {
			$var_decl = 'my (';
			$var_decl .= "$_, " for @{$data->{import}};
			$var_decl =~ s/, $//;
			$var_decl .= ");\n";
		}
		$$buffer_sref = "use strict; $var_decl$$buffer_sref";

		$self->perl_error_check ( perl_code_sref => $buffer_sref );
		
		return $RC;
	}

	$self->check_options (
		mandatory => { 'name'   => 1 },
		optional  => { 'import' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	my $name = $options->{name};
	$name = "main::$name" if $name !~ /:/ and
				 not $self->get_state->{module_name};

	if ( $options->{import} ) {
		my $import = $self->parse_variable_option_list (
			option => 'import',
		);
		$RC = $self->RC_BLOCK_TAG (
			import => $import
		);
	}

	$self->write (
		qq[sub $name {\n]
	);

	$self->open_output_buffer;
	
	return $RC;
}

sub cmd_hiddenfields {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => {},
		optional  => { '*' => 1 },
	) || return $RC;

	my $options      = $self->get_current_tag_options;
	my $options_case = $self->get_current_tag_options_case;

	my (@val_list, $par, $val);
	
	# first get variables from PARAMS option
	if ( defined $options->{params} ) {
		my $params = $self->parse_variable_option_hash (
			option => 'params',
			types  => [ 'scalar', 'array' ]
		) || return $RC;

		foreach $par ( keys %{$params} ) {
			$val = $par;
			$par =~ s/^[\$\@]//;
			push @val_list, "$val\t$par";
		}
	}

	# now add explicite options
	while ( ($par,$val) = each %{$options} ) {
		next if $par eq 'params';
		push @val_list, "$val\t".$options_case->{$par};
	}

	# now we have tab delimited entries in @val_list:
	#
	#	idx 0	assigned parameter:
	#		if begins with $ : scalar variable
	#		if begins with @ : array variable
	#		else:              literal string
	#
	# 	idx 1	name of the parameter for the hidden field

	# first generate constant hiddenfields for scalar parameters
	my $item;
	foreach $item (grep /^[^\@]/, @val_list) {
		($val, $par) = split ("\t", $item);
		$par=lc($par);
		$self->write (
		    qq[print qq{].
		    qq[<input type="hidden" name="$par" value="}.].
		    qq[\$CIPP::request->html_field_quote(qq{$val}).qq{"\$CIPP::ee>\\n};\n] );
	}

	# generate dynamic hiddenfield code for arrays
	foreach $item (grep /^\@/, @val_list) {
		($val, $par) = split ("\t", $item);
		$par=lc($par);
		$self->write (
		    qq[{my \$cipp_tmp;\nforeach \$cipp_tmp ($val) {\n].
		    qq[print qq{<input type="hidden" name="$par" ].
		    qq[value="}.\$CIPP::request->html_field_quote(qq{\$cipp_tmp}).].
		    qq[qq{"\$CIPP::ee>\\n};\n].
		    qq[}\n}\n] );
	}

	return $RC;
}

sub cmd_comment {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

	if ( $self->get_current_tag_closed ) {
		$self->pop_context;
		$self->check_options (
			mandatory => {},
			optional  => {},
		) || return $RC;
		return $RC;
	}

	$self->check_options (
		mandatory => {},
		optional  => {},
	) || return $RC;

	$self->push_context('comment');

	return $RC;
}

sub cmd_input {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => {},
		optional  => { '*' => 1 },
	) || return $RC;

	my $code = qq[print qq{<input];

	my $options      = $self->get_current_tag_options;
	my $options_case = $self->get_current_tag_options_case;

	my ($par, $val);
	while ( ($par,$val) = each %{$options} ) {
		if ( $par eq 'value' ) {
			# quote the VALUE option
			$code .= qq[ value="}.\$CIPP::request->html_quote ].
		   		 qq[(qq{$options->{value}}).qq{"];

		} elsif ( $par eq 'src' ) {
			# check whether this image exists and is of correct type
			# (<input type="image" src="...">)
			return $RC if not $self->check_object_type (
				name => $val,
				type => 'cipp-image',
			); 

			my $object_url = $self->get_object_url ( name => $val );
			$code .= qq[ src="$object_url"];

		} elsif ( $par ne 'sticky' ) {
			# other parameters are taken as is
			$par =~ tr/A-Z/a-z/;
			$code .= qq[ $par="$val"];
		}
	}

	my $sticky_var = $options->{sticky};

	if ( $sticky_var ) {
		if ( $options->{type} =~ /^radio$/i and 
		     $options->{name} !~ /\$/ and not $options->{checked} ) {
			# sticky feature for type="radio"
	     		if ( $sticky_var == 1 ) {
				$sticky_var = '$'.$options->{name};
			}
			$code .= qq[},($sticky_var eq qq{$options->{value}} ].
				 qq[? " checked\$CIPP::ee>\\n":"\$CIPP::ee>\\n");\n];

		} elsif ( $options->{type} =~ /^checkbox$/i and
		          $options->{name} !~ /\$/ and not $options->{checked} ) {
			# sticky feature for type="checkbox"
			$sticky_var = '@'.$options->{name} if $sticky_var == 1;
			$code .= qq[},(grep /^$options->{value}\$/,$sticky_var) ].
				 qq[? " checked\$CIPP::ee>\\n":"\$CIPP::ee>\\n";\n];
		}
	} else {
		$code .= "\$CIPP::ee>\\n};\n";
	}

	$self->write($code);

	return $RC;
}

sub cmd_savefile {			# deprecated. replaced by <?FETCHUPLOAD>
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => { 'var' => 1, 'filename' => 1 },
		optional  => { 'throw' => 1, 'symbolic' => 1 }
	) || return $RC;

	my $options = $self->get_current_tag_options;

	$options->{var} =~ s/^\$//;

	$options->{throw} ||= "savefile";

	my $formvar;
	if ( ! defined $options->{symbolic} ) {
		$formvar = "'$options->{var}'";
	} else {
		$formvar = "\$$options->{var}";
	}

	my $code = "{\nno strict;\n";
	$code .= "my \$_cipp_filehandle = CGI::param($formvar);\n";
	$code .= "die '$options->{throw}\tFile upload variable not set.'\n ";
	$code .= "if not \$_cipp_filehandle;\n";
	$code .= "open (cipp_SAVE_FILE, \"> $options->{filename}\")\n";
	$code .= "or die \"$options->{throw}\tCan't open file '$options->{filename}' ".
		 "for writing\";\n";
	$code .= "binmode cipp_SAVE_FILE;\n";
	$code .= "binmode \$_cipp_filehandle;\n";
	$code .= "my (\$_cipp_filebuf, \$_cipp_read_result);\n";
	$code .= "while (\$_cipp_read_result = read \$_cipp_filehandle, ".
		 "\$_cipp_filebuf, 1024) {\n";
	$code .= "print cipp_SAVE_FILE \$_cipp_filebuf ";
	$code .= "or die \"$options->{throw}\tError writing to output file.\";\n";
	$code .= "}\n";
	$code .= "close cipp_SAVE_FILE;\n";
	$code .= "(!defined \$_cipp_read_result) and \n";
	$code .= "die \"$options->{throw}\tError reading the upload file. ".
	         "Did you set ENCTYPE=multipart/form-data?\";\n";
	$code .= "close \$_cipp_filehandle;\n";
	$code .= "}\n";
	
	$self->write ($code);

	return 1;
}

sub cmd_fetchupload {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => { 'var' => 1, 'filename' => 1 },
		optional  => { 'throw' => 1 }
	) || return $RC;

	my $options = $self->get_current_tag_options;
	$options->{throw} ||= "fetchupload";

	my $var = $self->parse_variable_option (
		option => 'var',
		types => [ 'scalar' ]
	) || return $RC;

	$self->writef (
		'$CIPP::request->fetch_upload ('."\n".
		'  filename => "%s",'."\n".
		'  fh       => %s,'."\n".
		'  throw    => "%s"'."\n".
		');'."\n",
		
		$options->{filename},
		$var,
		$options->{throw},
	);

	return $RC;
}

sub cmd_interface {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	if ( defined $self->get_state->{interface_occured} ) {
		$self->add_tag_message (
			message => 'Multiple instances of '.
				   '<?INTERFACE> are forbidden.'
		);
		return $RC;
	}

	if ( $self->get_object_type ne 'cipp' ) {
		$self->add_tag_message (
			message => "Illegal use of the <?INTERFACE> command. This is not a CIPP program."
		);
		return $RC;
	}

	$self->get_state->{interface_occured} = 1;

	$self->check_options (
		mandatory => {},
		optional  => { 'input' => 1, 'optional' => 1 },
	) || return $RC;

	my $mandatory = $self->parse_variable_option_hash (
		option => 'input'
	);

	my $optional  = $self->parse_variable_option_hash (
		option => 'optional'
	);

	return $RC if not keys %{$mandatory} and not keys %{$optional};

	$self->write (
		"my (".
		join (", ", keys %{$mandatory}, keys %{$optional}).
		");\n\n"
	);
	
	$self->write (
		'$CIPP::request->read_input_parameter ('."\n".
		"  mandatory => {\n"
	);
	
	my ($name, $var, @clash);
	while ( ($var, $name) = each %{$mandatory} ) {
		if ( defined $optional->{$var} ) {
			push @clash, $var;
			next;
		}
		$self->write (
			"    '$name' => \\$var,\n"
		);
	}
	
	$self->write (
		"  },\n".
		"  optional => {\n"
	);

	while ( ($var, $name) = each %{$optional} ) {
		$self->write (
			"    '$name' => \\$var,\n"
		);
	}
	$self->write (
		"  },\n".
		");\n\n"
	);

	$self->add_tag_message (
		message => "INPUT/OPTIONAL variable clash: ".
			    join(', ', @clash)
	) if @clash;


	return $RC;
}

sub cmd_use {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => { 'name' => 1 },
		optional  => {},
	) || return $RC;

	my $options = $self->get_current_tag_options;

	$self->writef(
		'use %s;'."\n",
		$options->{name}
	);

	$self->add_used_module (
		name => $options->{name},
	);

	return $RC;
}

sub cmd_require {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => { 'name' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	$self->write(
		qq[{ my \$_cipp_mod = "$options->{name}";\n].
		qq[\$_cipp_mod =~ s!::!/!og;\n].
		qq[\$_cipp_mod .= ".pm";\n].
		qq[require \$_cipp_mod;}\n]
	);

	if ( $options->{name} !~ /\$/ ) {
		$self->add_used_module (
			name => $options->{name},
		);
	}

	return $RC;
}

sub cmd_module {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

	if ( $self->get_current_tag_closed ) {
		$self->check_options (
			mandatory => {},
			optional  => {},
		) || return $RC;
		return $RC;
	}

	$self->check_options (
		mandatory => { 'name' => 1 },
		optional  => { 'isa'  => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	if ( $self->get_state->{module_name} ) {
		$self->add_tag_message (
			message => "Mulitiple module declaration: ".
				   $self->get_state->{module_name}
		);
		return $RC;
	}
	
	$self->get_state->{module_name} = $options->{name};

	$self->write("package $options->{name};\n\n");

	if ( $options->{isa} ) {
		my $isa = $options->{isa};
		$isa =~ s/,/ /g;
		$self->write (
			'@'.$options->{name}."::ISA = qw( $isa );\n"
		);
	}

	my @isa = split (/\s*,\s*/, $options->{isa});
	foreach my $isa ( @isa ) {
		$self->write(
			qq[\n{ my \$_cipp_mod = "$isa";\n].
			qq[\$_cipp_mod =~ s!::!/!og;\n].
			qq[\$_cipp_mod .= ".pm";\n].
			qq[require \$_cipp_mod;}\n\n]
		);
	}

	return $RC;
}

sub cmd_config {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => { 'name' => 1 },
		optional  => { 'nocache' => 1, 'runtime' => 1, 'throw' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	my $name = $options->{name};
	
	if ( not $options->{runtime} ) {
		return $RC if not $self->check_object_type (
			name => $name,
			type => 'cipp-config',
		);

		$self->add_used_object (
			name => $name,
			type => 'cipp-config'
		);
	}

	my $throw = $options->{throw};
	$throw ||= 'config';

	my $require;

	$self->writef (
		'$CIPP::request->read_config ('."\n".
		'    name  => "%s",'."\n".
		'    throw => "%s"'."\n".
		');'."\n",
		$name,
		$throw
	);

	return $RC;
}

sub cmd_form {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

	if ( $self->get_current_tag_closed ) {
		$self->check_options (
			mandatory => {},
			optional  => {},
		) || return $RC;

		$self->write ('print "</form>\n";'."\n");

		return $RC;
	}

	$self->check_options (
		mandatory => { 'action' => 1 },
		optional  => { '*' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	my $method;
	if ( defined $options->{method} ) {
		$method = $options->{method};
		delete $options->{method};
	} else {
		$method = "POST";
	}

	my $name = $options->{action};
	delete $options->{action};

	my $anchor;
	if ( $name =~ /#/ ) {
		($name, $anchor) = split ("#", $name, 2);
		$anchor = "#$anchor";
	}

	return $RC if not $self->check_object_type (
		name => $name,
		type => 'cipp',
	);

	my $object_url = $self->get_object_url ( name => $name );

	my $code = qq[print qq{<form action="$object_url$anchor" ].
		   qq[method="$method"];

	my ($par, $val);
	while ( ($par,$val) = each %{$options} ) {
		$par =~ tr/a-z/A-Z/;
		$code .= qq[ $par="$val"];
	}

	$code .= ">\\n};\n";

	$self->write($code);

	return $RC;
}

sub cmd_a {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

	if ( $self->get_current_tag_closed ) {
		$self->pop_context;
		$self->check_options (
			mandatory => {},
			optional  => {},
		) || return $RC;

		$self->write ('print qq[</a>\n];'."\n");

		return $RC;
	}

	$self->check_options (
		mandatory => { 'href' => 1 },
		optional  => { '*' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	my $name = $options->{href};
	delete $options->{href};

	my $anchor;
	if ( $name =~ /#/ ) {
		($name, $anchor) = split ("#", $name, 2);
	}

	return $RC if not $self->object_exists (
		name => $name,
		add_message_if_not => 1
	);

	my $object_url = $self->get_object_url (
		name => $name,
		add_message_if_has_no => 1
	);

	return $RC if not defined $object_url;

	my $code;
	if ( defined $anchor ) {
		$code = qq[print qq{<a href="$object_url#$anchor"];
	} else {
		$code = qq[print qq{<a href="$object_url"];
	}

	my ($par, $val);
	while ( ($par,$val) = each %{$options} ) {
		$par =~ tr/a-z/A-Z/;
		$code .= qq[ $par="$val"];
	}

	$code .= ">};\n";

	$self->write($code);

	$self->push_context ('html_exact');

	return $RC;
}

sub cmd_frame {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	if ( $self->get_current_tag_closed ) {
		$self->check_options (
			mandatory => {},
			optional  => {},
		) || return $RC;

		return $RC;
	}

	$self->check_options (
		mandatory => { 'src' => 1 },
		optional  => { '*' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	my $name = delete $options->{src};

	my $anchor;
	if ( $name =~ /#/ ) {
		($name, $anchor) = split ("#", $name, 2);
	}

	return $RC if not $self->object_exists (
		name => $name,
		add_message_if_not => 1
	);

	my $object_url = $self->get_object_url (
		name => $name,
		add_message_if_has_no => 1
	);

	return $RC if not defined $object_url;

	my $code;
	if ( defined $anchor ) {
		$code = qq[print qq{<frame src="$object_url#$anchor"];
	} else {
		$code = qq[print qq{<frame src="$object_url"];
	}

	my ($par, $val);
	while ( ($par,$val) = each %{$options} ) {
		$par =~ tr/a-z/A-Z/;
		$code .= qq[ $par="$val"];
	}

	$code .= "\$CIPP::ee>};\n";

	$self->write($code);

	return $RC;
}

sub cmd_geturl {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => { 'name' => 1 },
		optional  => { '*'    => 1 },
	) || return $RC;

	my $options      = $self->get_current_tag_options;
	my $options_case = $self->get_current_tag_options_case;

	# mangle URLVAR and VAR options. URLVAR is depreciated.
	
	if ( $options->{urlvar} ) {
		if ( $options->{var} ) {
			$self->add_tag_message (
				message => "Using VAR and URLVAR option ".
					   "is forbidden. URLVAR is ".
					   "deprecated."
			);
			return $RC;
		}
		$options->{var} = $options->{urlvar};
		delete $options->{urlvar};
	}

	if ( not $options->{var} ) {
		$self->add_tag_message (
			message => "VAR option missing."
		);
		return $RC;
	}

	my $var = $self->parse_variable_option (
		option => 'var',
		types => [ 'scalar' ]
	);
	delete $options->{var};


	my $name      = delete $options->{name};
	my $runtime   = delete $options->{runtime};
	my $throw     = delete $options->{throw} || 'geturl';
	my $path_info = delete $options->{pathinfo};
	my $my_cmd    = delete $options->{my};
	$my_cmd = $my_cmd ? 'my ' : '';
	
	return $RC if not $runtime and not $self->object_exists (
		name => $name,
		add_message_if_not => 1
	);

	my $object_url;

	if ( not $runtime ) {
		$object_url = $self->get_object_url (
			name => $name,
			add_message_if_has_no => 1
		);
		return $RC if not defined $object_url;

		$self->write ("${my_cmd}$var=qq{$object_url}\n");

	} else {
		$self->write (
			qq{${my_cmd}$var=\$CIPP::request->get_object_url ( name => "$name", throw => "$throw")}
		);
	}

	# add PATHINFO, if requested
	$self->write (qq[.qq{/$path_info}]) if $path_info;

	# now add parameters to the url
	my @val_list;
	my ($par, $val);

	# get values from PARAMS

	if ( defined $options->{params} ) {
		my $params = $self->parse_variable_option_hash (
			option => 'params',
			types  => [ 'scalar', 'array' ]
		) || return $RC;

		foreach $par ( keys %{$params} ) {
			$val = $par;
			$par =~ s/^[\$\@]//;
			push @val_list, "$val\t$par";
		}
	}

	# now add explicite options
	while ( ($par,$val) = each %{$options} ) {
		next if $par eq 'params';
		push @val_list, "$val\t".$options_case->{$par};
	}

	# now we have tab delimited entries in @val_list:
	#
	#	idx 0	assigned parameter:
	#		if begins with $ : scalar variable
	#		if begins with @ : array variable
	#		else:              literal string
	#
	# 	idx 1	name of the parameter for the hidden field

	if ( @val_list ) {
		return $RC if not $runtime and not $self->check_object_type (
			name => $name,
			type => 'cipp',
			message => "Illegal attempt to add parameters ".
				   "to a non CGI URL."
		);

		# process scalar parameters first.
		my $delimiter = "?";
		my $item;

		foreach $item (grep /^[^\@]/, @val_list) {
			($val, $par) = split ("\t", $item);
			$par=lc($par);
			$self->write (
			    qq{.qq{${delimiter}$par=}.}.
			    qq{\$CIPP::request->url_encode("$val")} );

			$delimiter = $self->get_url_par_delimiter if $delimiter eq '?';
		}
		$self->write ( ";\n" );

		# now array parameters
		foreach $item (grep /^\@/, @val_list) {
			($val, $par) = split ("\t", $item);
			$par=lc($par);
			$self->write (
				qq[{my \$_cipp_tmp;\nforeach \$_cipp_tmp ($val) {\n].
				qq[$var.="${delimiter}$par=".].
				qq[\$CIPP::request->url_encode(\$_cipp_tmp);\n].
				qq[}\n}\n] );

			$delimiter = $self->get_url_par_delimiter if $delimiter eq '?';
		}
	}

	$self->write (";\n");

	return $RC;
}

sub cmd_img {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => { 'src' => 1 },
		optional  => { '*' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	my $name   = delete $options->{src};
	my $nosize = delete $options->{nosize};

	my $object_url = $self->get_object_url (
		name => $name,
		add_message_if_has_no => 1
	);
	
	return $RC if not defined $object_url;

	my $code = qq[print qq{<img src="$object_url"];

	if ( not defined $nosize and
	     not defined $options->{width} and
	     not defined $options->{height} ) {
		my $filename = $self->get_object_filename ( name => $name );
		last if not $filename;
		eval "use Image::Size qw()";
		last if $@;
		eval {
			($options->{width},
			 $options->{height})
			 	= Image::Size::imgsize ($filename);
		};
	}

	my ($par, $val);
	while ( ($par,$val) = each %{$options} ) {
		$code .= qq[ $par="$val"];
	}

	$code .= "\$CIPP::ee>};\n";

	$self->write($code);

	return $RC;
}

sub cmd_select {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

	if ( $self->get_current_tag_closed ) {
		$self->get_state->{select_tag_options} = undef;
		$self->check_options (
			mandatory => {},
			optional  => {},
		) || return $RC;
		$self->write(
			qq{print "</select>\\n";}
		);
		return $RC;
	}

	if ( $self->get_state->{select_tag_options} ) {
		$self->add_tag_message (
			message => "Nesting forbidden."
		);
		return $RC;
	}

	$self->check_options (
		mandatory => { 'name' => 1 },
		optional  => { '*' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	$self->get_state->{select_tag_options} = $options;

	my $code = qq[print qq{<select];

	my ($par, $val);
	while ( ($par,$val) = each %{$options} ) {
		if ( $par ne 'sticky' ) {
			$code .= qq[ $par="$val"];
		}
	}
	$code .= ">\\n};\n";

	$self->write($code);

	return $self->RC_BLOCK_TAG (%{$options});
}

sub cmd_option {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

	if ( $self->get_current_tag_closed ) {
		$self->check_options (
			mandatory => {},
			optional  => {},
		) || return $RC;
		$self->pop_context;
		$self->write(
			qq[^),"</option>\\n";]
		);
		return $RC;
	}

	my $select_options = $self->get_state->{select_tag_options};

	if ( not $select_options ) {
		$self->add_tag_message (
			message => "Missing <?SELECT> tag."
		);
		return $RC;
	}

	$self->check_options (
		mandatory => {},
		optional  => { '*' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	my $code = qq[print qq{<option];

	my ($par, $val);
	while ( ($par,$val) = each %{$options} ) {
		if ( $par eq 'value' ) {
			$code .= qq[ value="}.\$CIPP::request->html_field_quote].
		   		 qq[(qq{$options->{value}}).qq{"];
		} else {
			$par =~ tr/A-Z/a-z/;
			if ( $par ne 'sticky' ) {
				$code .= qq[ $par="$val"];
			}
		}
	}

	my $sticky_var = $select_options->{sticky} || $options->{sticky};

	if ( $sticky_var ) {
		if ( $options->{name} !~ /\$/ and not $options->{selected} and
		     $select_options->{multiple} ) {
			if ( $sticky_var == 1 ) {
				$sticky_var = '@'.$select_options->{name};
			}
			$code .= qq[},(grep /^$options->{value}\$/,$sticky_var) ? " selected>":">",\n];
		} elsif ( $options->{name} !~ /\$/ and not $options->{selected} ) {
			if ( $sticky_var == 1 ) {
				$sticky_var = '$'.$select_options->{name};
			}
			$code .= qq[},($sticky_var eq qq{$options->{value}}) ? " selected>":">",\n];
		}
	} else {
		$code .= ">},\n";
	}

	$self->write($code);
	$self->write (
		qq[\$CIPP::request->html_quote (qq^]
	);

	$self->push_context('var_quote');

	return $RC;
}

sub cmd_lib {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => { 'name' => 1 },
		optional  => {},
	) || return $RC;

	my $options = $self->get_current_tag_options;

	$self->write("use $options->{name};\n");

	return $RC;
}

sub cmd_getparam {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => { 'name' => 1 },
		optional  => { 'my' => 1, 'var' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	my $var;
	if ( not defined $options->{var} ) {
		$var = '$'.$options->{name};
		$options->{'my'} = 1;
	} else {
		$var = $self->parse_variable_option (
			option => "var"
		);
	}

	my $my = $options->{'my'} ? 'my' : '';

	$self->write("$my $var = \$CIPP::request->param(\"$options->{name}\");\n");

	return $RC;
}

sub cmd_getparamlist {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => { 'var' => 1 },
		optional  => { 'my' => 1 },
	) || return $RC;

	my $var = $self->parse_variable_option (
			option => "var",
			types => [ 'array' ]
	) || return $RC;

	my $options = $self->get_current_tag_options;

	my $my = $options->{'my'} ? 'my' : '';

	$self->write("$my $var = \$CIPP::request->param();\n");

	return $RC;
}

sub cmd_autoprint {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => {},
		optional  => { 'off' => 1, 'on' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	if ( $options->{on} and $options->{off} ) {
		$self->add_tag_message (
			message => 'Illegal combination of ON and OFF.'
		);
		return $RC;
	}

	if ( not $options->{on} and not $options->{off} ) {
		$self->add_tag_message (
			message => 'Neither ON nor OFF specified.'
		);
		return $RC;
	}

	$self->get_state->{autoprint} = 0 if $options->{off};
	$self->get_state->{autoprint} = 1 if $options->{on};
	
	return $RC;
}

sub cmd_exit {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => {},
		optional  => {},
	) || return $RC;

	$self->write(
		"die '_cipp_exit_command';\n"
	);

	return $RC;
}

sub cmd_profile {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

	if ( $self->get_current_tag_closed ) {
		$self->check_options (
			mandatory => {},
			optional  => {},
		) || return $RC;

		$self->write (
			'$CIPP::request->stop_profiling;'."\n"
		);

		return $RC;
	}

	$self->check_options (
		mandatory => {},
		optional  => {
			'deep'       => 1, 'name'      => 1,
			'filename'   => 1, 'filter'    => 1,
			'scaleunit'  => 1,
		},
	) || return $RC;

	my $options = $self->get_current_tag_options;

	my $deep        = $options->{deep} ? 1 : 0;
	my $name        = $options->{name} || 'unnamed';
	my $filename    = $options->{filename};
 
	my $filter      = $options->{filter}    || 0;
	my $scale_unit  = $options->{scaleunit} || 0.2;
 
	$self->write (
		'$CIPP::request->start_profiling ('."\n".
		"    deep        => $deep,\n".
		"    name        => qq{$name},\n".
		"    filename    => qq{$filename},\n".
		"    filter      => $filter,\n".
		"    scale_unit  => $scale_unit\n".
		");\n"
	);

	return $RC;
}

sub cmd_profile_old {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => {},
		optional  => { 'on' => 1, 'off' => 1, 'deep' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	my $deep = '';
	if ( $options->{on} ) {
		if ( $options->{deep} ) {
			$self->get_state->{profile} = "deep";
			$deep = " DEEP";
		} else {
			$self->get_state->{profile} = "on";
		}
	}
	
	if ( $options->{off} ) {
		$self->get_state->{profile} = undef;
		$self->write(
			'printf STDERR "PROFILE %5d STOP'.$deep.'\n",$$;'
		);
	} else {
		$self->write(
			"require 'Time/HiRes.pm';\n",
			'printf STDERR "\nPROFILE %5d START'.$deep.'\n",$$;'
		);
	}

	return $RC;
}

sub get_profile_start_code {
	my $self = shift; $self->trace_in;
	
	return	'my ($_cipp_t1, $_cipp_t2);'."\n".
		'$_cipp_t1 = Time::HiRes::time();'."\n";
}

sub get_profile_end_code {
	my $self = shift; $self->trace_in;
	
	my ($what, $detail) = @_;

	$what   = "q[$what]";
	$detail = "q[$detail]";
	
	return	'$_cipp_t2 = Time::HiRes::time();'."\n".
		'printf STDERR "PROFILE %5d %-10s %-40s %2.4f\n", '.
		'$$, '.$what.','.$detail.', $_cipp_t2-$_cipp_t1;'."\n";
}

sub get_dbh_code {
	my $self = shift; $self->trace_in;
	
	my $options = $self->get_current_tag_options;

	if ( $options->{dbh} and $options->{db} ) {
		$self->add_tag_message (
			message => "Illegal combination of DB and DBH."
		);
		return;
	}

	if ( $options->{dbh} ) {
                #-- trivial, if DBH option was set
		my $var = $self->parse_variable_option (
			option => 'dbh',
			types => [ 'scalar' ]
		) || return;
		return $var;

	}
        elsif ( $options->{db} =~ /\$/ ) {
                #-- Obviously a variable database name, then this is
                #-- resolved at runtime (need to normalize the name
                #-- on-the-fly i.e. remove the PROJECT DOT from the
                #-- variable's content).
                return   '$CIPP::request->dbh(do{my $__db='
                       . $options->{db}
                       . ';$__db=~s/^[^.]+\.//;$__db})';
                
        }
        else {
                #-- otherwise it's a static new.spirit dotted object name
		my $db = $options->{db};
		if ( $db ) {
			$self->check_object_type (
				name    => $db,
				type    => 'cipp-db',
				message => "$db is not a database configuration object"
			) || return;

			# we normalize here, because the identifier for
			# the default db __default must not be normalized
			# by the ->add_used_object method call beyond.
			# so we can call it with normalized => 1.
			$db =~ s/^[^.]+\.//;
#			$db = $self->get_normalized_object_name ( name => $options->{db} );
		} else {
			$db = "default";
		}

		$self->add_used_object (
			name => ($db eq 'default' ? '__default' : $db),
			type => 'cipp-db',
			normalized => 1
		);

		return '$CIPP::request->dbh("'.$db.'")';
	}
}

sub cmd_getdbhandle {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => { 'var' => 1 },
		optional  => { 'my'  => 1, 'db' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	my $var = $self->parse_variable_option (
		option => 'var',
		types  => [ 'scalar' ]
	) || return $RC;

	my $dbh_code = $self->get_dbh_code;

	my $my_cmd = $options->{'my'} ? 'my ' : '';

	if ( $self->get_state->{profile} ) {
		$self->write ( $self->get_profile_start_code );
	}

	$self->write (
		qq{${my_cmd}$var = $dbh_code;\n}
	);

	if ( $self->get_state->{profile} ) {
		$self->write (
			$self->get_profile_end_code (
				"CONNECT", "Database: ".($options->{db}||'default')
			)
		);
	}

	return $RC;
}

sub cmd_switchdb {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

	if ( $self->get_current_tag_closed ) {
		$self->check_options (
			mandatory => {},
			optional  => {},
		) || return $RC;

		$self->writef (
			'};'."\n".
			'$CIPP::request->unswitch_db;'."\n".
			'die $@ if $@;'."\n"
		);
		
		return $RC;
	}

	$self->check_options (
		optional  => { 'dbh' => 1, 'db' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	my $dbh_code = $self->get_dbh_code;

	$self->write (
		qq[eval {\n].
		qq[\$CIPP::request->switch_db ( dbh => $dbh_code );\n]
	);

	return $RC;
}

sub cmd_autocommit {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => {},
		optional  => { 'on' => 1, 'off' => 1, 'db' => 1,
			       'dbh' => 1, 'throw' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	my $dbh_code = $self->get_dbh_code;

	if ( not defined $options->{on} and not defined $options->{off} ) {
		$self->add_tag_message (
			message => "Neither ON nor OFF option set."
		);
		return $RC;
	}

	if ( defined $options->{on} and defined $options->{off} ) {
		$self->add_tag_message (
			message => "Illegal combination of ON and OFF options."
		);
		return $RC;
	}

	my $status = defined $options->{on} ? 1 : 0;
	my $throw  = $options->{throw} || 'autocommit';

	$self->writef (
		'$CIPP::request->set_throw (qq{%s});'."\n",
		$throw
	);

	if ( $status ) {
		$self->writef (
			'die qq{%s\tAutoCommit already on} if %s->{AutoCommit};'."\n",
			$throw,
			$dbh_code
		);
	} else {
		$self->writef (
			'die qq{%s\tAutoCommit already off} if not %s->{AutoCommit};'."\n",
			$throw,
			$dbh_code
		);
	}

	$self->write ("$dbh_code\->{AutoCommit} = $status;\n");
	

	return $RC;
}

sub cmd_commit {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => {},
		optional  => { 'db' => 1, 'dbh' => 1, 'throw' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	my $dbh_code = $self->get_dbh_code;
	my $throw  = $options->{throw} || 'commit';

	$self->writef (
		'$CIPP::request->set_throw (qq{%s});'."\n",
		$throw
	);

	$self->writef (
		'die qq{%s\tCommit used, but AutoCommit is on} if %s->{AutoCommit};'."\n",
		$throw,
		$dbh_code
	);

	$self->write (
		"$dbh_code\->commit;\n"
	);

	return $RC;
}

sub cmd_rollback {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => {},
		optional  => { 'db' => 1, 'dbh' => 1, 'throw' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	my $dbh_code = $self->get_dbh_code;
	my $throw  = $options->{throw} || 'rollback';

	$self->writef (
		'$CIPP::request->set_throw (qq{%s});'."\n",
		$throw
	);

	$self->writef (
		'die qq{%s\tRollback used, but AutoCommit is on} if %s->{AutoCommit};'."\n",
		$throw,
		$dbh_code
	);

	$self->write (
		"$dbh_code\->rollback;\n"
	);

	return $RC;
}

sub cmd_dbquote {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => { 'var' => 1 },
		optional  => { 'dbvar' => 1, 'dbh' => 1, 'db' => 1, 'my' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	my $my_cmd = $options->{'my'} ? 'my ' : '';
	my $dbh_code = $self->get_dbh_code;

	my $var = $self->parse_variable_option (
		option => 'var',
		types  => [ 'scalar' ]
	) || return $RC;

	my $dbvar = $self->parse_variable_option (
		option => 'dbvar',
		types  => [ 'scalar' ]
	);

	($dbvar = $var) =~ s/^\$/\$db_/ if not $dbvar;

	$self->writef (
		'%s%s = %s->quote(%s);'."\n",
		$my_cmd,
		$dbvar,
		$dbh_code,
		$var
	);

	return $RC;
}

sub cmd_sql {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

	my $data;
	if ( $data = $self->get_current_tag_closed ) {
		$self->check_options (
			mandatory => {},
			optional  => {},
		) || return $RC;

		return $RC if $data->{type} eq 'do';
		
		$self->writef (
			"    }\n".
			'    $_cipp_sth->finish;'."\n".
			'    $CIPP::request->sql_select_finished;'."\n".
			'}'."\n"
		);
		
		return $RC;
	}

	$self->check_options (
		mandatory => {
			sql => 1
		},
		optional => {
			db 	 => 1,  dbh => 1,     cond => 1,
			var	 => 1,  params => 1,  result => 1,
			throw	 => 1,  maxrows => 1, winstart => 1,
			winsize	 => 1,  my => 1,      profile => 1,
		} 
	) || return $RC;

	my $options = $self->get_current_tag_options;

	if ( defined $options->{winstart} ^ defined $options->{winsize} ) {
		$self->add_tag_message (
			message => 'WINSTART without WINSIZE or vice versa.'
		);
		return $RC;
	}

	if ( defined $options->{winstart} and defined $options->{maxrows} ) {
		$self->add_tag_message (
			message => 'Illegal combination of WINSTART and MAXROWS.'
		);
		return $RC;
	}

	my $dbh_code = $self->get_dbh_code;

	my $var_lref = $self->parse_variable_option_list (
		option => 'var',
		types => [ 'scalar' ]
	);

	my $result_var = $self->parse_variable_option (
		option => 'result',
		types => [ 'scalar' ]
	);
	
	my $sql      = $options->{sql};
	my $throw    = $options->{throw} || "sql";

	my $maxrows  = $options->{maxrows};
	my $winstart = $options->{winstart};
	my $winsize  = $options->{winsize};
	my $my_cmd   = $options->{'my'} ? 'my ' : '';

	$sql =~ s/;\s*$//;
	$sql =~ s/^\s+//;
	$sql =~ s/\s+$//;

	my $params_code = "";
	$params_code = "$options->{params}" if $options->{params};

	my $profile = $options->{profile} || "sql";

	if ( $options->{var} ) {
		# we assume a SELECT statement which is fetching data
		my $var_list = join(",",@{$var_lref});
		
		# declare variables, if neccessary
		$self->write ( "my ($var_list);\n" ) if $my_cmd;

                # prepare statement
                $self->writef (
                        '{'."\n".
                        '    my $_cipp_sth = $CIPP::request->sql_select ('."\n".
			'        %s, qq{%s}, [%s], qq{%s}, qq{%s}'."\n".
			'    );'."\n".
                        '    $_cipp_sth->execute(%s);'."\n",
                        $dbh_code,
                        $sql,
                        $params_code,
			$throw,
			$profile
                );

                # build list of references for binding fetch data
                # (dynamically extend or shrink list if column count
                #  of the result set doesn't match - for backward
                #  compatability)
                $self->writef (
                        '    my $_cipp_col_cnt  = $_cipp_sth->{NUM_OF_FIELDS};'."\n".
                        '    my @_cipp_col_refs = \(%s);'."\n".
                        '    while ( @_cipp_col_refs < $_cipp_col_cnt ) {'."\n".
                        '        my $_cipp_dummy;'."\n".
                        '        push @_cipp_col_refs, \$_cipp_dummy;'."\n".
                        '    }'."\n".
                        '    splice (@_cipp_col_refs, $_cipp_col_cnt) if @_cipp_col_refs > $_cipp_col_cnt;'."\n",
                        $var_list
                );

                $self->writef (
                        '    $_cipp_sth->bind_columns (undef, @_cipp_col_refs);'."\n".
                        '    my $_cipp_maxrows;'."\n",
                        $throw
                );

		# code for MAXROWS/WINSTART/WINSIZE stuff

		my $maxrows_cond;
		
		if ( defined $maxrows ) {
			$self->writef (
				'    $_cipp_maxrows = %s;'."\n",
				$maxrows
			);
			$maxrows_cond = '$_cipp_maxrows-- > 0 and';
		}

		my $winstart_cmd;

		if ( defined $winstart ) {
			$self->writef (
				'    $_cipp_maxrows = %s+%s;'."\n".
				'    my $_cipp_winstart = %s;'."\n",
				$winstart,
				$winsize,
				$winstart
			);
			$winstart_cmd = 'next if --$_cipp_winstart > 0;'."\n";
			$maxrows_cond = '--$_cipp_maxrows > 0 and';
		}

		if ( $options->{cond} ) {
			$maxrows_cond .= " ($options->{cond}) and";
		}

		# fetch loop

		$self->writef (
		        '    my $_cipp_utf8 = $CIPP::request->get_utf8;'."\n".
			'    SQL: while ( %s $_cipp_sth->fetch ) {'."\n".
			'        if ( $_cipp_utf8 ) {'."\n".
			'            Encode::_utf8_on($_) for (%s);'."\n".
			'        }'."\n",
			$maxrows_cond,
			$var_list
		);

		$self->write ($winstart_cmd) if $winstart_cmd;
		
		return $self->RC_BLOCK_TAG (
			type => 'select',
			throw => $throw,
			profile => $profile,
		);

	} else {
		# we assume a do statement without a result set
		my $result_code = "";
		$result_code = "${my_cmd}$result_var = " if $options->{result};

                $self->writef (
                        '%s$CIPP::request->sql_do ('."\n".
			'    %s, qq{%s}, [%s], qq{%s}, qq{%s}'."\n".
			');'."\n",
			$result_code,
                        $dbh_code,
                        $sql,
                        $params_code,
			$throw,
			$profile
                );

		return $self->RC_BLOCK_TAG (
			type  => 'do',
		);
	}
}

sub cmd_incinterface {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($tag, $options, $options_case, $closed) =
	@par{'tag','options','options_case','closed'};

	my $RC = $self->RC_SINGLE_TAG;

	if ( $self->get_object_type ne 'cipp-inc' ) {
		$self->add_tag_message (
			message =>
				"Illegal use of the <?INCINTERFACE> ".
				"command. This is not a CIPP Include."
		);
		return $RC;
	}

	if ( $self->get_state->{incinterface}->{input} ) {
		$self->add_tag_message (
			message =>
				"Multiple occurence of <?INCINTERFACE>."
		);
		return $RC;
	}

	$self->check_options (
		optional => {
			input		=> 1,
			optional	=> 1,
			output		=> 1,
			noquote		=> 1,
		}
	) or return $RC;

	if ( not defined $options->{input} and
	     not defined $options->{optional} ) {
		$self->get_state->{include_noinput} = 1;
	}

	if ( not defined $options->{output} ) {
		$self->get_state->{include_nooutput} = 1;
	}

	my $input = $self->parse_variable_option_hash (
		option => 'input',
		name2var => 1,
	);
	my $optional = $self->parse_variable_option_hash (
		option => 'optional',
		name2var => 1,
	);
	my $noquote = $self->parse_variable_option_hash (
		option => 'noquote',
		name2var => 1,
	);
	my $output = $self->parse_variable_option_hash (
		option => 'output',
		name2var => 1,
	);

	$self->get_state->{incinterface}->{input}    = $input;
	$self->get_state->{incinterface}->{optional} = $optional;
	$self->get_state->{incinterface}->{noquote}  = $noquote;
	$self->get_state->{incinterface}->{output}   = $output;

	my @unknown;
	foreach my $var ( keys %{$noquote} ) {
		push @unknown, $var if not defined $input->{$var} and
				       not defined $optional->{$var};
	}
	if ( @unknown ) {
		$self->add_tag_message (
			message => "Unknown NOQUOTE variable(s): ".
				   join (", ", @unknown)
		);
	}

	my %double;
	foreach my $var ( keys %{$input}, keys %{$optional} ) {
		$double{$var} = 1 if defined $input->{$var} and
				     defined $optional->{$var};
	}
	if ( %double ) {
		$self->add_tag_message (
			message => "Illegal INPUT and OPTIONAL declared variable(s): ".
				   join (", ", sort keys %double)
		);
	}

	return $RC;
}

sub cmd_include {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($tag, $options, $options_case, $closed) =
	@par{'tag','options','options_case','closed'};

	my $RC = $self->RC_SINGLE_TAG;

	$self->check_options (
		mandatory => { 'name' => 1 },
		optional  => { '*' => 1 },
	) || return $RC;

	my $options = $self->get_current_tag_options;

	my $name = delete $options->{name};
	my $my   = delete $options->{'my'};

	# filter output parameters from $options
	my ($var_output, $var);
	foreach $var ( keys %{$options} ) {
		if ( $var =~ /^[\$\@\%]/ ) {
			# output parameters begin with $, @, % an
			my $var_name = $options->{$var};
			$var_name =~ tr/A-Z/a-z/;
			$var_output->{$var_name} = $var;
			delete $options->{$var};
		}
	}

	# memorize that we use this Include
	$self->add_used_object (
		name => $name,
		type => 'cipp-inc'
	);

	# check filename of Include
	my $filename = $self->get_object_filename ( name => $name );

	if ( not defined $filename ) {
		$self->add_tag_message (
			message => "Include $name not found."
		);
		return $RC;
	}

	if ( not -r $filename ) {
		$self->add_tag_message (
			message =>
				"Include file '$filename' ($name) ".
				"not readable."
		);
		return $RC;
	}

	# first process this Include (cached)
	my $include_parser = $self->create_new_parser (
		object_type    => 'cipp-inc',
		program_name   => $name,
	);

	# check recursive inclusion
	my $norm_name = $include_parser->get_norm_name;
# print "<p>trace=".$self->get_inc_trace." norm_name=$norm_name</p>\n";

	if ( $self->get_inc_trace =~ /:$norm_name:/ ) {
		$self->add_tag_message (
			message =>
				"Illegal recursive inclusion of ".
				"Include '$name' (trace is '".
				$self->get_inc_trace."')",
		);
		return $RC;
	}

	$include_parser->process;

	# copy error messages of this Include into $self
	foreach my $msg ( @{$include_parser->get_messages} ) {
		$self->add_message_object (
			object => $msg
		);
	}

	# check if the actual parameters match the Includes interface
	return $RC if not $self->interface_is_correct (
		include_parser => $include_parser,
		input 	       => $options,
		output	       => $var_output
	);

	# now generate Include subroutine call code
	my $code = '';
	my $interface = $include_parser->read_include_interface_file;

	# get output parameters
	my $output = $var_output;
	if ( $my ) {
		if ( keys %{$output} ) {
			$code .= "my (";
			foreach my $var_name ( values %{$output} ) {
				$code .= "$var_name,";
			}
			$code =~ s/,$//;
			$code .= ");\n";
		}
	}

	# these three files are neccessary for include processing
	my $sub_filename = $self->get_relative_inc_path (
		filename => $include_parser->get_prod_filename
	);

	# call subroutine
	$code .= '$CIPP::request->call_include_subroutine ('."\n";
	$code .= "\tfile         => '$sub_filename',\n";
	$code .= "\tinput        => {\n";
	
	# input parameters
	my $input = $options;
	my $quote_start;
	my $quote_end;
	my $val;

	foreach my $name ( keys %{$input} ) {
		my $var = $interface->{input}->{$name} ||
		          $interface->{optional}->{$name};
		$var =~ /^(.)/;
		my $type = $1;

		if ( $type eq '$' ) {
		     	# scalar parameter
			$quote_start = defined $interface->{noquote}->{$name}
				? '' : 'qq{';
			$quote_end   = defined $interface->{noquote}->{$name}
				? '' : '}';
			$val = $input->{$name};
			$code .= "\t\t$name => $quote_start$val$quote_end,\n";

		} elsif ( $type eq '@' ) {
			# list parameter
			$code .= "\t\t$name => [ $input->{$name} ],\n";

		} elsif ( $type eq '%' ) {
			# hash parameter
			$code .= "\t\t$name => { $input->{$name} },\n";
		}
	}
	
	$code .= "\t},\n";
	
	# tell which output parameters we want
	if ( keys %{$output} ) {
		$code .= "\toutput => {\n";
		my $type;
		foreach my $name ( keys %{$output} ) {
			my $var = $output->{$name};
			$code .= "\t\t\t'$name' => \\$var,\n";
		}
		$code .= "\t\t},\n";
	}
	
	$code .= ");\n";
	
	$self->write ( $code );

	return $RC;
}

sub cmd_httpheader {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($tag, $options, $options_case, $closed) =
	@par{'tag','options','options_case','closed'};

	my $RC = $self->RC_BLOCK_TAG;

	if ( $self->get_current_tag_closed ) {
		$self->pop_context;
		$self->writef (
			"\n".
			"  }; # end of generic exception handler eval\n\n".
			'  # check for an exception (filters <?EXIT> exception)'."\n".
			'  if ( $@ and $@ !~ /_cipp_exit_command/ ) {'."\n".
			'      $CIPP::request->error ('."\n".
			'          message    => $@,'."\n".
			'          httpheader => "%s"'."\n".
			'      );'."\n".
			'      die "_cipp_exit_command";'."\n".
			'  } elsif ( $@ ) {'."\n".
			'      die $@;'."\n".
			'  }'."\n\n",
			$self->get_program_name
		);

		$self->write (
			q[  1;]."\n",
			q[};]."\n",
		);

		my $buffer_sref = $self->close_output_buffer;

		$self->check_options (
			mandatory => {},
			optional  => {},
		) || return $RC;

		my $http_filename = $self->get_http_filename;

		return $RC if not $http_filename;

		my $fh = FileHandle->new;
		if ( open ($fh, ">$http_filename") ) {
			print $fh $$buffer_sref;
			close $fh;
		} else {
			$self->add_tag_message (
				message => "Can't write '$http_filename'"
			);
		}
		
		return $RC;
	}

	# We open the output buffer before error checking,
	# because the closed_tag code above assumes it.
	$self->open_output_buffer;
	$self->push_context('perl');

	# now check for errors
	$self->check_options (
		mandatory => { 'var' => 1 },
		optional  => { 'my'  => 1 },
	) || return $RC;

	my $var = $self->parse_variable_option (
		option => 'var', types => [ 'scalar' ]
	) || return $RC;

	# prevent multiple <?!HTTPHEADER> instances
	if ( $self->get_state->{http_header_occured} ) {
		$self->add_tag_message (
			message => "Only one <?!HTTPHEADER> per program allowed.",
		);
		return $RC;
	}
	
	# only allowed in CGIs and Includes
	if ( $self->get_object_type ne 'cipp' and $self->get_object_type ne 'cipp-inc' ) {
		$self->add_tag_message (
			message => "<?!HTTPHEADER> only allowed inside Programs or Includes",
		);
		return $RC;
	}

	$self->get_state->{http_header_occured} = 1;

	# generate HTTP header code, like an Include subroutine
	$self->writef (
		q[sub {]."\n".
		q[  use strict;]."\n".
		q[  shift;]."\n".
#		q[  my $_cipp_line_nr;]."\n".
		q[  my %s = $CIPP::request->get_http_header;]."\n".
		q[  eval {]."\n",
		$var
	);

	return $RC;
}

sub cmd_lang {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

        if ( $self->get_current_tag_closed ) {
            $self->pop_context;
            $self->write("^)");
            $self->write(";\n") if $self->context eq 'perl';
            return $RC;
        }

	$self->check_options (
		mandatory => {},
		optional  => {},
	) || return $RC;
        
        $self->push_context('var_noquote');
        
        $self->write("CIPP->request->set_locale_messages_lang(qq^");
        
        return $RC;
}

sub cmd_l {
	my $self = shift; $self->trace_in;

	my $RC = $self->RC_BLOCK_TAG;

	if ( $self->get_current_tag_closed ) {
		$self->check_options (
			mandatory => {},
			optional  => {},
		) || return $RC;

		my $buffer_sref      = $self->close_output_buffer;
		my (undef, $options) = $self->pop_context;
		my $context          = $self->context;

                ${$buffer_sref} =~ s/^\s+//gm;
                ${$buffer_sref} =~ s/\s*$/ /gm;
                ${$buffer_sref} =~ s/\s+$//s;
		${$buffer_sref} =~ s/\^/\\^/g;
                ${$buffer_sref} =~ s/\s+/ /gs;

		$options ||= {};

		$self->write("print ") if $context ne 'perl' &&
				          $context !~ /^var/;
		$self->write("^.")     if $context eq 'var_quote';

                my $domain = $self->get_text_domain;

		if ( $options and keys %{$options} ) {
			my $options_hash = "{ ";
			while ( my ($k,$v) = each %{$options} ) {
				$v =~ s/\^/\\^/g;
				$options_hash .= "'$k' => qq^$v^, ";
			}
			$options_hash .= "}";
			$self->writef (
				qq[\$CIPP::request->dgettext("$domain",qq^%s^, $options_hash)],
				${$buffer_sref}
			);
		} else {
			$self->writef (
				qq[\$CIPP::request->dgettext("$domain",qq^%s^)],
				${$buffer_sref}
			);
		}

		$self->write(";\n") if $context ne 'perl' &&
				       $context !~ /^var/;
		$self->write(".qq^") if $context eq 'var_quote';

		return $RC;
	}

	$self->open_output_buffer;

	my %data;
	my $options_case = $self->get_current_tag_options_case;
	my $options      = $self->get_current_tag_options;

	foreach my $opt ( keys %{$options_case} ) {
		$data{$options_case->{$opt}} = $options->{$opt};
	}

	$self->push_context('var_noquote', \%data);

	return $RC;

}

1;
