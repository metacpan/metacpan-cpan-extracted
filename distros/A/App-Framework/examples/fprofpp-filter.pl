#!/usr/bin/perl
#
use strict ;

use App::Framework '::Filter' ;

# VERSION
our $VERSION = '1.000' ;

	# Create application and run it
	my $app = App::Framework->new(
		'debug' => 0,
	) ;
	$app->go() ;

#=================================================================================
# SUBROUTINES EXECUTED BY APP
#=================================================================================

#----------------------------------------------------------------------
# Start of file
sub app_start
{
	my ($app, $opts_href, $state_href) = @_ ;

	$state_href->{info} ||= [];	
	$state_href->{modules} ||= {};	

	if ($opts_href->{sort})
	{
		$app->set(buffer => 1) ;
	}
		
}

#----------------------------------------------------------------------
# Main execution
#
sub app
{
	my ($app, $opts_href, $state_href, $line, @args) = @_ ;
	
	# default is to output the line
	$state_href->{output} = $line ;	

	# /usr/lib/perl5/site_perl/5.10.0/App/Framework/Base/Object.pm:486 4.63736 437388: return $href ? %$href : () ;
	if ($line =~ /([^:]+):(\d+) ([\.\d+]+) (\d+):(.*)/)
	{
		my ($file, $line, $time, $count, $source) = ($1, $2, $3, $4, $5) ;
		
		if ($opts_href->{module})
		{
			if ($file !~ /$opts_href->{module}/)
			{
				$state_href->{output} = undef ;
				return ;	
			}
		}
		
		$state_href->{modules}{$file} ||= parse_module($app, $file) ;
		my $module_ref = $state_href->{modules}{$file} ;
		my $function = get_function($app, $module_ref, $line) ;
		
		my $total = $time * $count ;
		push @{$state_href->{info}}, [$file, $line, $time, $count, $source, $total, $function] ;
		$state_href->{output} = sprintf("%-70s:%-4d %3.4f %8d [%10.2f] : %s :: %s", $file, $line, $time, $count, $total, $function, $source) ;
	}
	
	if ($opts_href->{sort})
	{
		$state_href->{output} = undef ;
	}
}

#----------------------------------------------------------------------
# End of file
sub app_end
{
	my ($app, $opts_href, $state_href) = @_ ;

	if ($opts_href->{sort})
	{
		my ($file_len, $fn_len) = (0, 0) ;
		foreach my $aref ( sort {$b->[5] <=> $a->[5]} @{$state_href->{info}})
		{
			my ($file, $line, $time, $count, $source, $total, $function) = @$aref ;
			$file_len = length($file) if $file_len < length($file) ;
			$fn_len = length($function) if $fn_len < length($function) ;
			
		}
		$file_len += 5 ;
		$fn_len += 5 ;
		foreach my $aref ( sort {$b->[5] <=> $a->[5]} @{$state_href->{info}})
		{
			my ($file, $line, $time, $count, $source, $total, $function) = @$aref ;
			
			$app->write_output(
				sprintf("%-${file_len}s:%-4d %3.4f %8d [%10.2f] : %-${fn_len}s :: %s", 
					$file, $line, $time, $count, $total, $function, $source) 
			);
		}
	}
	
	
}

#=================================================================================
# LOCAL SUBROUTINES
#=================================================================================


#----------------------------------------------------------------------
sub parse_module
{
	my ($app, $file) = @_ ;

	my $module_ref = [] ;
	if (open my $fh, "<$file")
	{
		my $line_num = 1 ;
		my $fn ;
		my $line ;
		my $href = {} ;
		while (defined($line = <$fh>))
		{
			chomp $line ;
			
			if ($line =~ m/^\s*sub\s+(\w+)/)
			{
				if ($fn) 
				{
					$href->{'end'} = $line_num-1 ;
					push @$module_ref, $href ;
					$href = {} ;
				}
				$fn = $1 ;
				$href->{'function'} = $fn ;
				$href->{'start'} = $line_num ;
			}
			++$line_num;
		}
		
		close $fh ;
		
		if ($fn) 
		{
			$href->{'end'} = $line_num-1 ;
			push @$module_ref, $href ;
		}
		
	}

	return $module_ref ;	
}

#----------------------------------------------------------------------
sub get_function
{
	my ($app, $module_ref, $linenum) = @_ ;

	my $function = 'unknown' ;
	foreach my $href (@$module_ref)
	{
		if ( ($linenum >= $href->{'start'}) && ($linenum <= $href->{'end'}) )
		{
			$function = $href->{'function'} . "()" ;
			last ;
		}
	}
	return $function ;
}

#=================================================================================
# SETUP
#=================================================================================
__DATA__


[SUMMARY]

Filter Devel::FastProf output

[OPTIONS]

-module=s		Only report specified module(s)

Specify a regexp to filter out any modules that do not match

-sort    		Sort output

Sort output on total time in function

[DESCRIPTION]

B<$name> filters Devel::FastProf output

	# fprofpp output format is:
	# filename:line time count: source
	/usr/lib/perl5/site_perl/5.10.0/App/Framework/Base/Object.pm:486 4.63736 437388: return $href ? %$href : () ;
	/usr/lib/perl5/site_perl/5.10.0/App/Framework/Base/Object.pm:799 2.25143 1512764: return $class ;

