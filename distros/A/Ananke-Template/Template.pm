#!/usr/bin/perl

package Ananke::Template;
use strict;

our $VERSION = '1.4'; 
my @my;

# Processo para facilitar o print do template
sub view_template {
	my ($template_dir,$template_file,$vars,$to_file) = @_;
	my $return;

	my $template = new Ananke::Template($template_dir);
	$return = $template->process($template_file,$vars,$to_file);

	return $return if ($to_file == 1);

	undef $template_dir; undef $template_file; undef $vars;
	undef $template; undef $to_file;
}

# Inicia modulo
sub new {
	my($self,$templ_dir,$to_file) = @_;

	# Grava dados
	bless {
		'TEMPL_DIR' => $templ_dir,
	}, $self;
}

# Processa página
sub process {
	my($self,$file,$vars,$to_file) = @_;
	my($fdata,$output,$my,$return);
	$self->{TEMPL_FILE} = $file;
	
	# Retorna em var, sprintf
	if ($to_file == 1) {
		$self->{TO_RETURN} = 1;
		undef $to_file;
	}
	
	$self->{TO_FILE} = $to_file;
	@my = ();

	$fdata = $self->load();
	$output = $self->parse($fdata,$vars);

	#$my = "my \$return;\n";
	
	foreach (@my) {
		$my .=  $_->{value};
	}

	$output = $my.$output;
	$return = eval $output;
	#print $output."\n";

	print $@ if ($@);

	return $return if ($self->{TO_RETURN});

	#open (FH,">/tmp/filexx");
	#syswrite(FH,$output);
	#close(FH);
}

# Trata arquivo
sub parse {
	my($self,$fdata,$vars) = @_;
	my(@t,$ndata,$output);
	my $outype;
	
	if ($self->{TO_FILE}) {
		$output .= "open(OUTFILE,\">".$self->{TO_FILE}."\");";
		$outype = "OUTFILE";
	} else {
		$outype = "STDOUT";
	}

	# Transfere dados para vars
	foreach (keys %{$vars}) {
		push(@my,{
			var	=> "\$T$_",
			value => "my \$T$_ = \$vars->{$_};\n"
		});
	}
	
	# Adiciona \ em caracteres nao permitidos
	my $Tstart = quotemeta("[%");
	my $Tend = quotemeta("%]");

	# Faz o primeiro parse
	while ($fdata) {

		# Verifica parse
		if ($fdata =~ s/^(.*?)?(?:$Tstart\s?(.*?)\s?$Tend)//sx) {

			$t[1] = $1; $t[2] = $2;
			$t[1] =~ s/[\n|\s]//g if ($t[1] =~ /^[\n\s]+$/);

			# Nao executa linhas comentadas e espacos desnecessarios
			$t[2] =~ s/^\s+?\#\s+(.*?)\s+?$//g;
			$t[2] =~ s/^\s+?(.*?)\s+?$/$1/g;

			if ($t[1]) {
				$t[1] = "\nsyswrite($outype,\"".&AddSlashes($t[1])."\");";
			}
		
			# Retira espaços em branco no começo e final da var
			$t[2] =~ s/^[ ]+?(.*)[ ]+?$/$1/s;
		
			# Trata if e elsif
			if ($t[2] =~ /^(IF|ELSIF|UNLESS)\s+(.*)$/i) {
				$t[3] = lc($1);
				$t[4] = $2;
				$t[4] =~ s/AND/\&\&/g; $t[4] =~ s/OR/\|\|/g;
			
				$t[3] = "} ".$t[3] if ($t[3] eq "elsif");
		
				# Trata todos os tipos de vars
				while ($t[4] =~ /([\s\>\<\=\%\!\&\|]+)?([\&\;\w\"\'\.\+\-\/\^\$\á\é]+)([\&\>\<\=\%\!\|\&]+)?/g) {
					$t[5] = $1; $t[6] = $2; $t[7] = $3;

					# Verifica qual metodo de comparacao deve usar
					$t[5] =~ s/\=\=/eq/g; $t[5] =~ s/\!\=/ne/g;
					$t[7] =~ s/\=\=/eq/g; $t[7] =~ s/\!\=/ne/g;

					# vars scalares
					#if ($t[6] =~ /^(\w+)\.(\w+)$/) {
					#	$t[6] = "\$T".$1."->{$2}";
					#	$self->my("\$T".$1."->{$2}");
					#}

  	        		# Trata hash
         		if ($t[6] =~ /(\w+)\.(\w+).?(\w+)?/) {
						$self->my("\$T".$1."->{$2}");
		           	$t[6]  = "\$T".$1."->{".$2."}";
            		$t[6] .= "->{".$3."}" if ($3);
					}

					# Numeros
					elsif ($t[6] =~ /^([\d]+)$/) {
						$t[6] = $1;
					}
				
					# Demais variaveis
					elsif ($t[6] =~ /^(\w+)$/) {
						$self->my("\$T".$t[6]);
						$t[6] = "\$T".$t[6];
					}
					
					# String
					elsif ($t[6] =~ /^([\w\"\']+)$/) {
						$t[6] = $1;
					}
					
					# vars normais
					#else {
					#}

					$t[8] .= $t[5].$t[6].$t[7];
				}

				$t[2] = "\n".$t[3]." (".$t[8].") {";

				# Verifica que tipo de comparacao deve usar
				if ($t[2] =~ /\s(eq|ne)\s\//) {
					if ($1 eq "eq") { $t[2] =~ s/ eq / =~ /g; }
					elsif ($1 eq "ne") { $t[2] =~ s/ ne / !~ /g; }
				}

				undef $t[3]; undef $t[4]; undef $t[5];
				undef $t[6]; undef $t[7]; undef $t[8];
			}

			# Trata for
			elsif ($t[2] =~ /(FOR)\s(.*)/) {
				$t[8] = $1;
				$t[3] = $2;
	
				# Trata opcoes do for
				while ($t[3] =~ /([\;])?([\w\.\+\-]+)([\<\=\>\!]+)?/g) {
					$t[4] = $2; $t[5] = $3; $t[6] = $1;
					$t[6] =~ s/\=\=/eq/g; $t[6] =~ s/\!\=/ne/g;
					
					# Trata numeros
					if ($t[4] =~ /^[0-9]+$/) {
						$t[4] = $t[4];
					}
					
					# Trata hash
					elsif ($t[4] =~ /^(\w+)\.(\w+)$/) {
						$self->my("\$T".$1."->{$2}");
						$t[4] = "\$T".$1."->{$2}";
					} 
					
					# Trata vars
					else {
						$self->my("\$T".$t[4]);
						$t[4] = "\$T".$t[4];
					}

					$t[7] .= "$t[6]$t[4]$t[5]";
				}

				$t[2] = "\n".lc($t[8])." (".$t[7].") {";
				
				undef $t[3]; undef $t[4]; undef $t[5];
				undef $t[6]; undef $t[7]; undef $t[8];
			}

			# Trata foreach
			elsif ($t[2] =~ /(FOREACH) (.*) = (.*)/i) {
				
				# Seta vars do if
				$t[3] = $1; $t[4] = $2; $t[5] = $3;

				# Verifica se é array
				if (ref $vars->{$t[5]} eq "ARRAY") {
					$t[2] = "\n".lc($t[3])." my \$T$t[4] (\@{\$T$t[5]}) {";
					$self->my("\@T$t[5]");
				}

				# Verifica se e' multi-array
				elsif ($t[5] =~ /^(.*)\.(.*)$/) {
					$t[2] = "\n".lc($t[3])." my \$T$t[4] (\@{\$T$1->\{$2\}}) {";
				}

				# Caso nao exista array
				else {
					$t[2] = "\n".lc($t[3])." my \$T$t[4] (\@\{0\}) {";
				}

				# apaga vars do if
				undef $t[3]; undef $t[4]; undef $t[5];
			}

			# Fecha sintaxy
			elsif ($t[2] eq "END") {
				$t[2] = "\n}";
			}

			# Else
			elsif ($t[2] eq "ELSE") {
				$t[2] = "\n} else {";
			}

			# Adiciona include
			elsif ($t[2] =~ /^INCLUDE\s+(.*)$/) {
				$t[3] = $1;

				$t[3] =~ s/^\!(.*)$/$vars->{$1}/g;
			
				# Verifica se arquivo existe para dar include
				if (-f $self->{TEMPL_DIR}."/".$t[3]) {
				   $ndata = $self->load($t[3]);
					$t[2] = $self->parse($ndata,$vars);
				} else {
					$t[2] = undef;
				}
			}

			# Trata hash
			elsif ($t[2] =~ /(\w+)\.(\w+).?(\w+)?/) {
				$t[10]  = "\$T".$1."->{".$2."}";
				$t[10] .= "->{".$3."}" if ($3);

				$t[2] = "\nsyswrite($outype,".$t[10].");";
				$self->my($t[10]);

				undef $t[10];
			}

			# Trata string
			elsif ($t[2] =~ /^\w$/) {
				$self->my("\$T".$t[2]);
				$t[2] = "\nsyswrite($outype,\$T".$t[2].");";
			}

			# Seta vars
			elsif ($t[2] =~ /^([\w\+\-]+)\s?([\=\>\<\!]+)?\s?[\"]?(.*)?[\"]?$/) {
				$t[3] = $1; $t[4] = $2; $t[5] = $3;
				$t[4] =~ s/\=\=/eq/g; $t[4] =~ s/\!\=/ne/g;

				$t[5] =~ s/"$//g if ($t[5] =~ /"$/);

				# Trata variaveis unica
				if ($t[3] && !$t[5]) {
					
					# Variaveis
					if ($t[3] =~ /^\w+$/) {
						$self->my("\$T".$t[3]);
						$t[2] = "\nsyswrite($outype,\$T".$t[3].");";
					}
					
					# Variaveis especiais
					elsif ($t[3] =~ /^[\w\+\-]+$/) {
						$self->my("\$T".$t[3]);
						$t[2] = "\n\$T".$t[3].";";
					}
				}
				
				# Seta variaveis
				elsif ($t[3] && $t[5]) {
					$self->my("\$T".$t[3]);
					$t[2] = "\n\$T".$t[3]." $t[4] \"".&AddSlashes($t[5])."\";";
				}
			}
	
			$output .= $t[1].$t[2];
		}

		# Outros
		elsif ($fdata =~ s/^(.*)$//sx) {
			$output .= "\nsyswrite($outype,\"".&AddSlashes($1)."\");\n";
		}
	}

	$output .= "close(OUTFILE);\n" if ($self->{TO_FILE});
	$output =~ s/syswrite\(STDOUT,/\$return .= sprintf(/g if ($self->{TO_RETURN});
	return $output;
}

# Verifica se adicionou no array
sub my {
	my($self,$var) = @_;
	my (@t,$t);

	if ($var =~ /^([\$\@\%])(.*)?$/) {
		$t[1] = $1; $t[2] = $2;
	
		# Trata array
		if ($t[1] eq "\@") {
			# Verifica se ja esta no array
			$t = 1;
			foreach (@my) { if ($_->{var} eq "\@".$t[2]) { undef $t } }
			
			# Adiciona no array
			push(@my,{
				var	=> "\@".$t[2],
				value	=> "my \@".$t[2].";\n",
			}) if ($t);

			undef $t;
		}

		# Trata var
		elsif ($t[1] eq "\$" && $t[2] =~ /^([\w\+]+)([\-\>]+)?([\w\{\}]+)?/g) {
			$t[3] = $1;
			$t[3] =~ s/\+//g; $t[3] =~ s/\-//g;
	
			# Verifica se ja esta no array
			$t = 1;
			foreach (@my) { 
				if ($_->{var} eq "\$".$t[3]) { 
					undef $t;
					last;
				}
			}
			
			# Adiciona no array
			push(@my,{
				var	=> "\$".$t[3],
				value	=> "my \$".$t[3].";\n",
			}) if ($t);
			
			undef $t;
		}
	}
}

# Abre aquivo
sub load {
	my($self,$templ_file) = @_;
	my($r,$fdata);
	my $path;
	my $file = $templ_file || $self->{TEMPL_FILE};
	my $templ_path = $self->{TEMPL_DIR}."/".$file;

	local $/ = undef;
	#local *FH;

	# Abre arquivo
	if (open(FH,$templ_path)) {
		$fdata = <FH>;
		
		#open(FH2,">>/tmp/filexx");
		#syswrite(FH2,$fdata);
		#close(FH2);

		# Fecha arquivo
		close(FH);
	}

	# Retorna erro
	else {
		die "Erro abrindo arquivo $templ_path: $!\n";
	}

	# Retorna dados
	return $fdata;
}

# Adiciona barras invertidas
sub AddSlashes {
	my($str) = @_;

	$str =~ s/\\/\\\\/g;
	$str =~ s/\#/\\#/g;
	$str =~ s/\@/\\@/g;
	$str =~ s/\"/\\"/g;
	
	return $str;
}

1;
__END__

=head1 NAME

Ananke::Template - Front-end module to the Ananke::Template

=head1 DESCRIPTION

Based in Template ToolKit
This documentation describes the Template module which is the direct
Perl interface into the Ananke::Template.

=head1 SYNOPSIS 

=head2 Template.pl:

	use Ananke::Template;

	# Vars
	my @array;
	push(@array,{ name => 'Udlei', last => 'Nattis' });
	push(@array,{ name => 'Ananke', last => 'IT' });

	my $var = {
		id => 1,
		title => 'no title',
		text  => 'no text',
	};

	# Template Directory and File
	my $template_dir = "./";
	my $template_file = "template.html";
	my $template_vars = {
		'hello'  => "\nhello world",
		'scalar' => $var,
		'array'  => ['v1','v2','v3','v4'],
		'register' => \@array,
	};
	$template_vars->{SCRIPT_NAME} = "file.pl";

	# Method 1 - print
	# Create template object
	my $template = new Ananke::Template($template_dir);

	# Run Template
	$template->process($template_file,$template_vars);

	# Method 2 - print
	&Ananke::Template::view_template($template_dir,$template_file,$template_vars);

	# Method 3 - write in file
	&Ananke::Template::view_template($template_dir,$template_file,$template_vars,"/tmp/file.html");

	# Method 4 - return to variable
	my $return = Ananke::Template::view_template($template_dir,$template_file,$template_vars,1);
	print $return;

=head2 template.html:

	[% hello %]

	[% IF scalar %]
		ID: [% scalar.id %]
		Title: [% scalar.title %]
		Text: [% scalar.text %]
	[% END %]

	[% FOREACH i = array %]
		value = [% i %]
	[% END %]

	[% FOREACH i = register %]
		Nome = [% i.name %], Last = [% i.last %]
	[% END %]

=head1 DIRECTIVE

=head2 INCLUDE

Process another template file or block and include the output.  Variables are localised.

	[% INCLUDE template %]
	[% INCLUDE ../template.html %]

=head2 FOREACH

Repeat the enclosed FOREACH ... END block for each value in the list.

	[% FOREACH variable = list %]                 
		content... 
		[% variable %]
	[% END %]

	# or

	[% FOREACH i = list_chn_grp %]
		[% count++ %]
		[% IF count % 2 %] [% bgcolor = "#FFFFFF" %]
		[% ELSE %] [% bgcolor = "#EEEEEE" %]
		[% END %]
	
		[% i.bgcolor %]
	[% END %]

=head2 IF / UNLESS / ELSIF / ELSE

Enclosed block is processed if the condition is true / false.

	[% IF condition %]
		content
	[% ELSIF condition %]
		content
	[% ELSE %]
		content
	[% END %]

	[% UNLESS condition %]
		content
	[% # ELSIF/ELSE as per IF, above %]
		content
	[% END %]

=head2 FOR

	[% FOR i=1;i<=12;i++ %]
		[% i=1 %]
	[% END %]

=head2 VARIABLES

	[% var = 'text' %]
	[% var %]

=head1 AUTHOR

	Udlei D. R. Nattis
	nattis@anankeit.com.br
	http://www.nobol.com.br
	http://www.anankeit.com.br

=cut

# Data inicio: Thu Feb 21 16:19:18 BRT 2002
# Desenvolvido por: Udlei Nattis <nattis@anankeit.com.br

