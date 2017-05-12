#!/usr/bin/perl
package CSS::LESSp;

use warnings;
use strict;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw('parse');
our $VERSION = '0.86';

my $id = 1;

#
# specs check
#
# accessors.less 					( ok )
# big.less							( ok )
# colors.less						( ok ) exceptions : no hsl
# comments.less						( ok )
# css-3.less						( ok )
# css.less							( ok )
# dash-prefix.less					( ok )
# functions.less                    ( unsupported )
# hidden.less                       ( unsupported )
# import-with-extra-paths.less      ( unsupported )
# import.less                       ( unsupported )
# lazy-eval.less                    ( unsupported )
# literal-css.less                  ( unsupported )
# mixins-args.less                  ( ok )
# mixins.less                       ( ok )
# operations.less                   ( ok )
# parens.less                       ( ok )
# rulesets.less                     ( ok )
# scope.less                        ( ok )
# selectors.less                    ( ok )
# strings.less                      ( ok )
# variables.less                    ( ok )
# whitespace.less                   ( ok ) exceptions : doesn't merge same lines
# 

sub new {
	my $class = shift;	
	my $self = {		
		'variables' => {},
		'rules' => [],
		'type' => 'child',
		'children' => []
	};
	bless $self, $class;
	return $self;
}

sub isFunction {
	my ($self) = @_;
	if ( $self->{'type'} eq 'function' ) { return 1; }
	return 0;
}

sub insertChild {
	my ($self, $name, $parents) = @_;		
	my @parents = @{$parents} if $parents;
	$id++;
	$self->{'children'} = [] if !defined($self->{'children'});
	
	$name =~ s/\n/ /mg;		
	
	#	
	# Find the full name
	my $fullName = $name;	
	if ( defined($self->{'id'}) ) {				
		my @names = $name =~ /\,/ ? split(/\s*\,\s*/, $name) : ( $name );
		for my $parent ( reverse @parents ) {						
			next if !defined($parent->{'name'});						
			my @prenames = $parent->{'name'} =~ /\,/ ? split(/\s*\,\s*/, $parent->{'name'}) : ($parent->{'name'});
			my @postnames = ();
			for my $prename ( @prenames ) {
				for my $name ( @names ) {												
					push @postnames, $prename.( $name =~ /^\:/ ? "" : " " ).$name;
				}
			}
			@names = @postnames;
			$fullName = join(", ", @names);						
		}
	}
	
	push @{$self->{'children'}}, {
		'name' => $name,
		'fullname' => $fullName,
		'type' => 'child',
		'id' => $id,
		'variables' => {}		
	};	
	return bless $self->{'children'}->[$#{$self->{'children'}}];
}

sub insertVariable {
	my ($self, $variable, $value) = @_;
	
	if ( $self->isFunction ) {
		push @{$self->{'variables'}}, { $variable => $value };
	} else {
		$self->{'variables'}->{$variable} = $value;		
	}
	
	return $self;
}

sub insertRule {
	my ($self, $property, $value) = @_;
	
	$self->{'rules'} = [] if !defined($self->{'rules'});
	
	push @{$self->{'rules'}}, { $property => $value };
	
	return $self;
}

sub insertFunction {
	my ($self, $name, $parents) = @_;
	my @parents = @{$parents} if $parents;
	#my @variables = @{$variables} if $variables;
	
	$name =~ s/\n/ /mg;
	$self->{'functions'} = [] if !defined($self->{'functions'});
	
	push @{$self->{'functions'}}, {
		'name' => $name,
		'type' => 'function',
		'variables' => []		
	};	
	return bless $self->{'functions'}->[$#{$self->{'functions'}}];
}

sub getVariable {
	my ($self, $variable, $parents) = @_;	
	my @parents = @{$parents} if $parents;
	
	#
	# First try to see if the variable is here
	if ( defined($self->{'variables'}->{$variable}) ) {		
		return $self->{'variables'}->{$variable};
	}	
	
	#
	# If we have parents parse them too
	for my $parent ( reverse @parents ) {
		return $parent->{'variables'}->{$variable} if defined($parent->{'variables'}->{$variable});				
	}
	
	return 0;
}

sub getSelector {
	my ($self, $name, $parents) = @_;
	my @parents = @{$parents} if $parents;	
	
	#
	# First try to see if it's a previous sibling 
	if ( defined($self->{'children'}) ) {
		for my $style ( @{$self->{'children'}} ) {
			return $style if ($style->{'name'} eq $name);
		}
	}		

	#
	# Next try to find from parents
	for my $parent ( reverse @parents ) {						
		for my $style ( @{$parent->{'children'}} ) {		
			return $style if ($style->{'name'} eq $name);
		}
	}
	
	#
	# Last we start search of everything if it is root
	my $root = $parents[0] if !defined($parents[0]->{'id'});
	if ( defined($root->{'children'}) ) {		
		my $return;
		my $fullNameSelector;
		$root->process(sub {
			my ($style) = @_;
			if ( defined($style->{'name'}) and $style->{'name'} eq $name ) {
				$return = $style;
			}
			if ( defined($style->{'fullname'}) and $style->{'fullname'} eq $name ) {
				$fullNameSelector = $style;
			}
		});
		return $return if $return;
		return $fullNameSelector if $fullNameSelector;
	}
	
	#
	# If we can't find ... then try for functions the same way
	if ( defined($self->{'functions'}) ) {
		for my $function ( @{$self->{'functions'}} ) {
			return $function if ($function->{'name'} eq $name);
		}
	}
	for my $parent ( reverse @parents ) {
		if ( defined($parent->{'functions'}) ) {
			for my $function ( @{$parent->{'functions'}} ) {			
				return $function if ($function->{'name'} eq $name);
			}
		}
	}
	if ( defined($root->{'children'}) ) {		
		my $return;
		my $fullNameSelector;
		$root->process(sub {
			my ($style) = @_;
			if ( defined($style->{'functions'}) ) {
				for my $function ( @{$style->{'functions'}} ) {
					if ( defined($function->{'name'}) and $function->{'name'} eq $name ) {
						$return = $function;
					}					
				}
			}
		});
		return $return if $return;
		return $fullNameSelector if $fullNameSelector;
	}
	
	return 0;
}

sub getValue {
	my ($self, $property) = @_;
	my $value;	
	
	if ( defined($self->{'rules'}) ) {		
		for my $rule ( @{$self->{'rules'}} ) {			
			$value = join('', values %{$rule}) if join('', keys %{$rule}) eq $property;
		}
	}	
	
	return $value;
}

sub process {
	my ($styles, $function) = @_;
	
	my @parents = ();
	push @parents, $styles->{'children'};
	$styles = $styles->{'children'};
	my $level = 0;				
	push my @position, 0;
	
	while ( 1 ) {
		my $style = $styles->[$position[$level]];
		&$function($style, $level, (\@parents, \@position));
		if ( defined($style->{'children'}) ) {					
			$level++;
			$position[$level] = 0;				
			push @parents, $styles;
			$styles = $style->{'children'};				
		} else {						
			while ( $position[$level] == $#{$styles} ) {
				return 1 if $level == 0;
				$styles = pop @parents;
				$level--;									
			}			
			$position[$level]++;			
		}
	}
	return 0;
}

sub copyTo {
	my ($self, $targetSelector) = @_;
	my ($rules, $children, $variables);	
	
	# copy rules
	if ( defined($self->{'rules'}) ) {	
		$targetSelector->{'rules'} = [] if !defined($targetSelector->{'rules'});
		for my $rule ( @{$self->{'rules'}} ) {						
			push @{$targetSelector->{'rules'}}, {%{$rule}};
		}
	}
	
	# copy variables
	if ( defined($self->{'variables'}) ) {
		for my $variable ( keys %{$self->{'variables'}} ) {
			$targetSelector->{'variables'}->{$variable} = $variables->{$variable};				
		}
	}
	
	# copy children
	if ( defined($self->{'children'}) ) {
		my @targets = ();
		push @targets, $targetSelector;
		my $target = $targetSelector;
		my $l = 0;
		
		$self->process(sub {
			my ($style, $level) = @_;			
			$target = $target->insertChild($style->{'name'}, \@targets);
			#
			# adding variables
			if ( defined($style->{'variables'}) ) {
				for my $variable ( keys %{$style->{'variables'}} ) {
					$target->insertVariable($variable, $style->{'variables'}->{$variable});
				}
			}
			#
			# adding rules
			if ( defined($style->{'rules'}) ) {					
				for my $rule ( @{$style->{'rules'}} ) {
					my $property = join("", keys %{$rule});
					my $value = join("", values %{$rule});
					$target->insertRule($property, $value);						
				}
			}			
			#
			# children leveling
			if ( defined($style->{'children'}) ) {					
				push @targets, $target;					
			} else {				
				if ( $l != $level ) {
					$l = $level;
					$target = pop @targets;
				}
			}	
		});
	}	
	
	return 0;
}

sub copyFunction {
	my ($self, $targetSelector, $variables, $parents) = @_;
	my ($rules, $children);
	my @variables = @{$variables};
	my @parents = @{$parents};	
	
	# copy vars	
	if ( defined($self->{'variables'}) ) {				
		for ( my $position = 0; $position <= $#{$self->{'variables'}}; $position++ ) {
			my $variable = join("",keys %{$self->{'variables'}->[$position]});
			my $value = join("", values %{$self->{'variables'}->[$position]});			
			$value = $variables[$position] if $variables[$position];			
			$targetSelector->{'variables'}->{$variable} = $value;			
		}
	}
	
	# copy rules
	if ( defined($self->{'rules'}) ) {	
		$targetSelector->{'rules'} = [] if !defined($targetSelector->{'rules'});
		for my $rule ( @{$self->{'rules'}} ) {
			my $property = join("", keys %{$rule});
			my $value = join("", values %{$rule});
			while ( $value =~ /\@(\w+\-*\w*)/ ) {
				my $word = $1;								
				# get the variable
				my $var = $targetSelector->getVariable($word, \@parents);
				$value =~ s/\@$word/$var/;						
				# if variable value is negative
				if ( $var =~ s/^\-// ) {
					$value =~ s/\-\s*\-$var/\+ $var/g;
					$value =~ s/\+\s*\-$var/\- $var/g;
				}
			}
			# parse for other stuff									
			$value = _parse_value($value);
			push @{$targetSelector->{'rules'}}, {$property => $value};
		}
	}
	
	# copy children
	if ( defined($self->{'children'}) ) {
		my @targets = ();
		push @targets, $targetSelector;
		my $target = $targetSelector;
		my $l = 0;
		
		$self->process(sub {
			my ($style, $level) = @_;			
			$target = $target->insertChild($style->{'name'});
			#
			# adding variables
			if ( defined($style->{'variables'}) ) {
				for my $variable ( keys %{$style->{'variables'}} ) {
					$target->insertVariable($variable, $style->{'variables'}->{$variable});
				}
			}
			#
			# adding rules
			if ( defined($style->{'rules'}) ) {					
				for my $rule ( @{$style->{'rules'}} ) {
					my $property = join("", keys %{$rule});
					my $value = join("", values %{$rule});
					$target->insertRule($property, $value);						
				}
			}			
			#
			# children leveling
			if ( defined($style->{'children'}) ) {					
				push @targets, $target;					
			} else {				
				if ( $l != $level ) {
					$l = $level;
					$target = pop @targets;
				}
			}	
		});
	}	
	
	return 0;
}

sub dump {
	my ($self) = @_;
	my @return = ();
	
	if ( defined($self->{'rules'}) ) {
		for my $rule ( @{$self->{'rules'}} ) {
			push @return, join('', keys %{$rule}).join('', values %{$rule}).";\n";
		}
		push @return, "\n";
	}
	
	$self->process(sub {
		my ($style, $level, @arrays) = @_;
		my @parents = @{$arrays[0]};
		my @position = @{$arrays[1]};		
		if ( defined($style->{'rules'}) ) {					
			push @return, $style->{'fullname'} ." { ";
			push @return, "\n" if $#{$style->{'rules'}} > 0;			
			for my $rule ( @{$style->{'rules'}} ) {
				push @return, "\t" if $#{$style->{'rules'}} > 0;
				push @return, join('', keys %{$rule}).": ".join('', values %{$rule})."; ";
				push @return, "\n" if $#{$style->{'rules'}} > 0;
			}
			push @return, "}\n";
		}		
	});
	return @return;
}

sub _parse_value {
	my $value = shift;
	# convert rgb(255,255,255) to #ffffff ( hsl doesn't work right now )
	while ( $value =~ /rgb\((\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*\)/ ) {							
		my $color = sprintf("#%0.2X%0.2X%0.2X", $1,$2,$3);
		$value =~ s/rgb\((\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*\)/$color/;
	}
	# expand colors ( from #fff to #ffffff )
	while ( $value =~ /\#([abcdef0123456789]{3})([^abcdef0123456789]|$)/i ) {
		my $color = $1;
		my $replace = join('', map { $_ x 2 } split(//, $color)); # equals to : for ( split(//, $color) ) { $replace .= $_ x 2; }
		$value =~ s/\#$color/\#$replace/;
	}
	# expressions in brackets
	while ( $value =~ /\(\s*(\-?\d+\s*((px|pt|em|cm|%))*\s*[\+\*\/\-]\s*\-?\d+\s*((px|pt|em|cm|%))*)\s*\)/ ) {
		my $expression = my $eval = $1;
		my ($removed) = $eval =~ m/(px|pt|em|cm|%)/;
		$eval =~ s/(px|pt|em|cm|%)//;
        if ( $eval !~ /[a-z]/i and defined(my $result = eval($eval)) ) {
			$result .= "$removed" if defined $result and $removed;
			$value =~ s/(\(\Q$expression\E\))/$result/;	
		};						
	}
	# expression (+,-,*,/) ; whole expressions
	if ( $value =~ /(\d+)\s*(px|pt|em|cm|%)*\s*(\+|\*|\/)\s*((\d+)\s*(px|pt|em|cm|%)*|\d+)/ or $value =~ /(\d+)\s*(px|pt|em|cm|%)*\s*(\-)\s+((\d+)\s*(px|pt|em|cm|%)*|\d+)/ ) {																		
		my $eval = $value;
		my $removed = $1 if $eval =~ s/(px|pt|em|cm|%)//g;																		
		if ( $eval !~ /[a-z]/i ) {
			my $result = eval($eval);							
			$result .= "$removed" if defined($result) and $removed;
			$value = $result if !$@ and defined $result;
		}						
	}
	# expression with color
	if ( $value =~ /\#[abcdef0123456789]{6}/i and $value =~ /(\+|\-|\*|\/)/ ) {			
		my @rgb = ( $value, $value, $value );						
		$rgb[0] =~ s/\#([abcdef0123456789]{2})[abcdef0123456789]{4}/\#$1/ig;
		$rgb[1] =~ s/\#[abcdef0123456789]{2}([abcdef0123456789]{2})[abcdef0123456789]{2}/\#$1/ig;
		$rgb[2] =~ s/\#[abcdef0123456789]{4}([abcdef0123456789]{2})/\#$1/ig;
		my $return = "";
		for ( @rgb ) {							
			while ( /\#([abcdef0123456789]{2})/i ) {
				my $dec = hex($1);
				s/\#$1/$dec/;
			}										
			if ( !/[a-z]/i ) {
				my $eval = eval;
				if ( $eval < 0 ) { $eval = 0 };
				if ( $eval > 255 ) { $eval = 255 };								
				$return .= sprintf("%0.2X", $eval);								
			}
		}
		$value = "#".lc $return if $return;						
	}		
	return $value;
}

sub parse {
	my $self = shift;
	my $string = shift;
	my $styles = CSS::LESSp->new();	
	my $selector = $styles;		
	my @parents;
	push @parents, $styles;
	# real parsing
	my $lastChar = my $buffer = my $mode = my $stop = "";	
	$string =~ s/^\xEF\xBB\xBF\x0A//; # removing special characters from front of file		
	for ( split //, $string ) {		
		$buffer .= $_;		
		if ( $mode ) {
			$buffer =~ s/.$// if $mode eq "delete";
			if ( length($stop) == 1 and $_ eq $stop ) {	$mode = "" };
			if ( length($stop) == 2 and $lastChar.$_ eq $stop ) { $mode = "" } else { $lastChar = $_ };
			next;			
		}
		next if /\n/;
		#
		# The program
		#
		if ( /\}/ or /\;/ ) {
			# clearing some buffer data
			$buffer =~ s/.$//;					
			$buffer =~ s/^\s*|\s*$//g; # remove any spaces from front or back			
			$buffer =~ s/\s*\n\s*/ /g; # removes any new line
			if ( $buffer ) {
				# if it's a property and rule
				if ( $buffer =~ s/^\s*([^:]*)\s*\:\s*(.*)\s*$// ) {					
					my $property = $1;
					my $value = $2;								
					$value =~ s/\n/ /g;					
					$property =~ s/\s*$//;   # remove any additional spaces left					
					# different rule-set property ( mixins )
					if ( $value =~ /^(#|.)(.*)\[(.*)\]$/ ) {												
						my $targetSelectorName = $1.$2;
						my $targetProperty = $3;
						my $return;
						$targetProperty =~ s/['"]//g;						
						$targetProperty =~ s/\s*//g;	
						# get the target mixin selector
						my $targetSelector = $selector->getSelector($targetSelectorName, \@parents);						
						# get the value
						if ( $targetProperty =~ /^\@/ ) {
							$targetProperty =~ s/^\@//;
							$return = $targetSelector->getVariable($targetProperty);
						} else {
							$return = $targetSelector->getValue($targetProperty);
						}						
						$value = $return if $return;						
					}
					# variable access
					if ( !$selector->isFunction ) {
						while ( $value =~ /\@(\w+\-*\w*)/ ) {
							my $word = $1;								
							# get the variable
							my $var = $selector->getVariable($word, \@parents);
							$value =~ s/\@$word/$var/;						
							# if variable value is negative
							if ( $var =~ s/^\-// ) {
								$value =~ s/\-\s*\-$var/\+ $var/g;
								$value =~ s/\+\s*\-$var/\- $var/g;
							}
						}						
						# parse for other stuff									
						$value = _parse_value($value);
					}
					# variable definition check ( after we have parsed the stuff )
					if ( $property =~ /^\@(\w+\-*\w*)/ ) {																		
						$selector->insertVariable($1, $value);
						$property = $value = "";
					} else {
						$selector->insertRule($property, $value);						
					}
				}
				# nested rules (mixins)
				if ( $buffer =~ s/^(\..*)$// or $buffer =~ s/^(\#.*)$// ) {																
					my $source = $1;
					$source =~ s/\s*\:\s*/\:/g;										
					# for multiple mixins					
					while ( $source =~ /\(.*,.*\)/ ) {
						$source =~ s/\(\s*(.*)\s*,\s*(.*)\s*\)/($1;$2)/ 
					};
					my @sources = $source =~ /\,/ ? split(/\s*\,\s*/, $source) : ( $source );					
					for my $source ( @sources ) {					
						my @vars; # this is if any functions are found
						my $sourceSelector = $selector->getSelector($source , \@parents);
						if ( $source =~ /\>/ && !$sourceSelector ) {
							my ( $parent, $child ) = split(/\s*\>\s*/, $source);							
							my $pSelector = $selector->getSelector($parent, \@parents);
							$sourceSelector = $pSelector->getSelector($child) if $pSelector;							
						}
						if ( $source =~ /(.*)\((.*)\)/ && !$sourceSelector ) {
							my $function = $1;
							my $vars = $2;
							@vars = $vars =~ /\;/ ? split(/\;/, $vars) : ( $vars );							
							$sourceSelector = $selector->getSelector($function, \@parents);
						}						
						next if !$sourceSelector;						
						if ( $sourceSelector->isFunction ) {														
							$sourceSelector->copyFunction($selector, \@vars, \@parents);
						} else {
							$sourceSelector->copyTo($selector);
						}
					}
				}
				# other stuff				
				$selector->insertRule($buffer,"") if $buffer;
			}
			$selector = pop @parents if /\}/;
			$buffer = "";
		}
		#
		# selectors
		if ( /\{/ ) {			
			# clearing some buffer data
			$buffer =~ s/.$//g;	
			$buffer =~ s/^\s*|\s*$//g; 	
			# insert the child
			if ( $buffer ) {
				push @parents, $selector;
				if ( $buffer =~ /(.*)\s*\((\@*.*)\)/ and $buffer !~ /^.*[:].*\(/ ) {														
					my $function = $1;
					my $vars = $2;
					$function =~ s/^\s*|\s*$//g;										
					$selector = $selector->insertFunction($function, \@parents);					
					my @vars = $vars =~ /\,/ ? split(/\s*\,\s*/, $vars) : ( $vars );					
					for my $var ( @vars ) {						
						next if !$var;
						my ($variable, $value) = split(/\s*\:\s*/, $var);
						$variable =~ s/^\@//;
						$selector->insertVariable($variable, $value);
					}
				} else {
					$selector = $selector->insertChild($buffer, \@parents);
				}
			}
			$buffer = "";
		}
		#
		#
		#		
		if ( /\"/ or /\'/ ) { $mode = "skip"; $stop = $_ };
		if ( /\(/ ) { $mode = "skip"; $stop = ")" };
		if ( $lastChar =~ /\// and /\// ) { $mode = "delete"; $stop = "\n";	$buffer =~ s/..$//	}
		if ( $lastChar =~ /\// and /\*/ ) { $mode = "delete"; $stop = "*/";	$buffer =~ s/..$//  };		
		$lastChar = $_;		
	}
	return $styles->dump();
}

1;

=head1 NAME

CSS::LESSp - LESS for perl. Parse .less files and returns valid css (lesscss.org for more info about less files)

=head1 SYNOPSIS

  use CSS::LESSp;

  my $buffer;
  open(IN, "file.less");
  for ( <IN> ) { $buffer .= $_ };
  close(IN);
 
  my @css = CSS::LESSp->parse($buffer);

  print join("", @css);

or you could simply use the lessp.pl tool in the package

  $ lessp.pl css.less > css.css

=head1 DESCRIPTION

This module is designed to parse and compile .less files in to .css files.

About the documentation and syntax of less files please visit lesscss.org 

=head1 DIFFERENCE WITH THE ORIGINAL LESS FOR RUBY

What is the benefits of LESS for perl ...

It's extremely fast :
 
  # time ./lessp.pl big.less > big.css

  real    0m2.198s
  user    0m2.174s
  sys     0m0.020s
  
  # time lessc big.less big.css

  real    0m18.805s
  user    0m18.437s
  sys     0m0.184s
 
=head1 METHODS

=head3 parse

Main parse method, returns array of the css file

=head3 copyFunction

=head3 copyTo

=head3 dump
=head3 getSelector
=head3 getValue
=head3 getVariable
=head3 insertChild
=head3 insertFunction
=head3 insertRule
=head3 insertVariable
=head3 isFunction
=head3 new
=head3 process

=head1 BUGS

a ) You can not import other less files ...

You can't do this

  @import url('/other.less')

It might be added in future versions

b ) You can not use hsl as a color

You can't do this

  color: hsl(125,125,125);
  
All other bugs should be reported via
L<http://rt.cpan.org/Public/Dist/Display.html?Name=CSS-LESSp>
or L<bug-CSS-LESSp@rt.cpan.org>.

=head1 AUTHOR

Ivan Drinchev <drinchev@gmail.com>

=head1 CONTRIBUTORS

People who've helped with this project :

Michael Schout <mschout@gkg.net>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
