package Code::Class::C;

use 5.010000;
use strict;
use warnings;

our $VERSION = '0.08';

my $LastClassID = 0;

#-------------------------------------------------------------------------------
sub new
#-------------------------------------------------------------------------------
{
	my ($class, @args) = @_;
	my $self = bless {}, $class;
	return $self->_init();
}

#-------------------------------------------------------------------------------
sub func
#-------------------------------------------------------------------------------
{
	my ($self, $name, $code) = @_;

	my $sign = $self->_parse_signature($name);
	
	die "Error: function name '$sign->{'name'}' is not a valid function name\n"
		if $sign->{'name'} !~ /^[a-z][a-zA-Z0-9\_]*$/;
	die "Error: function must not be named 'main'\n"
		if $sign->{'name'} eq 'main';

	$name = $self->_signature_to_string($sign);
	
	die "Error: trying to redefine function '$name'\n"
		if exists $self->{'functions'}->{$name};

	$self->{'functions'}->{$name} = $self->_load_code_from_file($code);
	$self->{'functions-doc'}->{$name} = ''
		unless exists $self->{'functions-doc'}->{$name};

	return $self;
}

#-------------------------------------------------------------------------------
sub attr
#-------------------------------------------------------------------------------
{
	my ($self, $classname, $attrname, $attrtype) = @_;
	die "Error: no class '$classname' defined\n"
		unless exists $self->{'classes'}->{$classname};

	my $class = $self->{'classes'}->{$classname};

	die "Error: attribute name '$attrname' is not a valid attribute name\n"
		if $attrname !~ /^[a-z][a-zA-Z0-9\_]*$/;
	
	$class->{'attr'}->{$attrname} = $attrtype;
	$class->{'attr-doc'}->{$attrname} = ''
		unless exists $class->{'attr-doc'}->{$attrname};
	
	return $self;
}

#-------------------------------------------------------------------------------
sub meth
#-------------------------------------------------------------------------------
{
	my ($self, $classname, $name, $code) = @_;
	die "Error: no class '$classname' defined\n"
		unless exists $self->{'classes'}->{$classname};
	
	my $class = $self->{'classes'}->{$classname};
	my $sign = $self->_parse_signature($name);

	die "Error: failed to parse method with signature '$name'.\n"
		if !defined $sign->{'returns'};

	die "Error: methodname '$sign->{'name'}' is not a valid method name\n"
		if $sign->{'name'} !~ /^[a-z][a-zA-Z0-9\_]*$/;

	# add implicit "self" first parameter
	unshift @{$sign->{'params'}}, ['self',$classname]; 
	$name = $self->_signature_to_string($sign);

	die "Error: trying to redefine method '$name' in class '$classname'\n"
		if exists $class->{'subs'}->{$name};

	$class->{'subs'}->{$name} = $self->_load_code_from_file($code);
	$class->{'subs-doc'}->{$name} = ''
		unless exists $class->{'subs-doc'}->{$name};
	
	return $name;
}

#-------------------------------------------------------------------------------
sub parent
#-------------------------------------------------------------------------------
{
	my ($self, $classname, @parentclassnames) = @_;
	die "Error: no class '$classname' defined\n"
		unless exists $self->{'classes'}->{$classname};

	my $class = $self->{'classes'}->{$classname};
	
	foreach my $parentclassname (@parentclassnames) {
		push @{$class->{'isa'}}, $parentclassname
			unless scalar grep { $parentclassname eq $_ } @{$class->{'isa'}};
	}
	
	return $self;
}

#-------------------------------------------------------------------------------
sub before
#-------------------------------------------------------------------------------
{
	my ($self, $classname, $methname, $code) = @_;
	die "Error: no class '$classname' defined\n"
		unless exists $self->{'classes'}->{$classname};
	
	my $class = $self->{'classes'}->{$classname};

	die "Error: methodname '$methname' is not a valid method name\n"
		if $methname !~ /^[a-z][a-zA-Z0-9\_]*$/;

	$class->{'before'}->{$methname} = $self->_load_code_from_file($code);
	
	return $self;
}

#-------------------------------------------------------------------------------
sub after
#-------------------------------------------------------------------------------
{
	my ($self, $classname, $methname, $code) = @_;
	die "Error: no class '$classname' defined\n"
		unless exists $self->{'classes'}->{$classname};
	
	my $class = $self->{'classes'}->{$classname};

	die "Error: methodname '$methname' is not a valid method name\n"
		if $methname !~ /^[a-z][a-zA-Z0-9\_]*$/;

	$class->{'after'}->{$methname} = $self->_load_code_from_file($code);
	
	return $self;
}

#-------------------------------------------------------------------------------
sub class
#-------------------------------------------------------------------------------
{
	my ($self, $name, %opts) = @_;
	die "Error: cannot redefine class '$name': $!\n" 
		if exists $self->{'classes'}->{$name};
	die "Error: classname '$name' does not qualify for a valid name\n"
		unless $name =~ /^[A-Z][a-zA-Z0-9\_]*$/;
	die "Error: classname must not be 'Object'\n"
		if $name eq 'Object';
	die "Error: classname must not be longer than 256 characters\n"
		if length $name > 256;
	
	$LastClassID++;
	$self->{'classes'}->{$name} = 
		{
			'id'   => $LastClassID,
			'name' => $name,
			'doc'  => '',
			'isa'  => [],
			'attr' => {},
			'attr-doc' => {},
			'subs' => {},
			'subs-doc' => {},
			'top'    => ($opts{'top'} || ''),
			'bottom' => ($opts{'bottom'} || ''),
			'after'  => {},
		};

	# define attributes
	my $attr = $opts{'attr'} || {};
	map { $self->attr($name, $_, $attr->{$_}) } keys %{$attr};
	
	# define methods
	my $subs = $opts{'subs'} || {};
	map { $self->meth($name, $_, $subs->{$_}) } keys %{$subs};

	# set parent classes
	$self->parent($name, @{$opts{'isa'} || []});

	return $self;
}

#-------------------------------------------------------------------------------
sub readFile
#-------------------------------------------------------------------------------
{
	my ($self, $filename) = @_;
	open SRCFILE, $filename or die "Error: cannot open source file '$filename': $!\n";
	#print "reading '$filename'\n";
	my $classname = undef; # if set, name of current class
	my $subname   = undef; # if set, name of current method
	my $funcname  = undef; # if set, name of current function
	my $top				= undef; # if set, means currently parsing a @top block
	my $bottom		= undef; # if set, means currently parsing a @bottom block
	my $types			= undef; # if set, means currently parsing a @types block
	my $after			= undef; # if set, the method name for current @after block
	my $before		= undef; # if set, the method name for current @before block
	
	my $buffer = undef;
	my $l      = 0;
	my $docref = undef; # ref to docstring of previous entry
	while (<SRCFILE>) {
		next if /^\/[\/\*]/;
		if (/^\@class/) {
			my ($class, $parents) = 
				$_ =~ /^\@class[\s\t]+([^\s\t\:]+)[\s\t]*\:?[\s\t]*(.*)$/;
			my @parents = split /[\s\t]*\,[\s\t]*/, $parents;

			$self->class($class) unless exists $self->{'classes'}->{$class};
			$self->parent($class, @parents);
			$classname = $class;
			$docref = \$self->{'classes'}->{$class}->{'doc'};
		}
		elsif (/^\@attr/) {
			die "Error: no classname present at line $l.\n"
				unless defined $classname;

			my ($attr, $type) =
				$_ =~ /^\@attr[\s\t]+([^\s\t\:]+)[\s\t]*\:?[\s\t]*(.*)$/;
			$type =~ s/[\s\t\n\r]*$//g;

			warn "Warning: attribute definition $classname/$attr overwrites present one.\n"
				if exists $self->{'classes'}->{$classname}->{'attr'}->{$attr};
				
			$self->attr($classname, $attr, $type);
			
			$self->{'classes'}->{$classname}->{'attr-doc'}->{$attr} = ''
				unless exists $self->{'classes'}->{$classname}->{'attr-doc'}->{$attr};
			$docref = \$self->{'classes'}->{$classname}->{'attr-doc'}->{$attr};
		}
		elsif (/^\@(sub|func|before|after)/) {
			unless (/^\@func/) { 	
				die "Error: no classname present at line $l.\n"
					unless defined $classname;
			}
			
			# save previous "something"
			_save_current_buffer($self, $classname, $subname, $funcname, $before, $after, $buffer);

			# start new "something"
			if (/^\@sub/) {
				($subname) = $_ =~ /^\@sub[\s\t]+(.+)[\s\t\n\r]*$/;
				$funcname = undef;
				$before = undef;
				$after = undef;

				my $methname = $self->_get_complete_method_name($classname, $subname);
				#print "($methname)\n" if $methname =~ /^getAppWindow/;
				$self->{'classes'}->{$classname}->{'subs-doc'}->{$methname} = ''
					unless exists $self->{'classes'}->{$classname}->{'subs-doc'}->{$methname};
				#print ">>docref meth $methname\n";
				$docref = \$self->{'classes'}->{$classname}->{'subs-doc'}->{$methname};
			}
			elsif (/^\@func/) {
				($funcname) = $_ =~ /^\@func[\s\t]+(.+)[\s\t\n\r]*$/;
				$subname = undef;
				$before = undef;
				$after = undef;

				$self->{'functions-doc'}->{$funcname} = ''
					unless exists $self->{'functions-doc'}->{$funcname};
				$docref = \$self->{'functions-doc'}->{$funcname};
			}
			elsif (/^\@after/) {
				my ($methname) = $_ =~ /^\@after[\s\t]+(.+)[\s\t\n\r]*$/;
				$after = $methname;
				$funcname = undef;
				$before = undef;
				$subname = undef;
			}
			elsif (/^\@before/) {
				my ($methname) = $_ =~ /^\@before[\s\t]+(.+)[\s\t\n\r]*$/;
				$before = $methname;
				$funcname = undef;
				$after = undef;
				$subname = undef;
			}
			
			$buffer = '';
			$bottom = undef;
			$top = undef;
			$types = undef;
		}
		elsif (/^\@top/) {
			$top = '';
			$bottom = undef;
			$types = undef;
		}
		elsif (/^\@bottom/) {
			$bottom = '';	
			$top = undef;
			$types = undef;
		}
		elsif (/^\@types/) {
			$types = '';
			$bottom = undef;	
			$top = undef;
		}
		elsif (/^[\s\t]*\@/) {
			my ($doc) = $_ =~ /^[\s\t]*\@[\s\t]*(.*)$/;
			#print "[$doc]\n";
			${$docref} .= ' '.$doc
				if defined $docref;
		}
		
		# store current line in a buffer
		elsif (!defined $subname && defined $top) {
			$self->{'area'}->{'top'} .= $_;
		}
		elsif (!defined $subname && defined $bottom) {
			$self->{'area'}->{'bottom'} .= $_;
		}
		elsif (!defined $subname && defined $types) {
			$self->{'area'}->{'types'} .= $_;
		}
		else {
			$buffer .= $_;
		}
		$l++;
	}
	# save last "something"
	_save_current_buffer($self, $classname, $subname, $funcname, $before, $after, $buffer);
	
	close SRCFILE;
	return 1;
	
	sub _save_current_buffer
	{
		my ($self, $classname, $subname, $funcname, $before, $after, $buffer) = @_;
		if (defined $classname && defined $subname && defined $buffer) {
			# add method to class
			my $methname = $self->meth($classname, $subname, $buffer);
		}
		elsif (defined $funcname && defined $buffer) {
			# add function
			$self->func($funcname, $buffer);			
		}
		elsif (defined $classname && defined $before && defined $buffer) {
			# add 'before'-hook
			$self->before($classname, $before, $buffer);
		}
		elsif (defined $classname && defined $after && defined $buffer) {
			# add 'after'-hook
			$self->after($classname, $after, $buffer);
		}
	}
	
	sub _get_complete_method_name
	{
		my ($self, $classname, $methname) = @_;
		my $sign = $self->_parse_signature($methname);
		unshift @{$sign->{'params'}}, ['self', $classname];
		return $self->_signature_to_string($sign);
	}
}

sub _skip_class
{
	my ($classname, $classnames) = @_;
	return
		defined $classnames &&
		!scalar grep { $_ eq $classname } @{$classnames};
}

#-------------------------------------------------------------------------------
sub functionsToLaTeX
#-------------------------------------------------------------------------------
{
	my ($self, $autogen) = @_;
	$autogen = 0 unless defined $autogen;
	
	die "Error: cannot call toLaTeX() method AFTER generate() method has been called\n"
		if $autogen == 0 && $self->{'autogen'} == 1;
	#$self->_autogen();

	my $tex = "\n\n";

	if (scalar keys %{$self->{'functions'}}) {
		$tex .= '\subsection{Statische Funktionen}'."\n";
		$tex .= '\begin{description*}'."\n\n";
		foreach my $funcname (sort keys %{$self->{'functions'}}) {
			my $sign = $self->_parse_signature($funcname);
			my $code = $self->{'functions'}->{$funcname};
				 $code =~ s/\t/  /g;
				 $code =~ s/(\r?\n)\s\s/$1/g;

			$tex .=
				'\item \texttt{\color{orange}'.$sign->{'name'}.'(} '.
				join(",\n", map {
					'\texttt{'.$_->[0].'} '.$self->_mkClassRef($_->[1]);					
				} @{$sign->{'params'}}).'\texttt{\color{orange})}'.
				': '.$self->_mkClassRef($sign->{'returns'})."\n";
			
			if (scalar @{$sign->{'params'}} > 0) {
				$tex .= "\n\n";
			}
			$tex .= _docToLaTeX($self->{'functions-doc'}->{$funcname})."\n\n";

# 			$tex .=
# 				'\item \texttt{\color{red}'.$sign->{'name'}.' ('.
# 				join(', ', map { $_->[0] } @{$sign->{'params'}}).'):} '.
# 				$self->_mkClassRef($sign->{'returns'})."\n\n";
# 			
# 			if (scalar @{$sign->{'params'}} > 0) {
# 				$tex .= '\begin{description*}'."\n\n";
# 				foreach my $param (@{$sign->{'params'}}) {
# 					$tex .= '\item \texttt{'.$param->[0].'} :\hspace{1ex} '.$self->_mkClassRef($param->[1])."\n\n";
# 				}
# 				$tex .= '\end{description*}'."\n\n";
# 			}
# 			$tex .= _docToLaTeX($self->{'functions-doc'}->{$funcname})."\n\n";
# 			$tex .= '\vspace{3mm}'."\n\n";
		}
		$tex .= '\end{description*}'."\n\n";
	}

	return $tex;
}

#-------------------------------------------------------------------------------
sub toLaTeX
#-------------------------------------------------------------------------------
{
	my ($self, $autogen, $classnames) = @_;
	$autogen = 0 unless defined $autogen;
	
	die "Error: cannot call toLaTeX() method AFTER generate() method has been called\n"
		if $autogen == 0 && $self->{'autogen'} == 1;
	#$self->_autogen();
	
	my $tex = "\n\n";
	foreach my $classname (keys %{$self->{'classes'}}) {
		next if _skip_class($classname,$classnames);
		$tex .= $self->_classToLaTeX($classname)."\n\n";
	}

	return $tex;
	
	sub _classToLaTeX
	{
		my ($self, $classname) = @_;
		my $class = $self->{'classes'}->{$classname};
		my $tex = '\subsection{'.$classname."}\n";
		$tex .= '\label{Class'.$classname."}\n";
		
		$tex .= _docToLaTeX($self->{'classes'}->{$classname}->{'doc'})."\n";
		$tex .= 'Die Implementierung dieser Klasse ist in der Datei \texttt{'.
			$classname.'.c} zu finden.'."\n\n";

		$tex .= '\begin{figure}[H]'."\n";
		$tex .= '	\centering'."\n";
		$tex .= '	\fbox{\makebox[0.5\textwidth]{'."\n";
		$tex .= '		\includegraphics[width=0.5\textwidth,keepaspectratio]{diagrams/'.$classname.'.png}'."\n";
		$tex .= '	}}'."\n";
		$tex .= '	\caption{UML Klassendiagramm der Klasse '.$classname.'.}'."\n";
		$tex .= '	\label{Block}'."\n";
		$tex .= '\end{figure}'."\n";
		
		if (scalar @{$class->{'isa'}}) {
			$tex .= '\subsubsection{Elternklassen}'."\n";
			
			#$tex .= '\begin{itemize*}'."\n\n";
			#foreach my $classname (@{$class->{'isa'}}) {
			#	#$tex .= '\item '.$self->_mkClassRef($classname)."\n\n";
			#}
			#$tex .= '\end{itemize*}'."\n\n";

			$tex .= join ', ', map { $self->_mkClassRef($_) } @{$class->{'isa'}};
			$tex .= "\n\n";
		}

		my $subclasses = $self->_get_subclasses()->{$classname};
		#use Data::Dumper;
		#print Dumper($subclasses);
		if (scalar keys %{$subclasses}) {
			$tex .= '\subsubsection{Kindklassen}'."\n";
			#$tex .= '\begin{itemize*}'."\n\n";
			#foreach my $classname (keys %{$subclasses}) {
			#	$tex .= '\item '.$self->_mkClassRef($classname)."\n\n";
			#}
			#$tex .= '\end{itemize*}'."\n\n";

			$tex .= join ', ', map { $self->_mkClassRef($_) } keys %{$subclasses};
			$tex .= "\n\n";
		}
		
		if (scalar keys %{$class->{'attr'}}) {
			$tex .= '\subsubsection{Attribute}'."\n";
			$tex .= '\begin{description*}'."\n\n";
			foreach my $attrname (sort keys %{$class->{'attr'}}) {
				$tex .= '\item \texttt{\color{blue}'.$attrname.'} '.$self->_mkClassRef($class->{'attr'}->{$attrname})."\n";
				$tex .= _docToLaTeX($class->{'attr-doc'}->{$attrname})."\n";
				#$tex .= '\vspace{3mm}'."\n\n";
			}
			$tex .= '\end{description*}'."\n\n";
		}
		
		if (scalar keys %{$class->{'subs'}}) {
			$tex .= '\subsubsection{Methoden}'."\n";
			#$tex .= '\setlength{\parskip}{-6pt}'."\n";
			$tex .= '\begin{description*}'."\n\n";
			foreach my $methname (sort keys %{$class->{'subs'}}) {
				my $sign = $self->_parse_signature($methname);
				my $code = $class->{'subs'}->{$methname};
					 $code =~ s/\t/  /g;
					 $code =~ s/(\r?\n)\s\s/$1/g;
				$tex .=
					'\item \texttt{\color{orange}'.$sign->{'name'}.'(} '.
					join(",\n", map {
						'\texttt{'.$_->[0].'} '.$self->_mkClassRef($_->[1]);					
					} @{$sign->{'params'}}).'\texttt{\color{orange})}'.
					#join(', ', map { $_->[0] } @{$sign->{'params'}}).'):} '.
					': '.$self->_mkClassRef($sign->{'returns'})."\n";
				
				if (scalar @{$sign->{'params'}} > 0) {
					#$tex .= '\renewcommand{\arraystretch}{1.0}'."\n\n";
					#$tex .= '\begin{tabular}{lcl}'."\n\n";
					#$tex .= join(",\n", map {
					#	'\texttt{'.$_->[0].'} : '.$self->_mkClassRef($_->[1]);					
					#} @{$sign->{'params'}});
					#foreach my $param (@{$sign->{'params'}}) {
					#	$tex .= '\texttt{'.$param->[0].'} : '.$self->_mkClassRef($param->[1])."\n";
					#	# $code
					#}
					#$tex .= '\end{tabular}'."\n\n";
					#$tex .= '\renewcommand{\arraystretch}{1.2}'."\n\n";
					$tex .= "\n\n";
				}
# 				if ($methname =~ /^getAppWindow/) {
# 					use Data::Dumper;
# 					print Dumper($class->{'subs-doc'});
# 				}
				$tex .= _docToLaTeX($class->{'subs-doc'}->{$methname})."\n\n";
# 				$tex .= '\begin{Verbatim}[fontsize=\footnotesize]'."\n";
# 				$tex .= $code."\n";
# 				$tex .= '\end{Verbatim}'."\n";
				#$tex .= '\vspace{3mm}'."\n\n";
			}
			$tex .= '\end{description*}'."\n\n";
			#$tex .= '\setlength{\parskip}{6pt}'."\n";
		}
		
		return $tex;
	}
	
	sub _docToLaTeX
	{
		my ($doc) = @_;
		my %replacements = (
			'{ae}' => '\"a',
			'{oe}' => '\"o',
			'{ue}' => '\"u',
			'{Ae}' => '\"A',
			'{Oe}' => '\"O',
			'{Ue}' => '\"U',
			'{AE}' => '\"A',
			'{OE}' => '\"O',
			'{UE}' => '\"U',
			'{ss}' => '\ss{}',
		);
		map { 
			my $match = quotemeta $_;
			my $replace = $replacements{$_};
			$doc =~ s/$match/$replace/g;
			$_;
		}
		keys %replacements;
		
		# special replacements
		$doc =~ s/t\{([^\}]*)\}/\\texttt{$1}/g; # t{...} -> fixed width text
		$doc =~ s/i\{([^\}]*)\}/\\textit{$1}/g; # i{...} -> italic text
		$doc =~ s/b\{([^\}]*)\}/\\textbf{$1}/g; # b{...} -> bold text
		
		return $doc;
	}
	
	sub _mkClassRef
	{
		my ($self, $classname) = @_;
		return
			(exists $self->{'classes'}->{$classname} ?
				'\textit{'.$classname.'}$_{\ref{Class'.$classname.'}}$' :
				'\textit{\color{gray}'.$classname.'}');
	}
}

#-------------------------------------------------------------------------------
sub toDot
#-------------------------------------------------------------------------------
{
	my ($self, $autogen, $classnames) = @_;
	$autogen = 0 unless defined $autogen;
	
	die "Error: cannot call toDot() method AFTER generate() method has been called\n"
		if $autogen == 0 && $self->{'autogen'} == 1;
	#$self->_autogen();
	
	my $dot = 
		'digraph {'."\n".
q{
	fontname="Bitstream Vera Sans"
	fontsize=8
 	overlap=scale
	
	node [
		fontname="Bitstream Vera Sans"
		fontsize=8
		shape="record"
	]
	
	edge [
		fontname="Bitstream Vera Sans"
		fontsize=8
		//weight=0.1
	]
	
};

	# add class nodes
	foreach my $classname (keys %{$self->{'classes'}}) {
		next if _skip_class($classname,$classnames);
		my $class = $self->{'classes'}->{$classname};
		$dot .= 
			'  '.$classname.' ['."\n".
			'    label="{'.
				$classname.'|'.
				join('\l', map { '+ '.$_.' : '.$class->{'attr'}->{$_} } keys %{$class->{'attr'}}).'\l|'.
				join('\l', map { $_ } keys %{$class->{'subs'}}).'\l}"'."\n".
			"  ]\n\n";
	}
	
	# add class relationships
	$dot .= 'edge [ arrowhead="empty" color="black" ]'."\n\n";
	foreach my $classname (keys %{$self->{'classes'}}) {
		next if _skip_class($classname,$classnames);
		my $class = $self->{'classes'}->{$classname};
		foreach my $parentclassname (@{$class->{'isa'}}) {
			next if _skip_class($parentclassname,$classnames);
			$dot .= '  '.$classname.' -> '.$parentclassname."\n";
		}
	}
	
	# add "contains" relationships
	$dot .= 'edge [ arrowhead="vee" color="gray" ]'."\n\n";
	foreach my $classname (keys %{$self->{'classes'}}) {
		next if _skip_class($classname,$classnames);
		my $class = $self->{'classes'}->{$classname};
		foreach my $attrname (keys %{$class->{'attr'}}) {
			my $attrtype = $class->{'attr'}->{$attrname};
			$dot .= '  '.$classname.' -> '.$attrtype."\n"
				if exists $self->{'classes'}->{$attrtype} &&
					!_skip_class($attrtype,$classnames);
		}
	}
	
	return $dot.'}'."\n";
}

#-------------------------------------------------------------------------------
sub toHtml
#-------------------------------------------------------------------------------
{
	my ($self) = @_;
	my $html = '';
	
	$self->_autogen();

	# oben: dropdown mit klassen-namen -> onclick wird klasse unten angezeigt
	# unten: Beschreibung der aktuell ausgewaehlten klasse: isa, attr, subs
	#         (auch geerbte!)
	
	my @classnames = sort keys %{$self->{'classes'}};
	
	return 
		'<html>'.
			'<head>'.
				'<title>API</title>'.
				'<style type="text/css">'.q{
					body {
						background: #fff;
						margin: 0;
						padding: 0;
					}
					body, div, select, h1, h2, h3, p, i, span {
						font-size: 12pt;
						font-family: sans-serif;
						font-weight: 200;
					}
					a {
						color: blue;
					}
						a:hover {
							color: #99f;
						}
					p i {
						font-size: 80%;
					}
					h1 { font-size: 200%; }
					h2 { 
						font-size: 140%;
						padding-bottom: 0.2em;
						border-bottom: solid 1px #ccc;
					}
					h3 { font-size: 120%; }
					#top {
						width: 100%;
						position: fixed;
						top: 0;
						left: 220px;
						background: #eee;
						padding: 1em;
					}
					#left {
						width: 200px;
						float: left;
						background: #eee;
						padding: 1em;
						border-left: solid 1px #666;
						overflow: auto;
					}
					#content {
						padding: 4em 1em 1em 260px;
					}
					select {
						vertical-align: middle;
						padding: 0.3em;
					}
					li {
						font-size: 90%;
						margin: 0 0 0 16px;
						list-style: circle;
					}
						li a {
							text-decoration: none;
						}
					ul {
						margin: 0.2em 0;
						padding: 0;
					}
					dl {
					
					}
						dt {
							margin-top: 0.4em;
						}
						dd {
							margin: 0.6em 0 0 2em;
						}
					.typename {
						color: #66c;
					}
					.typename:hover {
						color: #99f;
					}
					.methname {
						color: green;
					}
					p.methnames {
						border-bottom: dotted 1px #ccc;
						padding-bottom: 10pt;
						margin-bottom: 10pt;
					}
						p.methnames a {
							display: inline-block;
							background: #eee;
							-moz-border-radius: 0.4em;
							-webkit-border-radius: 0.4em;
							border-radius: 0.4em;			
							padding: 4pt 6pt 3pt;
							margin-bottom: 2pt;
						}
					pre {
						background: #eee;
						font-size: 9pt;
						padding: 0.4em 0.5em;
						overflow: auto;
						-moz-border-radius: 0.4em;
						-webkit-border-radius: 0.4em;
						border-radius: 0.4em;
						border: solid 1px #ccc;
						font-weight: 200;
						font-family: Monaco, fixed;
					}
						pre span {
							font-size: inherit;
							font-weight: inherit;
							font-family: inherit;
						}
						pre .keyword {
							color: #099;
						}
						pre .string {
							color: #669;
						}
						pre .comment {
							color: #999;
						}
						pre .call {
							color: #009;
						}
				}.'</style>'.				
				'<script type="text/javascript">'.
					'function showClass (id) {'.
					'  id = \'class-\'+id;'.
					'  document.getElementById(\'content\').innerHTML = document.getElementById(id).innerHTML;'.
					'  scroll(0,0);'.
					'}'.
				'</script>'.
			'</head>'.
			'<body onload="showClass(\''.$classnames[0].'\');">'.
				'<div id="top">'.
					'Class: '.
					'<select onchange="showClass(this.value);">'.
					join('', map {
						'<option value="'.$_.'">'.$_.'</option>'
					} @classnames).
					'</select>'.
				'</div>'.
				'<div id="left">'.
					$self->_mkClassTree().
					'<p><i>generated by Code::Class::C</i></p>'.
				'</div>'.
				'<div id="content"></div>'.
				join('', map {
					'<div id="class-'.$_.'" style="display:none">'.$self->_classToHtml($_).'</div>'
				} @classnames).
			'</body>'.
		'</html>';
		
	sub _mkClassTree
	{
		my ($self) = @_;
		# find top classes (those without any parent classes)
		my @topclasses = ();
		foreach my $classname (sort keys %{$self->{'classes'}}) {
			push @topclasses, $classname
				unless scalar @{$self->{'classes'}->{$classname}->{'isa'}};
		}
		
		my $html = '<ul>';
		foreach my $classname (@topclasses) {
			$html .= 
				'<li>'.
					$self->_mkClassLink($classname).' '.
					$self->_mkSubclassList($classname).
				'</li>';
		}
		return $html.'</ul>';
	}
	
	sub _mkSubclassList
	{
		my ($self, $classname) = @_;
		# find direct children
		my @children = ();
		foreach my $cname (sort keys %{$self->{'classes'}}) {
			foreach my $parentclassname (sort @{$self->{'classes'}->{$cname}->{'isa'}}) {
				push @children, $cname
					if $classname eq $parentclassname;
			}
		}
		return 
			(scalar @children ?
				'<ul>'.
					join('', map { '<li>'.$self->_mkClassLink($_).' '.$self->_mkSubclassList($_).'</li>' } @children).
				'</ul>'
					: '');
	}
		
	sub _classToHtml
	{
		my ($self, $classname) = @_;
		my $class = $self->{'classes'}->{$classname};
		my $html = '<h1 class="typename">'.$classname.'</h1>';
		
		$html .= '<h2>Parent classes</h2><dl><dt>';
		$html .= 
			join(', ', map { $self->_mkClassLink($_) }
				sort @{$class->{'isa'}});
		$html .= '</dt></dl>';
		$html .= '<p><i>none</i></p>' unless scalar @{$class->{'isa'}};

		$html .= '<h2>Child classes</h2><dl><dt>';
		my $subclasses = $self->_get_subclasses();
		$html .= 
			join(', ', map { $self->_mkClassLink($_) }
				sort keys %{$subclasses->{$classname}});
		$html .= '</dt></dl>';
		$html .= '<p><i>none</i></p>' unless scalar keys %{$subclasses->{$classname}};
		
		$html .= '<h2>Attributes</h2><dl>';
		foreach my $attrname (sort keys %{$class->{'attr'}}) {
			$html .= '<dt>'.$self->_mkClassLink($class->{'attr'}->{$attrname}).' '.$attrname.'</dt>';
		}
		$html .= '</dl>';
		$html .= '<p><i>none</i></p>' unless scalar keys %{$class->{'attr'}};
		
		$html .= '<h2>Methods</h2><p class="methnames">';
		my $meths = '';
		foreach my $methname (sort keys %{$class->{'subs'}}) {
			my $sign = $self->_parse_signature($methname);
			my $code = $class->{'subs'}->{$methname};
			   $code =~ s/\t/  /g;
			   $code =~ s/(\r?\n)\s\s/$1/g;
			$html .= '<a href="#'.$sign->{'name'}.'">'.$sign->{'name'}.'</a> ';
			$meths .= 
				'<dt>'.
					'<a name="'.$sign->{'name'}.'"></a>'.
					$self->_mkClassLink($sign->{'returns'}).' : '.
					'<span class="methname">'.$sign->{'name'}.'</span>'.
					' ( '.join(', ', map { $self->_mkClassLink($_->[1]).' '.$_->[0] } @{$sign->{'params'}}).' )'.
				'</dt><dd><pre>'.$self->_highlightC($code).'</pre></dd>';
		}
		$html .= '</p><dl>'.$meths.'</dl>';
		$html .= '<p><i>none</i></p>' unless scalar keys %{$class->{'subs'}};
		
		return $html;
	}
	
	sub _highlightC
	{
		my ($self, $c) = @_;
		$c =~ s/(\"[^\"]*\")/<span class="string">$1<\/span>/g;
		$c =~ s/(if|else|for|return|self|while|void|static)/<span class="keyword">$1<\/span>/g;
		$c =~ s/(\/\/[^\n]*)/<span class="comment">$1<\/span>/g;
		$c =~ s/(\/\*[^\*]*\*\/)/<span class="comment">$1<\/span>/mg;
		$c =~ s/([a-zA-Z\_][a-zA-Z0-9\_]*)\(/<span class="call">$1<\/span>\(/g;
		return $c;
	}

	sub _mkClassLink
	{
		my ($self, $classname) = @_;
		return
			(exists $self->{'classes'}->{$classname} ?
				'<a href="javascript:showClass(\''.$classname.'\');" class="typename">'.
					$classname.
				'</a>'
					: '<span class="typename">'.$classname.'</span>');
	}
}

#-------------------------------------------------------------------------------
sub generate
#-------------------------------------------------------------------------------
{
	my ($self, %opts) = @_;
	
	my $file     = $opts{'file'}    || die "Error: generate() needs a filename.\n";
	my $lheaders = $opts{'localheaders'}  || [];
	push @{$lheaders}, @{$opts{'headers'} || []};
	my $gheaders = $opts{'globalheaders'} || [];
	my $maincode = $self->_load_code_from_file($opts{'main'} || '');
	my $debug    = $opts{'debug'} || 0;
	
	my $topcode = 
		$self->_load_code_from_file($opts{'top'} || '')."\n\n".
		$self->_load_code_from_file($self->{'area'}->{'top'});
	
	my $bottomcode = 
		$self->_load_code_from_file($opts{'bottom'} || '')."\n\n".
		$self->_load_code_from_file($self->{'area'}->{'bottom'});

	my $typescode =
		$self->_load_code_from_file($opts{'types'} || '')."\n\n".
		$self->_load_code_from_file($self->{'area'}->{'types'});

	$self->_autogen();
	
	# add standard headers needed
	foreach my $h (qw(string stdio stdlib stdarg)) {
		unshift @{$gheaders}, $h
			unless scalar grep { $_ eq $h } @{$gheaders};
	}

	##############################################################################	
	my $ccode = '';
	
	# write headers
	$ccode .= join '', map { '#include <'.$_.'.h>'."\n" } @{$gheaders};
	$ccode .= join '', map { '#include "'.$_.'.h"'."\n" } @{$lheaders};

	$ccode .= '#define CREATE_STACK_TRACE ('.($debug ? 1 : 0).')'."\n";
	$ccode .= q{
/*----------------------------------------------------------------------------*/

#if CREATE_STACK_TRACE

	#define STACKTRACE_MAX_LENGTH (10)
	char StackTrace[STACKTRACE_MAX_LENGTH][255];
	int StackTraceLength = 0;
	
	void printStackTrace (void)
	{
		int i;
		printf("Stack trace (last one last):\n");
		for (i = 0; i < StackTraceLength; i++) {
			printf("  %d. %s()\n", i, StackTrace[i]);
		}
	}
	
	void logStackTraceEntry (char* msg)
	{
		if (StackTraceLength < STACKTRACE_MAX_LENGTH) {
			sprintf(StackTrace[StackTraceLength], "%s", msg);
			StackTraceLength++;
		}
		else {
			/* move all entries one down */
			int i;
			for (i = 1; i < StackTraceLength; i++) {
				sprintf(StackTrace[i-1], "%s", StackTrace[i]);
			}
			/* set last one */
			sprintf(StackTrace[StackTraceLength-1], "%s", msg);
		}
	}

#endif

/*----------------------------------------------------------------------------*/

typedef struct S_Object* Object;

struct S_Object {
  int classid;
  char classname[256];
  void* data;
};

typedef Object my;

/*----------------------------------------------------------------------------*/
/* String functions */

void setstr (char* dest, const char* src) {
  int i;
  for (i = 0; i < 256; i++) {
    dest[i] = src[i];
  }
}

int streq (char* s1, char* s2) {
  return (strcmp(s1, s2) == 0);
}

};

	##############################################################################
	# create hash of subclasses for each class
  my %subclasses = %{$self->_get_subclasses()};
	$ccode .= "/*-----------------------------------------------------------*/\n";
	$ccode .= "/* ISA Function */\n\n";
	$ccode .= 'int isa (int childid, int classid) {'."\n";
	$ccode .= '  if (childid == classid) { return 1; }'."\n";
  my $first = 1;
  foreach my $classname (keys %subclasses) {
    next unless scalar keys %{$subclasses{$classname}};
  	my $classid = $self->{'classes'}->{$classname}->{'id'};
	  my @clauses = ();
    foreach my $childclassname (keys %{$subclasses{$classname}}) {
	  	my $childclassid = $self->{'classes'}->{$childclassname}->{'id'};
	  	push @clauses, 'childid == '.$childclassid.'/*'.$childclassname.'*/';
  	}
		$ccode .=
			'  '.($first ? 'if' : 'else if').' (classid == '.$classid.'/*'.$classname.'*/'.
					 (scalar @clauses ? ' && ('.join(' || ',@clauses).')' : '').') {'."\n".
			'    return 1;'."\n".
			'  }'."\n";
  	$first = 0;
  }
	$ccode .= '  return 0;'."\n";
	$ccode .= '}'."\n\n";

	##############################################################################
	$ccode .= 'int classname2classid (char* classname) {'."\n";
  $first = 1;
  foreach my $classname (keys %{$self->{'classes'}}) {
  	my $classid = $self->{'classes'}->{$classname}->{'id'};  	
		$ccode .=
			'  '.($first ? 'if' : 'else if').' (streq(classname, "'.$classname.'")) {'."\n".
			'    return '.$classid.';'."\n".
			'  }'."\n";
  	$first = 0;
  }
	$ccode .= '  return -1;'."\n";
	$ccode .= '}'."\n\n";

	##############################################################################
	$ccode .= "/*-----------------------------------------------------------*/\n";
	$ccode .= "/* Types */\n\n";
	my $typedefs = '';
	my $structs  = '';
	foreach my $classname (keys %{$self->{'classes'}}) {
		my $class = $self->{'classes'}->{$classname};

		# typedef for class-specific struct pointer (member 'data' in S_Object struct)
		$typedefs .= 'typedef struct S_'.$self->_get_c_typename($classname).'* '.$self->_get_c_typename($classname).';'."\n\n";
		
		# struct for the class
		$structs .= 'struct S_'.$self->_get_c_typename($classname).' {'."\n";
		$structs .= '  int dummy'.";\n" unless scalar keys %{$class->{'attr'}};
		foreach my $attrname (sort keys %{$class->{'attr'}}) {
			my $attrtype = $class->{'attr'}->{$attrname};
			$structs .= '  '.$self->_get_c_attrtype($attrtype).' CCC_'.$attrname.";\n";
		}
		$structs .= "};\n\n";
	}
	$ccode .= $typedefs;
	$ccode .= $typescode;
	$ccode .= $structs;

	##############################################################################
	$ccode .= "/*-----------------------------------------------------------*/\n";
	$ccode .= "/* User top code */\n\n";
	$ccode .= $topcode."\n\n";

	##############################################################################
	$ccode .= $self->_generate_functions()."\n\n";

	##############################################################################
	$ccode .= "/*-----------------------------------------------------------*/\n";
	$ccode .= "/* User bottom code */\n\n";
	$ccode .= $bottomcode."\n\n";

	##############################################################################
	if (length $maincode) {
		$ccode .= "/*-----------------------------------------------------------*/\n";
		$ccode .= "/* Main function */\n\n";
		$ccode .= 'int main (int argc, char** argv) {'."\n";
		$ccode .= '  '.$maincode;
		$ccode .= "\n}\n";
	}

	open OUTFILE, '>'.$file
		or die "Error: failed to open output file '$file': $!\n";
	print OUTFILE $ccode;
	close OUTFILE;	
}

################################################################################
################################################################################
################################################################################

#-------------------------------------------------------------------------------
sub _parse_signature
#-------------------------------------------------------------------------------
{
	my ($self, $signature_string) = @_;
	
	# render(self:Square,self:Vertex,self:Point):void
	my $rs = '[\s\t\n\r]*';
	my $rn = '[^\(\)\,\:]+';
	my ($name, $args, $returns) = ($signature_string =~ /^$rs($rn)$rs\($rs(.*)$rs\)$rs\:$rs($rn)$rs$/);
	my @params = map { [split /$rs\:$rs/] } split /$rs\,$rs/, $args;

	my $sign = {
		name    => $name,
		returns => $returns,
		params  => \@params,
	};
	return $sign;
}

#-------------------------------------------------------------------------------
sub _dbg
#-------------------------------------------------------------------------------
{
	my (@msg) = @_;
	eval('use Data::Dump;');
	Data::Dump::dump(\@msg);
}

#-------------------------------------------------------------------------------
sub _get_subclasses
#-------------------------------------------------------------------------------
{
	my ($self) = @_;
	my %subclasses = ();
  foreach my $classname (keys %{$self->{'classes'}}) {
  	my $classid = $self->{'classes'}->{$classname}->{'id'};
  	$subclasses{$classname} = {} unless exists $subclasses{$classname};
  	#$subclasses{$classname}->{$classname} = 1;
    foreach my $parentclassname ($self->_get_parent_classes($classname)) {
	  	my $parentclassid = $self->{'classes'}->{$parentclassname}->{'id'};
	  	$subclasses{$parentclassname}->{$classname} = 1;
  	}
	}	
	return \%subclasses;
}

#-------------------------------------------------------------------------------
sub _autogen
#-------------------------------------------------------------------------------
{
	my ($self) = @_;
	unless ($self->{'autogen'}) {
		$self->_inherit_members();

		$self->_define_accessors();
		$self->_add_hook_code();
		$self->_define_constructors();
		$self->_define_destructors();
		$self->_define_dumpers();
		$self->{'autogen'} = 1;
	}
}

#-------------------------------------------------------------------------------
sub _generate_functions
#-------------------------------------------------------------------------------
{
	my ($self) = @_;
	
	# find all functions and store them by their name
	my %functions = (); # "<funcname>" => {"<signature>" => [...], ...}
	foreach my $classname (keys %{$self->{'classes'}}) {
		my $class = $self->{'classes'}->{$classname};
		foreach my $name (keys %{$class->{'subs'}}) {
			my $sign = $self->_parse_signature($name);
			$functions{$sign->{'name'}} = {}
				unless exists $functions{$sign->{'name'}};
			
			$functions{$sign->{'name'}}->{$name} = 
				{
					'classname' => $classname,
					'number'    => undef,
					'name'      => $name,
					'code'      => $self->{'classes'}->{$classname}->{'subs'}->{$name},
				};				
		}
	}
	# add normal functions, too
	foreach my $fname (keys %{$self->{'functions'}}) {
		my $sign = $self->_parse_signature($fname);
		$functions{$sign->{'name'}}->{$fname} = 
			{
				'classname' => undef,
				'number'    => undef,
				'name'      => $fname,
				'code'      => $self->{'functions'}->{$fname},
			};		
	}
	# give every implementation a unique number
	foreach my $fname (keys %functions) {
		my $n = 0;
		foreach my $name (keys %{$functions{$fname}}) {
			$functions{$fname}->{$name}->{'number'} = $n;
			$n++;
		}
	}

	######

	# check all overloaded functions: they are only allowed if they
	# take class-typed parameters ONLY!
	my %infos = (); # <functionname> => {...}
	foreach my $fname (keys %functions) {
		#print "($fname)\n";

		# define scheme of signature
		my $first_sign = $self->_parse_signature((keys %{$functions{$fname}})[0]);

		my $returns = 
			(exists $self->{'classes'}->{$first_sign->{'returns'}} ? 
				'Object' : $first_sign->{'returns'});

		my $all_class_types =
			(scalar(grep { exists $self->{'classes'}->{$_} } @{$first_sign->{'params'}})
				== scalar(@{$first_sign->{'params'}}) ? 1 : 0);

		my $params = [ # sequence of "Object" or "<c-type>" strings
			map { exists $self->{'classes'}->{$_->[1]} ? 'Object' : $_->[1] }
				@{$first_sign->{'params'}}
		];

		$infos{$fname} = {
			'all-class-types' => $all_class_types,
			'params-scheme' => $params,
			'returns' => $returns,
			'at-least-one-impl-has-zero-params' => 0,
			'has-only-one-implementation' => (scalar(keys %{$functions{$fname}}) == 1),
		};

		if (scalar keys %{$functions{$fname}} > 2) {
		
			# check if all signatures match the scheme
			foreach my $name (keys %{$functions{$fname}}) {
				#print "  [$name]\n";
				my $sign = $self->_parse_signature($name);
				   $sign->{'returns'} = 
						(exists $self->{'classes'}->{$sign->{'returns'}} ? 
							'Object' : $sign->{'returns'});
				
				die "Error: overloaded method '$name' does not return a valid ".
				    "return type (is '$sign->{'returns'}', must be '$returns')\n"
				  if $returns ne $sign->{'returns'};

				$infos{$name}->{'at-least-one-impl-has-zero-params'} = 1
					if scalar @{$sign->{'params'}} == 0;

				if ($all_class_types) {
					# all parameters should be class-typed
					map {
						die "Error: overloaded method '$name' is not allowed to take ".
						    "non-class typed parameters\n"
							if !exists $self->{'classes'}->{$_->[1]};					
					}
					@{$sign->{'params'}};
				}
				else {
					# the parameter list should match the $params list
					for (my $p = 0; $p < @{$params}; $p++) {
						my $paramtype  = $params->[$p];
						die "Error: overloaded method '$name' does not ".
						    "follow the scheme 'method(".join(',',@{$params})."):$returns'\n"
							if 
							  ($p > scalar @{$sign->{'params'}} - 1) ||
							  ($paramtype eq 'Object' && 
							   !exists $self->{'classes'}->{$sign->{'params'}->[$p]->[1]}) || 
							  ($paramtype ne 'Object' &&
							   $paramtype ne $sign->{'params'}->[$p]->[1]);
					}
				}
			}
		}
	}
	
	# generate c code
	my $protos = ''; # prototypes for implementation functions
	my $impls  = ''; # implementation functions
	
	foreach my $fname (sort keys %functions) {
		my $info = $infos{$fname};

		my $first_impl_name = (keys %{$functions{$fname}})[0];
		my $first_sign = $self->_parse_signature($first_impl_name);

		$protos .= 
			$info->{'returns'}.' '.$fname.' ('.
				$self->_generate_params_declaration($first_impl_name).');'."\n";

		$impls .=
			$info->{'returns'}.' '.$fname.' ('.
				$self->_generate_params_declaration($first_impl_name).') {'."\n";
		
		my $first = 1;
		for my $name (keys %{$functions{$fname}}) {
			$impls .=
				'  '.($first ? '' : 'else ').'if '.
					'('.$self->_generate_wrapper_select_clause($name).') {'."\n".
				'    #if CREATE_STACK_TRACE'."\n".
				'		   logStackTraceEntry("'.$name.'");'."\n".
				'    #endif'."\n".
				'    {'."\n".
				'      '.$functions{$fname}->{$name}->{'code'}."\n".
				'    }'."\n".
				'  }'."\n";
			$first = 0;
		}
		
		$impls .= '  else {'."\n";
		$impls .= '    printf("Error: Failed to find an implementation of function/method \''.$fname.'\'.\n");'."\n";
		$impls .= '    #if CREATE_STACK_TRACE'."\n";
		$impls .= '      printStackTrace();'."\n";
		$impls .= '    #endif'."\n";
		$impls .= '    printf("The parameters passed were:\n");'."\n";
		my $p = 0;
		for my $param (@{$first_sign->{'params'}}) {
			my $paramname = $param->[0];
			my $paramtype = $param->[1];
			if (exists $self->{'classes'}->{$paramtype}) {
				$impls .= '    printf(" ['.$p.'] = %s\n", '.$paramname.'->classname);'."\n";
			} else {
				$impls .= '    printf(" ['.$p.'] = '.$paramtype.'\n");'."\n";			
			}
			$p++;
		}
		$impls .= '    exit(0);'."\n";
		$impls .= '  }'."\n";
		$impls .= '}'."\n\n";
	}
	
	return
		"/*-----------------------------------------------------------*/\n".
		"/* Prototypes for implementation functions */\n\n".
		$protos."\n".

		"/*-----------------------------------------------------------*/\n".
		"/* Implementation functions */\n\n".
		$impls."\n";
}

#-------------------------------------------------------------------------------
sub _generate_wrapper_select_clause
#-------------------------------------------------------------------------------
{
	my ($self, $implname, $use_isa) = @_;
	my $sign = $self->_parse_signature($implname);
	my @clauses = ();
	my $p = 0;
	foreach my $param (@{$sign->{'params'}}) {
		my $paramname = $param->[0];
		my $paramtype = $param->[1];
		if (exists $self->{'classes'}->{$paramtype}) {
			my $class = $self->{'classes'}->{$param->[1]};
			push @clauses, 
				($p > 0 ?
					'('.$paramname.' == NULL || isa('.$paramname.'->classid, '.$class->{'id'}.'/* '.$paramtype.' */))' :
					$paramname.'->classid == '.$class->{'id'}.'/* '.$paramtype.' */');
		}
		$p++;
	}
	return (scalar @clauses ? join(' && ',@clauses) : '1');	
}

#-------------------------------------------------------------------------------
sub _generate_params_declaration
#-------------------------------------------------------------------------------
{
	my ($self, $implname) = @_;
	my $sign = $self->_parse_signature($implname);
	my @params = ();
	foreach my $param (@{$sign->{'params'}}) {
		my $paramtype = 
			(exists $self->{'classes'}->{$param->[1]} ? 'Object' : $param->[1]);
		push @params, $paramtype.' '.$param->[0];
	}
	return (scalar @params ? join(', ', @params) : 'void');		
}

#-------------------------------------------------------------------------------
sub _init
#-------------------------------------------------------------------------------
{
	my ($self, %opts) = @_;

	$self->{'classes'} = {};
	$self->{'functions'} = {};

	# if attributes/methods etc. have been auto-generated
	$self->{'autogen'} = 0;
	
	# prefix for type names created by this module
	$self->{'prefix-types'} = 'T_';
	
	# code areas that can be filled as classes are parsed/read
	$self->{'area'} = {
		'top' => '',
		'bottom' => '',
	};
	
	return $self;
}

# inherits all members from parent classes
#-------------------------------------------------------------------------------
sub _inherit_members
#-------------------------------------------------------------------------------
{
	my ($self) = @_;	
	# copy all inherited members from the parent classes
	foreach my $classname (keys %{$self->{'classes'}}) {
		my $class = $self->{'classes'}->{$classname};
		foreach my $parentclassname ($self->_get_parent_classes($classname)) {
			my $parentclass = $self->{'classes'}->{$parentclassname};
			foreach my $membertype (qw(attr subs after before)) {
				foreach my $membername (keys %{$parentclass->{$membertype}}) {
					if ($membertype eq 'attr' && exists $class->{$membertype}->{$membername}) {
						die "Error: inherited attribute '$membername' in class $classname must be of the same type as in class '$parentclassname'\n"
							if $class->{$membertype}->{$membername} ne $parentclass->{$membertype}->{$membername};
					}
	
					my $orig_membername = $membername;
					if ($membertype eq 'subs') {
						my $sign = $self->_parse_signature($membername);
						$sign->{'params'}->[0]->[1] = $classname;
						$membername = $self->_signature_to_string($sign);
					}
					
					unless (exists $class->{$membertype}->{$membername}) {
						$class->{$membertype}->{$membername} = 
							$parentclass->{$membertype}->{$orig_membername};
					}
				}
			}
		}
	}	
}

#-------------------------------------------------------------------------------
sub _add_hook_code
#-------------------------------------------------------------------------------
{
	my ($self) = @_;
	foreach my $hooktype (qw(before after)) {
		foreach my $classname (keys %{$self->{'classes'}}) {
			my $class = $self->{'classes'}->{$classname};
			foreach my $methname (keys %{$class->{$hooktype}}) {
				next if $methname eq 'new' || $methname eq 'delete';
				
				my $methods = $self->_get_methods_by_name($class, $methname);
				die "Error: $hooktype-hook for $classname.$methname cannot be installed, ".
						"because no method with that name exists in $classname.\n"
					unless scalar keys %{$methods};
				
				# add hook code
				foreach my $meth (keys %{$methods}) {
					if ($hooktype eq 'before') {
						$class->{'subs'}->{$meth} = 
							"{\n".$class->{$hooktype}->{$methname}."\n}\n".$class->{'subs'}->{$meth};
					}
					elsif ($hooktype eq 'after') {
						$class->{'subs'}->{$meth} = 
							$class->{'subs'}->{$meth}."{\n".$class->{$hooktype}->{$methname}."\n}\n";
					}
				}
			}
		}
	}
}

# finds all methods in a class with the same name
#-------------------------------------------------------------------------------
sub _get_methods_by_name
#-------------------------------------------------------------------------------
{
	my ($self, $class, $methname) = @_;
	my %subs = ();
	foreach my $s (keys %{$class->{'subs'}}) {
		my $sign = $self->_parse_signature($s);
		$subs{$s} = $class->{'subs'}->{$s}
			if $sign->{'name'} eq $methname;
	}
	return \%subs;
}

#-------------------------------------------------------------------------------
sub _define_constructors
#-------------------------------------------------------------------------------
{
	my ($self) = @_;
	foreach my $classname (keys %{$self->{'classes'}}) {
		my $class = $self->{'classes'}->{$classname};
		
		$self->func(
			'new_'.ucfirst($classname).'():Object',

			'Object self = NULL;'."\n".
			
			# pre hook
			(exists $class->{'before'}->{'new'} ?
				"{\n".$class->{'before'}->{'new'}."\n}\n" : '').
			
			"{\n".
			'  self = (Object)malloc(sizeof(struct S_Object));'."\n".
			'  if (self == (Object)NULL) {'."\n".
			'    printf("Failed to allocate memory for instance of class \''.$classname.'\'\n");'."\n".
			'    exit(1);'."\n".
			'  }'."\n".
			'  self->classid = '.$class->{'id'}.';'."\n".
			'  setstr(self->classname, "'.$classname.'");'."\n".
			'  self->data = malloc(sizeof(struct S_'.$self->_get_c_typename($classname).'));'."\n".
			'  if (self->data == NULL) {'."\n".
			'    printf("Failed to allocate memory for instance-data of class \''.$classname.'\'\n");'."\n".
			'    exit(1);'."\n".
			'  }'."\n".
			join('',
				map {
					my $attrtype = $class->{'attr'}->{$_};
					($attrtype eq 'pthread_mutex_t' ?
						'' :
						'  (('.$self->_get_c_typename($classname).')(self->data))->CCC_'.$_.
							' = '.$self->_get_init_c_code($attrtype).';'."\n");
				}
				sort keys %{$class->{'attr'}}
			).
			"}\n".

			# post hook
			(exists $class->{'after'}->{'new'} ?
				"{\n".$class->{'after'}->{'new'}."\n}\n" : '').
			'  return self;'."\n"
		);
	}
}

#-------------------------------------------------------------------------------
sub _define_dumpers
#-------------------------------------------------------------------------------
{
	my ($self) = @_;
	foreach my $classname (keys %{$self->{'classes'}}) {
		my $class = $self->{'classes'}->{$classname};
		
		my $funcsign = 'dump(self:'.$classname.',level:int,maxLevel:int):void';
		next if exists $self->{'functions'}->{$funcsign};
		
		$self->func(
			$funcsign,

			# pre hook
			(exists $class->{'before'}->{'dump'} ?
				"{\n".$class->{'before'}->{'dump'}."\n}\n" : '').

			"{\n".
			'  int i;'."\n".
			'  char indent[256];'."\n".
			'  indent[0] = \'\\0\';'."\n".
			'  for (i = 0; i < level; i += 1) {'."\n".
			'    strcat(indent, "    ");'."\n".
			'  }'."\n".
			
			'if (level <= maxLevel && maxLevel <= 64) {'."\n".			
			
			'  if (self == NULL) {'."\n".
			'  	 printf("%s(NULL)\n", indent);'."\n".
			'  }'."\n".
			'  else {'."\n".
			
				'  printf("%s{'.$classname.' #'.$class->{'id'}.'\n", indent);'."\n".
				join('',
					map {
						my $s = '  printf("%s  .'.$_.' <'.$class->{'attr'}->{$_}.'> = ", indent);'."\n";			
						if (exists $self->{'classes'}->{$class->{'attr'}->{$_}}) {
							$s .= 
								'  printf("\n");'.
								'  if (get'.ucfirst($_).'(self) == NULL)'."\n".
								'  	 printf("%s    (NULL)\n", indent);'."\n".
								'  else '."\n".
								'    dump(get'.ucfirst($_).'(self),level+1,maxLevel);'."\n";			
						}
						elsif ($class->{'attr'}->{$_} eq 'float') {
							$s .= '  printf("%f\n", get'.ucfirst($_).'(self));'."\n";									
						}
						elsif ($class->{'attr'}->{$_} eq 'int') {
							$s .= '  printf("%d\n", get'.ucfirst($_).'(self));'."\n";									
						}
						elsif ($class->{'attr'}->{$_} eq 'long int') {
							$s .= '  printf("%ld\n", get'.ucfirst($_).'(self));'."\n";									
						}
						elsif ($class->{'attr'}->{$_} eq 'char') {
							$s .= '  printf("%d / \'%c\'\n", get'.ucfirst($_).'(self), get'.ucfirst($_).'(self));'."\n";									
						}
						elsif ($class->{'attr'}->{$_} eq 'char*') {
							$s .= '  printf("\'%s\'\n", get'.ucfirst($_).'(self));'."\n";									
						}
						else {
							$s .= '  printf("?\n");'."\n";									
						}
						$s;
					}
					sort keys %{$class->{'attr'}}
				).
				'  printf("%s}\n", indent);'."\n".
				
			'  }'."\n".
			"}\n".
			
			'else {'."\n".
			'  printf("%s...\n", indent);'."\n".
			"}\n".

			"}\n".

			# post hook
			(exists $class->{'after'}->{'dump'} ?
				"{\n".$class->{'after'}->{'dump'}."\n}\n" : '')			
		);
	}
}

#-------------------------------------------------------------------------------
sub _get_init_c_code
#-------------------------------------------------------------------------------
{
	my ($self, $attrtype) = @_;
	return 
		(exists $self->{'classes'}->{$attrtype} ? 
			'(Object)NULL' :
			($attrtype eq 'pthread_mutex_t' ?
				'(pthread_mutex_t)PTHREAD_MUTEX_INITIALIZER' :
				'('.$attrtype.')0'));
}

#-------------------------------------------------------------------------------
sub _define_destructors
#-------------------------------------------------------------------------------
{
	my ($self) = @_;
	foreach my $classname (keys %{$self->{'classes'}}) {
		my $class = $self->{'classes'}->{$classname};
		
		$self->func(
			'delete(self:'.$classname.'):void',
				
			# pre hook
			(exists $class->{'before'}->{'delete'} ?
				"{\n".$class->{'before'}->{'delete'}."\n}\n" : '').

			'free(('.$self->_get_c_typename($classname).')(self->data));'."\n".
			'free(self);'."\n".

			# post hook
			(exists $class->{'after'}->{'delete'} ?
				"{\n".$class->{'after'}->{'delete'}."\n}\n" : '')
		);
	}
}

#-------------------------------------------------------------------------------
sub _define_accessors
#-------------------------------------------------------------------------------
{
	my ($self) = @_;
	foreach my $classname (keys %{$self->{'classes'}}) {
		my $class = $self->{'classes'}->{$classname};
		foreach my $attrname (keys %{$class->{'attr'}}) {
			#my $attrtype = $self->_get_c_attrtype($class->{'attr'}->{$attrname});
			my $attrtype = $class->{'attr'}->{$attrname};

			# getter
			$self->meth(
				$classname,
				'get'.ucfirst($attrname).'():'.$attrtype,
				'return (('.$self->_get_c_typename($classname).')(self->data))->CCC_'.$attrname.';',
			);

			# getter to pointer
			$self->meth(
				$classname,
				'get'.ucfirst($attrname).'Ptr():'.
					(exists $self->{'classes'}->{$attrtype} ? 'Object' : $attrtype).'*',
				
				'return &((('.$self->_get_c_typename($classname).')(self->data))->CCC_'.$attrname.');',
			);

			# setter
			$self->meth(
				$classname,
				'set'.ucfirst($attrname).'(value:'.$attrtype.'):void',
				'(('.$self->_get_c_typename($classname).')(self->data))->CCC_'.$attrname.' = value;',
			);
			
			# setter for pointer
			$self->meth(
				$classname,
				'set'.ucfirst($attrname).'Ptr(value:'.
					(exists $self->{'classes'}->{$attrtype} ? 'Object' : $attrtype).'*):void',
					
				'if (value == NULL) { printf("In set'.ucfirst($attrname).'Ptr(): cannot handle NULL pointer\n"); exit(1); }'."\n".
				'(('.$self->_get_c_typename($classname).')(self->data))->CCC_'.$attrname.' = *value;',
			);			
		}
	}
}

#-------------------------------------------------------------------------------
sub _get_c_typename
#-------------------------------------------------------------------------------
{
	my ($self, $type) = @_;
	return (exists $self->{'classes'}->{$type} ? $self->{'prefix-types'}.$type : $type);
}

#-------------------------------------------------------------------------------
sub _get_c_attrtype
#-------------------------------------------------------------------------------
{
	my ($self, $attrtype) = @_;
	return (exists $self->{'classes'}->{$attrtype} ? 'Object' : $attrtype);
}

#-------------------------------------------------------------------------------
sub _signature_to_string
#-------------------------------------------------------------------------------
{
	my ($self, $sign) = @_;
	return
		$sign->{'name'}.
		'('.join(',',map { $_->[0].':'.$_->[1] } @{$sign->{'params'}}).'):'.
		$sign->{'returns'};
}

#-------------------------------------------------------------------------------
sub _load_code_from_file
#-------------------------------------------------------------------------------
{
	my ($self, $code) = @_;	
	$code = '' unless defined $code;
	if (($code =~ /^\.?\.?\/[^\*]/) || ($code !~ /\n/ && -f $code && -r $code)) {
		open SRCFILE, $code or die "Error: cannot open source file '$code': $!\n";
		$code = join '', <SRCFILE>;
		close SRCFILE;
	}
	$code =~ s/^[\s\t\n\r]*//g;
	$code =~ s/[\s\t\n\r]*$//g;
	$code =~ s/(\r?\n\r?)([^\s])/$1  $2/g;
	
	# experimental: replace "//..." comments with "/*...*/"
	$code =~ s/\/\/+(.*)$/\/*$1*\//mg;
	
	return $code;
}

#-------------------------------------------------------------------------------
sub _get_parent_classes
#-------------------------------------------------------------------------------
{
	my ($self, $classname) = @_;
	my @parents = ();
	my @parents_parents = ();
	my $class = $self->{'classes'}->{$classname};
	foreach my $name (@{$class->{'isa'}}) {
		push @parents, $name;
		push @parents_parents, $self->_get_parent_classes($name);
	}
	push @parents, @parents_parents;
	# delete dublicates
	my @clean = ();
	map {
		my $x = $_;
		push(@clean, $x) unless scalar(grep { $x eq $_ } @clean);
	} 
	@parents;
	return @clean;
}

#-------------------------------------------------------------------------------
1;
__END__

=head1 NAME

Code::Class::C - Perl extension for creating ANSI C code from a set
of class definitions to accomplish an object-oriented programming style.

=head1 SYNOPSIS

  use Code::Class::C;
  my $gen = Code::Class::C->new();
  
  $gen->class('Shape',
    subs => {
      'getLargest(s:Shape):Shape' => 'c/Shape.getLargest.c',
      'calcArea():float' => q{
        return 0.0;
      },
    },
  );
  
  $gen->class('Circle',
    isa => ['Shape'],
    attr => {
      'radius' => 'float',
    },
    subs => {
      'calcArea():float' => q{
        return 3.1415 * getRadius(self) * getRadius(self);
      },
    },
  );

=head1 DESCRIPTION

This module lets you define a set of classes (consisting of
attributes and methods) and then convert these definitions
to ANSI C code. The module creates all the object oriented 
abstractions so that the application logic can be programmed
in an object oriented fashion (create instances of classes,
access attributes, destroy instances, method dispatch etc.).

=head2 Constructor

=head3 new()

  my $gen = Code::Class::C->new();
  
The constructor of Code::Class::C takes no arguments and returns
a new generator instance with the following methods.

=head2 Methods

=head3 class( I<name>, I<options> )

The class() method lets you define a new class:

  $gen->class('Circle',
    isa => ['Shape'],
    attr => {
      'radius' => 'float',
    },
    subs => {
      'calcArea():float' => q{
        return 3.1415 * getRadius(self) * getRadius(self);
      },
    },
    after => {
    	'new' => q{...},
    	# ...
    },
    top => q{...},
    bottom => q{...},
  );

The class() method takes as first argument the name of the class.
The name has to start with a capitol letter and may be followed
by an arbitrary amount of letters, numbers or underscore (to be
compatible with the ANSI C standard).

The special class name I<Object> is not allowed as a classname.
A classname must not be longer than 256 characters.

After the first argument the optional parameters follow
in any order:

=head4 isa => I<Arrayref of classnames>

The C<isa> option lets you specify zero or more parent classes of the class
that is to be defined.

=head4 attr => I<Hashref of attributes>

The C<attr> option lets you define the attributes of the class that
is to be defined. 

The hash key is the name of the attribute
(starting with a small letter and followed by zero or more
letters, numbers or underscore; note: attribute names are case-insensitive).

The hash value is the C-type of the attribute.
Here you can use basic C types OR class names (because each class becomes
available as a native C type when the C code is generated).

=head4 subs => I<Hashref of methods>

The C<subs> option lets you define the methods of the class that is to
be defined.

The hash key is the signature of the method, e.g.

  calcArea(float x, MyClass y):int

The hash value is the C sourcecode of the method (s.b. for details).
The hash value can optionally be a filename. In this case, the file's
content is used as the method's body.

=head4 top => I<C code or filename>
=head4 bottom => I<C code or filename>

This defines arbitrary C code that is included in the top/bottom
area of the generated C source.

=head4 after => <hashref>
=head4 before => <hashref>

This option defines post and pre hooks for specific methods.
For example:

  after => {
    'new' => q{...},
    'myMethod' => q{...},
  }

This defines two post hooks, one for the constructor and
the second for a method named 'myMethod'. Ths hook code is
inserted into the methods it is defined for inside an own
C code block (C<{ ... }>) so hook-local C variables can
be defined as if it would be a function. Also all the parameters
of the function can be accessed like in the actual method code.

=head3 attr( I<classname>, I<attribute-name>, I<attribute-type> )

Defines an attribute in a class with the given name and type.

  $gen->attr('Shape','width','float');

=head3 meth( I<classname>, I<method-signature>, I<c-code> )

Defines a method in a class of the given signature using the
given piece of C code (or filename).

  $gen->meth('Shape','calcArea():float','...');

=head3 parent( I<classname>, I<parent-classname>, ... )

Defines the parent class(es) of a given class.

  $gen->parent('Shape','BaseClass1','BaseClass2');

=head3 after( I<classname>, I<method-signature>, I<c-code> )

Defines a post hook for a method. The hook code is inserted into
the method it is defined on, at the end of the method.

See below for special hook names.

=head3 before( I<classname>, I<method-signature>, I<c-code> )

Defines a pre hook for a method. The hook code is inserted into
the method it is defined on, at the beginning of the method.

The special hook names are:

=over 1

=item * new: The hook is attached to the constructor function.

=item * delete: The hook is attached to the destructor function.

=back

To illustrate this, here is an example of a hook that is
installed after the constructor:

  $gen->after('new', q{printf("This is called when the object was constructed.\n");});

  $gen->before('new', q{printf("This is called when the object is about to be constructed.\n");});

A few things about constructor and destructor hooks should be noted:
The before-new hook is called before the object (C variable "self") is
created, so no manipulation of self can be done. The after-new hook
however can access the self variable.

Also, the post-delete hook can access the self variable, but should be aware
that it has already been free'd.

=head3 readFile( I<filename> )

readFile() takes one argument, a filename, loads this file and extracts
class, attribute and method definitions from it.

  $gen->readFile('c/Triangle.c');

Here is an example file:

  //------------------------------------------------------------------------------
  @class Triangle: Shape, Rectangle

  //------------------------------------------------------------------------------
  @top
  
  	// this code is appended to the top-area of the generated C source
  
  //------------------------------------------------------------------------------
  @bottom
  
  	// this code is appended to the top-area of the generated C source
  
  //------------------------------------------------------------------------------
  @attr prop:int
  
  //------------------------------------------------------------------------------
  // calculates the area of the triangle
  //
  @sub calcArea():float
  
  return self->width * self->height;
  
  //------------------------------------------------------------------------------
  // calculates the length of the outline of the triangle
  //
  @sub calcOutline():float
  
  return getWidth(self) * 2 + getHeight(self) * 2;

  //------------------------------------------------------------------------------
  @after new
  
  	// this code is called in the constructor at the end
  	
  //------------------------------------------------------------------------------
  @before calcArea

		// this code is called in the method 'calcArea' at the beginning

A line starting with '//' is ignored.
A line that starts with an '@' is treated as a class or
attribute definition line or as the start of a method definition.
I hope this is self-explanatory?

Such files can be saved with an ".c" extension so that you can open
them in your favourite C code editor and have fun with the highlighting.

=head3 func( I<signature>, I<c-code-or-filename> )

The func() method defines a normal C function.
It takes as parameters the signature of the function and the code
(which can be a code string or a filename):

  $gen->func('doth(float f, Shape s):int', '/* do sth... */');

=head3 generate( I<options> )

  $gen->generate(
    file    => './main.c',
    globalheaders => ['stdio','stdlib'],
    localheaders => ['opengl'],
    main    => 'c/main.c',
    top     => 'c/top.c',
    bottom  => 'c/bottom.c',
    debug   => 1,
  );

The generate() method generates a single ANSI C compliant source file
out of the given class definitions.

The options are:

=head4 file => I<filename>

This defines the name of the C output file.
This option is mandatory.

=head4 headers => I<Arrayref of headernames>

This defines C headers that are to be included in the generated C file.

=head4 main => I<Source or filename of main function body>

This defines the body (C code) of the main function of the generated
C file. This can be either C code given as a string OR a filename
which is loaded.

=head4 top => I<Source or filename of C code>

This method adds arbitrary C code to the generated C file. The code
is added after the class structs/typedefs and before the method (function)
declarations.

=head4 bottom => I<Source or filename of C code>

This method adds arbitrary C code to the generated C file. The code
is added to the end of the file, but before the main function.

=head4 debug => I<1/0>

If the debug option is set to 1, then a stack trace is created
and printed when a method could not be dispatched. This is handy
for debugging but has a negative effect on the performance (due to
the logbook that has to be maintained during runtime). Default is 0,
so no stack trace is created and the normal message is printed.

=head3 toDot()

This method generates a Graphviz *.dot string out of the class hierarchy
and additional information (attributes, methods). The dot string is
returned.

=head3 toHtml()

This method creates a HTML API documentation to the class hierarchy that
is defined. The HTML string is returned.

=head2 Object oriented features & C programming style

Throughout this document the style of programming that module lets the
programmer use, is called I<object oriented>, but this is just the canonical
name, actually it is I<class oriented> programming.

So you have defined a bunch of classes with attributes and methods.
But how do you program the method logic in C? This module promises
to make it possible to do this in an object-oriented fashion,
so this is the section where this fashion is described.

For a more complete example, see the t/ directory in the module
dictribution.

=head3 Class definition

This module lets you define classes and their methods and attributes.
Class definition is not possible from within the C code.

=head3 Instanciation

Arbitrary instances of classes can be created from within the C code.

Suppose you defined a class named 'Circle'. You can then create an
instance of that class like so (C code):

  Object c = new_Circle();

Important: B<All class instances in C are of the type "Object">!

There exists a type alias for the "Object" type named "my", so
C code can be written a little more "Perl-like", e.g.:

  my c = new_Circle();

=head3 Instance destruction

Since there is a way to create instances, there is also a way to
destroy them (free the memory they occupy).

A generic C function delete() is generated which can be used to
destruct any object/instance:

  Object c = new_Circle();
  delete(c); // c now points to NULL

=head3 Instance print to STDOUT

The automatically generated C function dump() will print the
content of any class instance to STDOUT:

  dump(myObject, 0, 2);

The first parameter is the object, the second the current level
(always 0) and the second the maximum level to print.

=head3 Inheritance

A class inherits all attributes and methods from its parent class or classes.
So multiple inheritance (multiple parent classes) is allowed.

=head3 Attribute access

Suppose you defined a class named 'Circle' with an attribute
(could also be inherited). Then you can access this attribute
the following:

  float r;
  float* r_ptr;
  int x = 42.0;
  Object c = new_Circle();
  r = getRadius(c);
  r_ptr = getRadiusPtr(c);
  
  setRadius(c, x);
  setRadiusPtr(c, &x);

As you can see, all methods (either getter or setter or other ones)
need to get the object/instance as first parameter.
B<This "self" parameter need not be written when defining the method>,
remember to define a method, only the B<addtional> parameters
are to be written:

  calcArea(int param):float

Remember: B<Always access the instance/object attributes via the
getter or setter methods!>.

=head3 Attribute overloading

Attributes once defined, must not be re-defined by child classes.

=head3 Method invocation

To invoke a method on an object/instance:

  Object c = new_Circle();
  printf("area = %f\n", calcArea(c));

The first argument of the method call is the object/instance the
method is invoked on.

=head3 Method overloading

Methods once defined, can be overloaded by methods of the same class.
Methods in a class can also be re-defined by child classes.

If a child class overwrites the method of one of its parent classes,
the signatures must be the same, B<regarding the non-class typed parameters>.

To illustrate this, here is an example of a parent class method
signature: C<doSth(Shape s, float f):void> - the first parameter is an object
of class 'Shape', the second a native C float.

Suppose another classes tries to overwrite this method. In this case the
first parameter's type is allowed to change (to any other class type!),
but the second not, because its a native type. This will work:
C<doSth(Circle s, float f):void> but this not: C<doSth(int s, float f):void>

=head3 Access "self" from within methods

When writing methods you need access to the object instance.
This variable is "magically" available and is named "self".
Here is an example of a method body:

  printf("radius of instance is %f\n", getRadius(self));

=head3 Default attributes

The following attributes are present in all classes. These attributes
differ compared to user-defined attributes in the way that they can
be accessed directly by dereferencing the instance/object pointer:

=head4 I<int> classid

Each class has a globally unique ID, a positive number greater than zero.

  Object c = new_Circle();
  printf("c.classid = %d\n", c->classid);

=head4 I<char*> classname

This is the name of the class of the object/instance.
To access the classname, use accessor methods like for all
other attributes, e.g.:

  Object c = new_Circle();
  printf("c.classname = %s\n", c->classname);

Beware, that, when you change the classname at runtime, methods may not be able
to determine the actual implementation of a method to be applied to an
object/instance.

=head2 LIMITATIONS & BUGS

This module is an early stage of development and has therefor some
limitations and bugs. If you think, this module needs a certain feature,
I would be glad to hear from you, also, if you find a bug, I would be
glad to hear from you.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Please send any hints on other modules trying to accomplish the same
or a similar thing. I haven't found one, yet.

=head1 AUTHOR

Tom Kirchner, E<lt>tom@tomkirchner.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Tom Kirchner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
