#!/usr/bin/perl
#
use strict ;

use App::Framework ;

# VERSION
our $VERSION = '1.003' ;

	# Create application and run it
	App::Framework->new()->go() ;


#=================================================================================
# SUBROUTINES EXECUTED BY APP
#=================================================================================

#----------------------------------------------------------------------
# Main execution
#
sub run
{
	my ($app) = @_ ;

	my %info ;
	
	# options
	my %opts = $app->options() ;

	# Get source
	my ($file) = @{$app->arglist()};

if ($opts{log})
{
	open my $fh, ">>$opts{log}" or die "Error: unable to append to log file $opts{log} : $!" ;
	print $fh "Processing $file\n" ;
}


	print "$file...\n" ;
	$info{'file'} = $file ;
	
	open my $fh, "<$file" ;
	my $line ;
	my $pkg ;
	my $fn ;
	my $fields ;
	my $pod ;
	my ($super, $call, $args) ;
	while (defined($line = <$fh>))
	{
		chomp $line ;
		$line =~ s/^\s+// ;
		$line =~ s/\s+$// ;


print "\n<$line>\n" if $opts{debug} ;
print "POD: $pod PKG:$pkg FN:$fn CALL:$call FIELDS:$fields\n" if $opts{debug} ;

		$line =~ s/^#.*// ;
		next unless $line ;
		
				
		## pod
		if ($line =~ /^=([\w]+)/)
		{
			if ($1 eq 'cut')
			{
				$pod = 0 ;
			}
			else
			{
				$pod = 1 ;
			}
		}
		
		next if $pod ;	
		
		
		## inside a call
		if ($call)
		{
			# see if call complete
			if ($line =~ /([^\)]*)\)\s*;/)
			{
				$args .= $1 ;
				my @args = split ',', $args ;
				foreach my $arg (@args)
				{
					$arg =~ s/^\s+// ;
					$arg =~ s/\s+$// ;
					$arg =~ s/^[\\\$\@\%]+// ;
				}
print " + + args (@args)\n" if $opts{debug} ;

				if ($super)
				{
					$fn = "$info{'isa'}:$fn" ;
				}
					
				push @{$info{'fn_calls'}{$fn}}, {
					'fn'	=> $call,
					'args'	=> \@args,
				} ;
				$call = undef ;
			}
			else
			{
				$args .= $line ;
			}
		}	
		
		# package App::Framework::Feature::Options ;
		if ($line =~ /^\s*package\s+([\w:_]+)/)
		{
			$pkg = $1 ;
			my $name = $pkg ;
			$name =~ s/::/_/g ;
			$info{'name'} = $name ;
			
			$pkg = pkg_name($pkg, \%opts) ;
			$info{'pkg'} = $pkg ;
			print "Package = $pkg\n" if $opts{debug} ;
		}
		
		# our @ISA = qw(NetPacket::Ethernet);
		if ($line =~ /^(?:\s*|my\s+|our\s+)\@ISA/)
		{
#			if ($line =~ /^(?:\s*|my\s+|our\s+)\@ISA\s*=\s*(?:qw.|['"])([\w+:_]+)/)
			if ($line =~ /\@ISA\s*=\s*(?:qw.|['"])([\w+:_]+)/)
			{
				my $isa = pkg_name($1, \%opts) ;
				$info{'isa'} = $isa ;
			}
			else
			{
				# undefined @ISA - try to use the last 'use'
				if ($info{'use'})
				{
					$info{'isa'} = $info{'use'}->[scalar(@{$info{'use'}})-1] ;
					
				}
			}
			print "ISA = $info{'isa'}\n" if $opts{debug};
		}
		
		# Use
		# use NetPacket::Ethernet;
		if ($line =~ /^\s*use\s+([\w+:_]+)/)
		{
			my $use = pkg_name($1, \%opts) ;
			$info{'use'} ||= [] ;
			push @{$info{'use'}}, $use ;
			print "USE = $use\n" if $opts{debug};
		}
		
		# Function definition
		# sub run
		if ($line =~ /^\s*sub\s+(\S+)/)
		{
			$info{'isa'} ||= 'UNIVERSAL' ;
			
			$fn = $1 ;
			$info{'fn_list'} ||= [] ;
			push @{$info{'fn_list'}}, $fn ;
			
			$info{'fn_details'}{$fn} = {
				'args'	=> [],
			} ;
			$info{'fn_calls'}{$fn} = [] ;

		}

		if ($fn)
		{
			# Function args
			# my () = @_ ;
			if ($line =~ /^\s*my\s*\(([^\)]*)\)\s*=\s*\@_\s*;/)
			{
				($args) = ($1) ;
print " + fn my ($args)\n" if $opts{debug} ;
				my @args = split ',', $args ;
				foreach my $arg (@args)
				{
					$arg =~ s/^\s+// ;
					$arg =~ s/\s+$// ;
					$arg =~ s/^[\\\$\@\%]+// ;
				}
print " + + args (@args)\n" if $opts{debug} ;
				$info{'fn_details'}{$fn}{'args'} = \@args ;
			}
						
			# method call
			# $this->access($options_aref) ;
			# $this->SUPER::access($options_aref) ;
			# App::Framework->access($options_aref) ;
			if ($line =~ /^[^#]*(?:\$\w+|[\w_:]+)\->(SUPER::){0,1}([^\s\(]+)\(([^\)]*)/)
			{
				($super, $call, $args) = ($1, $2, $3) ;
print " + fn call <$super>: $call($args)\n" if $opts{debug} ;

				# see if call complete
				if ($line =~ /\)\s*;/)
				{
					my @args = split ',', $args ;
					foreach my $arg (@args)
					{
						$arg =~ s/^\s+// ;
						$arg =~ s/\s+$// ;
						$arg =~ s/^[\\\$\@\%]+// ;
					}
	print " + + args (@args)\n" if $opts{debug} ;
					
					if ($super)
					{
						$call = "$info{'isa'}".":$call" ;
	print " + + call ($call)\n" if $opts{debug} ;
					}
					
					push @{$info{'fn_calls'}{$fn}}, {
						'fn'	=> $call,
						'args'	=> \@args,
					} ;
					$call = undef ;
				}
			}
		}
		
		#	my %FIELDS = (
		#		## Object Data
		#		'saved_app'	=> undef,
		#		'user'		=> 'nobody',
		#		'group'		=> 'nobody',
		#		'pid'		=> undef,
		#	) ;
		if ($line =~ /^\s*my\s+\%FIELDS\s*=\s*\(/)
		{
			++$fields ;
		}
		elsif ($fields)
		{
			if ($line =~ /^\s*['"]{0,1}([\w_]+)['"]{0,1}\s*=>\s*([^,]+),\s*/)
			{
				$info{'fields'} ||= [] ;
				push @{$info{'fields'}}, {
					'var'	=> $1,
					'val'	=> $2,
				} ;
print " + field: $1 => $2\n" if $opts{debug} ;
			}
			if ($line =~ /^\s*\)\s*;/)
			{
				$fields=0 ;
			}
			
		}
	}

	
	close $fh ;

	if ($opts{cpp})
	{
		write_cpp($file, \%info, \%opts) ;
	}
	else
	{
#		write_c($file, $opts{dir}, \%info, \%opts) ;
		write_single_cpp($file, \%info, \%opts) ;
	}

}

#----------------------------------------------------------------------
sub pkg_name
{
	my ($pkg, $opts_href) = @_ ;
	
	if ($opts_href->{pkgpath})
	{
		$pkg =~ s/::/_/g ;
	}
	else
	{
		my @fields = split '::', $pkg ;
		$pkg = pop @fields ;
	}	
	return $pkg ;
}


##----------------------------------------------------------------------
#sub write_c
#{
#	my ($file, $dir, $info_href, $opts_href) = @_ ;
#	
#	my ($base, $src_dir) = (fileparse($file, '\..*?'))[0,1] ;
#	my $outfile = "$dir/$base.c" ;
#	open my $out_fh, ">$outfile" or die "Error: cannot write to $outfile : $!";
#
#	my $pkg = $info_href->{pkg} ;
#	print $out_fh "namespace $pkg ; \n{\n" ;
#	foreach my $fn (@{$info_href->{'fn_list'}})
#	{
#		print $out_fh "void ${pkg}::$fn()\n{\n" ;
#		foreach my $call (@{$info_href->{'fn_details'}{$fn}})
#		{
#			print $out_fh "\t${pkg}::$call() ;\n"
#		}
#		print $out_fh "}\n\n" ;
#	}
#	print $out_fh "}\n"  ;
#	close $out_fh ;
#	
#}


#----------------------------------------------------------------------
sub write_cpp
{
	my ($file, $info_href, $opts_href) = @_ ;
	
#	my ($base, $src_dir) = (fileparse($file, '\..*?'))[0,1] ;

	my $pkg = $info_href->{pkg} ;
	my $base = $pkg ;
	my $dir = $opts_href->{standalone} ? $opts_href->{dir} : '';

die "Error: no name" unless $base ;
		
	## h file ######################################################################
	my $outfile = "$dir/$base.h" ;
	my $out_fh ;

	my $inc_ext = "h" ;
	if ($opts_href->{pm})
	{
		$inc_ext = "pm" ;
		$outfile = "$dir/$base.pm" ;
	}
	
	if ($dir)
	{
		open $out_fh, ">$outfile" or die "Error: cannot write to $outfile : $!";
	}
	else
	{
		$out_fh = \*STDOUT ;
	}
	
	print $out_fh "// $info_href->{file}\n\n" ;

	#class DrivesCombo : public KComboBox
	#00036 {
	#00037 public:
	#00038     DrivesCombo(QWidget* parent, const char* name = 0);
	#00039     virtual ~DrivesCombo();
	#00040 
	#00041 };

	foreach my $use (@{$info_href->{'use'}})
	{
		print $out_fh "#include \"$use.$inc_ext\"\n" ;
	}
	print $out_fh "#include \"$info_href->{isa}.$inc_ext\"\n" if $info_href->{isa} ;
	my $isa = $info_href->{isa} || $info_href->{'use'} || 'UNIVERSAL' ;
	
	print $out_fh "class $pkg : public $isa\n{\n" ;
	
	## Public
	print $out_fh "\npublic:\n" ;

	# fields
	foreach my $field_href (@{$info_href->{'fields'}})
	{
		next if $field_href->{'var'} =~ m/^_/ ;
		print $out_fh "\tint $field_href->{'var'} ;\n" ;
	}
	print $out_fh "\n" ;
	
	# methods
	foreach my $fn (@{$info_href->{'fn_list'}})
	{
		next if $fn =~ m/^_/ ;
		
		my $details_href = $info_href->{'fn_details'}{$fn} ;
		my $argstr = "" ;
		if ($opts_href->{args})
		{
			$argstr = join(', ', @{$details_href->{args}}) ;
		}
		print $out_fh "\tvoid $fn($argstr) ;\n" ;
	}

	## Protected
	print $out_fh "\nprotected:\n" ;

	# fields
	foreach my $field_href (@{$info_href->{'fields'}})
	{
		next unless $field_href->{'var'} =~ m/^_/ ;
		print $out_fh "\tint $field_href->{'var'} ;\n" ;
	}
	print $out_fh "\n" ;
	
	# methods
	foreach my $fn (@{$info_href->{'fn_list'}})
	{
		next unless $fn =~ m/^_/ ;
		
		my $details_href = $info_href->{'fn_details'}{$fn} ;
		my $argstr = "" ;
		if ($opts_href->{args})
		{
			$argstr = join(', ', @{$details_href->{args}}) ;
		}
		print $out_fh "\tvoid $fn($argstr) ;\n" ;
	}

	print $out_fh "};\n"  ;
	if ($dir)
	{
		close $out_fh ;
	}

	
	## cpp file ######################################################################
	$outfile = "$dir/$base.cpp" ;
	if ($opts_href->{pm})
	{
		$outfile = "$dir/$base.pm" ;
	}


	if ($dir)
	{
		open $out_fh, ">>$outfile" or die "Error: cannot write to $outfile : $!";
	}
	else
	{
		$out_fh = \*STDOUT ;
	}

print $out_fh "// $info_href->{file}\n\n" ;

#	my $def = uc $base ;
#	print $out_fh "#ifdef $def\n" ;
#	print $out_fh "#define $def\n" ;


	if ($dir && !$opts_href->{pm})
	{
		print $out_fh "#include \"$base.$inc_ext\"\n\n" ;
	}
		
	foreach my $fn (@{$info_href->{'fn_list'}})
	{
		print $out_fh "void ${pkg}::$fn()\n{\n" ;
		foreach my $call_href (@{$info_href->{'fn_calls'}{$fn}})
		{
			my $argstr = "" ;
			if ($opts_href->{args})
			{
				$argstr = join(', ', @{$call_href->{args}}) ;
			}
			print $out_fh "\t$call_href->{fn}($argstr) ;\n"
		}
		print $out_fh "}\n\n" ;
	}
#	print $out_fh "#endif\n" ;

	if ($dir)
	{
		close $out_fh ;
	}
	
}

#----------------------------------------------------------------------
sub write_single_cpp
{
	my ($file, $info_href, $opts_href) = @_ ;
	
#	my ($base, $src_dir) = (fileparse($file, '\..*?'))[0,1] ;

	my $pkg = $info_href->{pkg} ;
	my $base = $pkg ;
	my $dir = $opts_href->{standalone} ? $opts_href->{dir} : '';

die "Error: no name" unless $base ;
		
	## h file ######################################################################
	my $out_fh ;
	my $outfile = "$dir/$base.cpp" ;
	my $inc_ext = "cpp" ;

#	my $outfile = "$dir/$base.h" ;
#
#	my $inc_ext = "h" ;
#	if ($opts_href->{pm})
#	{
#		$inc_ext = "pm" ;
#		$outfile = "$dir/$base.pm" ;
#	}
#	
#	if ($dir)
#	{
#		open $out_fh, ">$outfile" or die "Error: cannot write to $outfile : $!";
#	}
#	else
#	{
#		$out_fh = \*STDOUT ;
#	}

#	if ($opts_href->{pm})
#	{
#		$outfile = "$dir/$base.pm" ;
#	}


	if ($dir)
	{
		open $out_fh, ">$outfile" or die "Error: cannot write to $outfile : $!";
	}
	else
	{
		$out_fh = \*STDOUT ;
	}
	
	print $out_fh "// $info_href->{file} h\n\n" ;

	#class DrivesCombo : public KComboBox
	#00036 {
	#00037 public:
	#00038     DrivesCombo(QWidget* parent, const char* name = 0);
	#00039     virtual ~DrivesCombo();
	#00040 
	#00041 };

	foreach my $use (@{$info_href->{'use'}})
	{
		print $out_fh "#include \"$use.$inc_ext\"\n" ;
	}
	print $out_fh "#include \"$info_href->{isa}.$inc_ext\"\n" if $info_href->{isa} ;
	my $isa = $info_href->{isa} || $info_href->{'use'} || 'UNIVERSAL' ;
	
	print $out_fh "class $pkg : public $isa\n{\n" ;
	
	## Public
	print $out_fh "\npublic:\n" ;

	# fields
	foreach my $field_href (@{$info_href->{'fields'}})
	{
		next if $field_href->{'var'} =~ m/^_/ ;
		print $out_fh "\tint $field_href->{'var'} ;\n" ;
	}
	print $out_fh "\n" ;
	
	# methods
	foreach my $fn (@{$info_href->{'fn_list'}})
	{
		next if $fn =~ m/^_/ ;
		
		my $details_href = $info_href->{'fn_details'}{$fn} ;
		my $argstr = "" ;
		if ($opts_href->{args})
		{
			$argstr = join(', ', @{$details_href->{args}}) ;
		}
		print $out_fh "\tvoid $fn($argstr) ;\n" ;
	}

	## Protected
	print $out_fh "\nprotected:\n" ;

	# fields
	foreach my $field_href (@{$info_href->{'fields'}})
	{
		next unless $field_href->{'var'} =~ m/^_/ ;
		print $out_fh "\tint $field_href->{'var'} ;\n" ;
	}
	print $out_fh "\n" ;
	
	# methods
	foreach my $fn (@{$info_href->{'fn_list'}})
	{
		next unless $fn =~ m/^_/ ;
		
		my $details_href = $info_href->{'fn_details'}{$fn} ;
		my $argstr = "" ;
		if ($opts_href->{args})
		{
			$argstr = join(', ', @{$details_href->{args}}) ;
		}
		print $out_fh "\tvoid $fn($argstr) ;\n" ;
	}

	print $out_fh "};\n"  ;
#	if ($dir)
#	{
#		close $out_fh ;
#	}

	
	## cpp file ######################################################################
#	$outfile = "$dir/$base.cpp" ;
#	if ($opts_href->{pm})
#	{
#		$outfile = "$dir/$base.pm" ;
#	}
#
#
#	if ($dir)
#	{
#		open $out_fh, ">>$outfile" or die "Error: cannot write to $outfile : $!";
#	}
#	else
#	{
#		$out_fh = \*STDOUT ;
#	}

print $out_fh "// $info_href->{file} cpp\n\n" ;

#	my $def = uc $base ;
#	print $out_fh "#ifdef $def\n" ;
#	print $out_fh "#define $def\n" ;

#	if ($dir && !$opts_href->{pm})
#	{
#		print $out_fh "#include \"$base.$inc_ext\"\n\n" ;
#	}
		
	foreach my $fn (@{$info_href->{'fn_list'}})
	{
		print $out_fh "void ${pkg}::$fn()\n{\n" ;
		foreach my $call_href (@{$info_href->{'fn_calls'}{$fn}})
		{
			my $argstr = "" ;
			if ($opts_href->{args})
			{
				$argstr = join(', ', @{$call_href->{args}}) ;
			}
			print $out_fh "\t$call_href->{fn}($argstr) ;\n"
		}
		print $out_fh "}\n\n" ;
	}
#	print $out_fh "#endif\n" ;

	if ($dir)
	{
		close $out_fh ;
	}
	
}


#=================================================================================
# SETUP
#=================================================================================
__DATA__

[SUMMARY]

Convert

[NAMEARGS]

source:f

[OPTIONS]

-standalone		Create output file

Run in standalone mode (i.e. not under doxygen) and create standalone files

-dir=s			Output directory [default=doxygen/src]

Directory into which the generated files are to stored (standalone mode)

-pm				Perl module files

Inn standalone mode, write out files as perl modules rather than .h/.cpp files

-makefile=s		Create makefile

Specify the Makefile path to create a doxygen makefile

-cpp=i			Create C++ [default=1]

Create pseudo C++ rather than pseudo C

-args=i			Show args [default=0]

Show function arguments

-pkgpath		Full path names

Use full path name for package rather than using the last name. For example, for App::Framework::Core, set the class to App_Framework_Core
rather than Core

[DESCRIPTION]

B<$name> reads the perl module ...


__END__

'/^=([\w]+)/: ($1 eq 'cut' ? pod=0 : pod=1);'

		## pod
		if ($line =~ /^=([\w]+)/)
		{
			if ($1 eq 'cut')
			{
				$pod = 0 ;
			}
			else
			{
				$pod = 1 ;
			}
		}

'pod:::FILTER_NEXT'
		
		next if $pod ;	
		
'call:/([^\)]*)\)\s*;/:????????'		
		## inside a call
		if ($call)
		{
			# see if call complete
			if ($line =~ /([^\)]*)\)\s*;/)
			{
				$args .= $1 ;
				my @args = split ',', $args ;
				foreach my $arg (@args)
				{
					$arg =~ s/^\s+// ;
					$arg =~ s/\s+$// ;
					$arg =~ s/^[\\\$\@\%]+// ;
				}
print " + + args (@args)\n" if $opts{debug} ;

				if ($super)
				{
					$fn = "$info{'isa'}:$fn" ;
				}
					
				push @{$info{'fn_calls'}{$fn}}, {
					'fn'	=> $call,
					'args'	=> \@args,
				} ;
				$call = undef ;
			}
			else
			{
				$args .= $line ;
			}
		}	

'/^\s*package\s+([\w:_]+)/:pkg=$1;:set_package()'	
sub set_package
{
			my $name = $pkg ;
			$name =~ s/::/_/g ;
			$info{'name'} = $name ;
			
			$pkg = pkg_name($pkg, \%opts) ;
			$info{'pkg'} = $pkg ;
	
}	
		# package App::Framework::Feature::Options ;
		if ($line =~ /^\s*package\s+([\w:_]+)/)
		{
			$pkg = $1 ;
			my $name = $pkg ;
			$name =~ s/::/_/g ;
			$info{'name'} = $name ;
			
			$pkg = pkg_name($pkg, \%opts) ;
			$info{'pkg'} = $pkg ;
			print "Package = $pkg\n" if $opts{debug} ;
		}

HASH:		
cond=>'/^(?:\s*|my\s+|our\s+)\@ISA/', flags=>'FILTER_START_IF', label=>'ISA'
label=>'ISA', flags=>'FILTER_IF', cond=>'/\@ISA\s*=\s*(?:qw.|['"])([\w+:_]+)/', vars=>'isa = pkg_name($1, \%opts);'
label=>'ISA', flags=>'FILTER_ELSE', cond=>'use', vars=>'isa=use->[scalar(@{use)-1] ;'

ARRAY: [cond, vars, flags, call, label]

['/^(?:\s*|my\s+|our\s+)\@ISA/', 											, 'FILTER_START_IF', 	, 'ISA']
['/\@ISA\s*=\s*(?:qw.|['"])([\w+:_]+)/', 	'isa = pkg_name($1, \%opts);'	, 'FILTER_IF', 			, 'ISA']
['use', 									'isa=use->[scalar(@{use)-1] ;'	, 'FILTER_ELSE', 		, 'ISA']

		# our @ISA = qw(NetPacket::Ethernet);
		if ($line =~ /^(?:\s*|my\s+|our\s+)\@ISA/)
		{
#			if ($line =~ /^(?:\s*|my\s+|our\s+)\@ISA\s*=\s*(?:qw.|['"])([\w+:_]+)/)
			if ($line =~ /\@ISA\s*=\s*(?:qw.|['"])([\w+:_]+)/)
			{
				my $isa = pkg_name($1, \%opts) ;
				$info{'isa'} = $isa ;
			}
			else
			{
				# undefined @ISA - try to use the last 'use'
				if ($info{'use'})
				{
					$info{'isa'} = $info{'use'}->[scalar(@{$info{'use'}})-1] ;
					
				}
			}
			print "ISA = $info{'isa'}\n" if $opts{debug};
		}

'/^\s*use\s+([\w+:_]+)/','use||=[]; push @{use}, pkg_name($1, \%opts) ;'	
	
		# Use
		# use NetPacket::Ethernet;
		if ($line =~ /^\s*use\s+([\w+:_]+)/)
		{
			my $use = pkg_name($1, \%opts) ;
			$info{'use'} ||= [] ;
			push @{$info{'use'}}, $use ;
			print "USE = $use\n" if $opts{debug};
		}
		
		# Function definition
		# sub run
		if ($line =~ /^\s*sub\s+(\S+)/)
		{
			$info{'isa'} ||= 'UNIVERSAL' ;
			
			$fn = $1 ;
			$info{'fn_list'} ||= [] ;
			push @{$info{'fn_list'}}, $fn ;
			
			$info{'fn_details'}{$fn} = {
				'args'	=> [],
			} ;
			$info{'fn_calls'}{$fn} = [] ;

		}

'fn:/^\s*my\s*\(([^\)]*)\)\s*=\s*\@_\s*;/','fn_details{$fn}{'args'} = args($1);'
		if ($fn)
		{
			# Function args
			# my () = @_ ;
			if ($line =~ /^\s*my\s*\(([^\)]*)\)\s*=\s*\@_\s*;/)
			{
				($args) = ($1) ;
print " + fn my ($args)\n" if $opts{debug} ;
				my @args = split ',', $args ;
				foreach my $arg (@args)
				{
					$arg =~ s/^\s+// ;
					$arg =~ s/\s+$// ;
					$arg =~ s/^[\\\$\@\%]+// ;
				}
print " + + args (@args)\n" if $opts{debug} ;
				$info{'fn_details'}{$fn}{'args'} = \@args ;
			}

'fn:/^[^#]*(?:\$\w+|[\w_:]+)\->(SUPER::){0,1}([^\s\(]+)\(([^\)]*)/', 'super=$1;call=$2;args=$3;', FILTER_START_IF, CALL
'/\)\s*;/', 'args=args(args);' FILTER_IF, CALL
'super:/\)\s*;/', '$call = "$isa".":$call" ;' FILTER_IF, CALL
'/\)\s*;/', '$call = "$isa".":$call" ;' FILTER_IF, CALL
						
			# method call
			# $this->access($options_aref) ;
			# $this->SUPER::access($options_aref) ;
			# App::Framework->access($options_aref) ;
			if ($line =~ /^[^#]*(?:\$\w+|[\w_:]+)\->(SUPER::){0,1}([^\s\(]+)\(([^\)]*)/)
			{
				($super, $call, $args) = ($1, $2, $3) ;
print " + fn call <$super>: $call($args)\n" if $opts{debug} ;

				# see if call complete
				if ($line =~ /\)\s*;/)
				{
					my @args = split ',', $args ;
					foreach my $arg (@args)
					{
						$arg =~ s/^\s+// ;
						$arg =~ s/\s+$// ;
						$arg =~ s/^[\\\$\@\%]+// ;
					}
	print " + + args (@args)\n" if $opts{debug} ;
					
					if ($super)
					{
						$call = "$info{'isa'}".":$call" ;
	print " + + call ($call)\n" if $opts{debug} ;
					}
					
					push @{$info{'fn_calls'}{$fn}}, {
						'fn'	=> $call,
						'args'	=> \@args,
					} ;
					$call = undef ;
				}
			}
		}
		
		#	my %FIELDS = (
		#		## Object Data
		#		'saved_app'	=> undef,
		#		'user'		=> 'nobody',
		#		'group'		=> 'nobody',
		#		'pid'		=> undef,
		#	) ;
		if ($line =~ /^\s*my\s+\%FIELDS\s*=\s*\(/)
		{
			++$fields ;
		}
		elsif ($fields)
		{
			if ($line =~ /^\s*['"]{0,1}([\w_]+)['"]{0,1}\s*=>\s*([^,]+),\s*/)
			{
				$info{'fields'} ||= [] ;
				push @{$info{'fields'}}, {
					'var'	=> $1,
					'val'	=> $2,
				} ;
print " + field: $1 => $2\n" if $opts{debug} ;
			}
			if ($line =~ /^\s*\)\s*;/)
			{
				$fields=0 ;
			}
			
		}




