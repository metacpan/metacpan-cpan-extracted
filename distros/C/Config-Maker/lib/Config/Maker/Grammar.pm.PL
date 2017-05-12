#package Config::Maker::Grammar;

use utf8;
use warnings;
use strict;

use Carp;

use Parse::RecDescent;
use Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/$parser/;

my $grammar = <<'GRAMMAR';

##################################################### COMMON GRAMMAR ##########

identifier : /[[:alpha:]][[:alnum:]_-]*/

literal : /[[:alnum:].!@%*=:\/?_+-]+/
      | /"(?:[^"]|\\.)*"/ { Config::Maker::unquote_double($item[1]); }
      | /'(?:[^']|\\.)*'/ { Config::Maker::unquote_single($item[1]); }
      | <error>

hexint :
	/0x[[:xdigit:]]+/ <commit> { Config::Maker::limit(hex($item[1]), @arg); }
       |
	<error?: Number $item[1] out of range> <reject>

octint :
	/0[0-7]*/ { Config::Maker::limit(oct($item[1]), @arg); }
       |
	<error?: Number $item[1] out of range> <reject>
       
decint :
	/[+-]\d+/ <commit> { Config::Maker::limit(0 + $item[1], @arg); }
       |
	/[1-9]\d*|0/ <commit> { Config::Maker::limit(0 + $item[1], @arg); }
       |
	<error?: Number $item[1] out of range> <reject>

integer : hexint[@arg] | octint[@arg] | decint[@arg] # Order is significant!

real :
	/[+-]?(\d+(\.\d*)?|\.\d+)(e\d+)?/ { 0 + $item[1]; } # Floating-point

eof : /^\Z/

perl_codeblock :
	{ Text::Balanced::extract_codeblock($text, '{}()[]', $skip, $arg[0]); }

####################################################### PATH GRAMMAR ##########

path_whole : <skip: ''> path eof { $item{path}; }

path : '' <skip: ''> metaroot relpath
       {
	   new Config::Maker::Path::Meta(-tail => $item[-1]);
       }
     | '' <skip: ''> metaroot
       {
	   new Config::Maker::Path::Meta();
       }
     | '' <skip: ''> separator relpath
       {
	   new Config::Maker::Path::Root(-tail => $item[-1]);
       }
     | '' <skip: ''> separator
       {
	   new Config::Maker::Path::Root();
       }
     | '' <skip: ''> relpath

relpath : nonglob['**'] ptail
	  {
	      new Config::Maker::Path::AnyPath(@{$item[-1]});
	  }
	| nonglob['..'] ptail
	  {
	      new Config::Maker::Path::Parent(@{$item[-1]});
	  }
	| nonglob['.'] ptail
	  {
	      new Config::Maker::Path::This(@{$item[-1]});
	  }
        | pcomponent ptail
	  {
	      new Config::Maker::Path(%{$item[1]}, @{$item[-1]});
	  }

ptail : separator relpath { [-tail => $item{relpath}] }
      | { []; }

pcomponent : glob ':' glob pcondition(?)
	     {
		 +{
		     -type => $item[1],
		     -value => $item[3],
		     ($item[-1][0] ? (-code => $item[-1][0]) : ())
		 }
	     }
	   | ':' glob pcondition(?)
	     {
		 +{
		     -value => $item[2],
		     ($item[-1][0] ? (-code => $item[-1][0]) : ())
		 }
	     }
	   | glob pcondition(?)
	     {
		 +{
		     -type => $item[1],
		     ($item[-1][0] ? (-code => $item[-1][0]) : ())
		 }
	     }

pcondition : perl_codeblock['()']

glob : /([[:alnum:].@%*=?|_\[\]{}-]|\\.)+/

nonglob : /\Q$arg[0]\E(?![[:alnum:].@%*=?|_\\\[\]{}-])/

metaroot : 'META:'

separator : /\/+/

################################################### TEMPLATE GRAMMAR ##########

template : <skip: ''> directive(s?) eof { $item[2]; }
	 | <error>

# Text outside directives...
directive :
	/([^\[]|\[\[)+/
	{ $item[1] =~ s/\[\[/[/g; $item[1] =~ s/\]\]/\]/g; $item[1]; }

# Comments...
directive : '[#' <commit> /([^#]|#[^\]])*/ '#]' { ''; }
	  | <error?> <reject>

# Simple directives...
directive : '[' <perl_codeblock> <commit> ']'
	    {
		my $code = $item[2];
		sub {
		    print Config::Maker::exe($code);
		}
	    }
	  | <error?> <reject>

optpath : ':' path
        | { new Config::Maker::Path::This(); }

directive : '[+' <commit> <skip: qr/\s*/> identifier optpath '+]'
	    {
		my $key = $item{identifier};
		my $path = $item{optpath};
		sub { print $_->get1($path)->{-$key}; }
	    }
	  | <error?> <reject>

directive : '[<' <skip: ''> <commit> /[^>]+/ '>]' space
	    {
		Config::Maker::Driver->load($item[4]);
	    }
	  | <error?> <reject>

# Block directives...
opener : '[$' <skip: qr/\s*/> "$arg[0]" value[@arg[1..$#arg]] '$]' space
	 { $item[-3]; }

closer : '[$' <skip: qr/\s*/> "end$arg[0]" <skip: ''> /(\s[^\$\[\]]*)?/ '$]' space
       | '[/]' space
       | <error>

directive : opener['map', perlcode => '()'] <commit> directive(s) closer['map']
	    {
		my $expr = $item[1];
		my @parts = @{$item[3]};
		sub {
		    for(Config::Maker::exe($expr)) {
			Config::Maker::Driver::apply(@parts);
		    }
		}
	    }

directive : opener['map', 'path'] <commit> directive(s) closer['map']
            {
		my $path = $item[1];
		my @parts = @{$item[3]};
		sub {
		    for(@{$path->find($_)}) {
			Config::Maker::Driver::apply(@parts);
		    }
		}
	    }
	  | <error?> <reject>

ifrest : opener['elsif', perlcode => '()'] <commit> directive(s) ifrest
	 {
	     my $expr = $item[1];
	     my @parts = @{$item[3]};
	     my $else = $item[4];
	     sub {
		 if(Config::Maker::exe($expr)) {
		     Config::Maker::Driver::apply(@parts);
		 } else {
		     Config::Maker::Driver::apply($else);
		 }
	     }
	 }

ifrest : opener['elsif', pair => ['identifier'], ['path']] <commit>
	 directive(s) ifrest
	 {
	     my ($test, $path) = @{$item[1]};
	     my @parts = @{$item[3]};
	     my $else = $item[4];
	     sub {
		 die "No if test '$test'"
		     unless $Config::Maker::Path::checks{$test};
		 if($Config::Maker::Path::checks{$test}($path)) {
		     Config::Maker::Driver::apply(@parts);
		 } else {
		     Config::Maker::Driver::apply($else);
		 }
	     }
	 }

ifrest : opener['else', 'void'] <commit> directive(s) closer['if']
	 {
	     my @parts = @{$item[3]};
	     sub {
		 Config::Maker::Driver::apply(@parts);
	     }
	 }

ifrest : closer['if'] { ''; }

directive : opener['if', perlcode => '()'] <commit> directive(s) ifrest
	    {
		my $expr = $item[1];
		my @parts = @{$item[3]};
		my $else = $item[4];
		sub {
		    if(Config::Maker::exe($expr)) {
			Config::Maker::Driver::apply(@parts);
		    } else {
			Config::Maker::Driver::apply($else);
		    }
		}
	    }

directive : opener['if', pair => ['identifier'], ['path']] <commit>
	    directive(s) ifrest
	    {
		my ($test, $path) = @{$item[1]};
		my @parts = @{$item[3]};
		my $else = $item[4];
		sub {
		    die "No if test '$test'"
			unless $Config::Maker::Path::checks{$test};
		    if($Config::Maker::Path::checks{$test}($path)) {
			Config::Maker::Driver::apply(@parts);
		    } else {
			Config::Maker::Driver::apply($else);
		    }
		}
	    }

directive : opener['output', 'identifier'] <commit>
	    directive(s) closer['output']
	    {
		my $key = $item[1];
		my @parts = @{$item[3]};
		my ($cache, $output) =
		    $key eq 'all'        ? (1, 1) :
		    $key eq 'both'       ? (1, 1) :
		    $key eq 'only-cache' ? (1, 0) :
		    $key eq 'no-cache'   ? (0, 1) :
		    $key eq 'only-out'   ? (0, 1) :
		    $key eq 'no-out'     ? (1, 0) :
				           die "Bad output option: $key";
		sub {
		    die "output limiting only works when cache is enabled"
			unless UNIVERSAL::isa(select(), 'Config::Maker::Tee');
		    local $Config::Maker::Tee::CACHE = $cache;
		    local $Config::Maker::Tee::OUT = $output;
		    Config::Maker::Driver::apply(@parts);
		}
	    }

space : <skip: ''> /[ \t]*\n?/

##################################################### CONFIG GRAMMAR ##########

# Starting rule. This is the list of all options...
configuration :
	<skip: qr/(\s|#[^\n]*)*/>
	option[$arg[0]](s?)
	eof
	{ $item[2]; }
    |
	<error>

# Signle option. First the identifier is read and appropriate identifier
# obtained. It tells use how to read rest of it.
option :
	block[@arg]
    |
	type[@arg] <commit>
	body[$item[1], $item[1]->body]
	{
	    $item[1]->instantiate($item[3]);
	}
    |
        <error?> <reject>

# Type is an identifier which is registered in appropriate context.
type :	identifier
	<commit>
	{ eval { $arg[0]->get($item[1]); } }
    |
	<error?: $@> <reject>

#############################################################################
# Now to the body. The body is a rule-by-name. We obtained the arguments
# from ->body method of type when we called this from option.

body :	<matchrule: body_$arg[1]>[$arg[0], @arg[2..$#arg]]

block :
	'{' option[$arg[0]](s?) '}'
	{ $item[2]; }
    |
	'<' <skip: ''> /[^>]+/ '>'
	{
	    Config::Maker::Config->read($item[3], $arg[0]);
	}
    | <error>

body_simple :
	value[@{$arg[1]}] ';'
	{ +{ -value => $item[1] }; }
    | <error>

body_anon_group :
	block[$arg[0]]
	{ +{ -children => $item[1] }; }
    | <error>

body_named_group :
	value[@{$arg[1]}]
	block[$arg[0]]
	{ +{
	    -value => $item[1],
	    -children => $item[2],
	}; }
    | <error>

#############################################################################
# And to the values. The values are again a rule-by-name calls. Arguments
# are passed through body_* calls from the ->body method.
# The '' before value is so that skip is skipped now...
value :	'' <matchrule: value_$arg[0]>[@arg[1..$#arg]]

# Special void value:
value_void :

# Complex types:
value_list :
	value[@arg](s)
	{ new Config::Maker::Value::List($item[1]); }
    | <error>

value_zero_list :
	value[@arg](s?)
	{ new Config::Maker::Value::List($item[1]); }
    | <error>

value_nested_list :
	'[' value_nestlist_elem[@arg](s?) ']'
	{ new Config::Maker::Value::List($item[2]); }
    | <error>

value_nestlist_elem :
	'[' value_nestlist_elem[@arg](s?) ']'
	{ new Config::Maker::Value::List($item[2]); }
    |
	<matchrule: value_$arg[0]>[@arg[1..$#arg]]
    | <error>

value_pair :
	<matchrule: value_$arg[0][0]>[$arg[0][1..$#{$arg[0]}]]
	# FIXME - space-separated...
	<matchrule: value_$arg[1][0]>[$arg[1][1..$#{$arg[1]}]]
	{ new Config::Maker::Value::List [$item[1], $item[-1]]; }
    | <error>

# Semi-complex types:
value_perlcode : perl_codeblock[@arg]
    | <error>

# Simple types:

value_string : literal
    | <error>

value_identifier : identifier
    | <error>

value_dns_name :
	/[a-zA-Z0-9-]+/
    | <error>

value_dns_zone :
	/([a-zA-Z0-9-]+\.)*[a-zA-Z0-9-]+\.?/
    | <error>

byte : decint[0,255]

value_ipv4 :
	<skip: ''> <leftop: byte '.' byte>
	{ @{$item[2]} == 4 ? join '.', @{$item[2]} : undef; }
    | <error>

value_port : decint[0,65535]
    | <error>

value_ipv4_port :
	<skip: ''> value_ipv4 ':' value_port
	{ "$item[2]:$item[-1]"; }
    | <error>

value_ipv4_mask :
	<skip: ''> value_ipv4 '/' ( decint[0,32] | value_ipv4 )
	{ "$item[2]/$item[-1]"; }
    | <error>

value_mac :
	/([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}/
    | <error>

value_path : path

GRAMMAR

Parse::RecDescent->Precompile($grammar, 'Config::Maker::Grammar');
rename 'Grammar.pm', $ARGV[0];

1;

__END__

=head1 NAME

Config::Maker::Grammar - Unified parser for Config::Maker

=head1 SYNOPSIS

  use Config::Maker;
  use Config::Maker::Grammar;

  $parser->config($config);
  $parser->template($template);
  $parser->path_whole($path);
  
=head1 DESCRIPTION

=head1 AUTHOR

Jan Hudec <bulb@ucw.cz>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Jan Hudec. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

configit(1), perl(1), Config::Maker(3pm).

=cut
# arch-tag: efac1596-bdde-4343-8be7-dfe989c3873e
