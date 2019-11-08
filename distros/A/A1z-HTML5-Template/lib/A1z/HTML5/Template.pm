package A1z::HTML5::Template;
use strict;
use warnings;
use vars qw($NAME);

# ABSTRACT: Fast and Easy Web Apps

sub NAME { my $self = shift; $NAME = "Fast and Easy Web Apps"; return $NAME; }

our $VERSION = '0.22';

use parent qw(Exporter); 
require Exporter; 
our @ISA = ("Exporter"); 

our @EXPORT_OK = qw(header start_html head_title head_meta head_js_css end_head begin_body body_js_css body_topnavbar 
body_accordion end_body end_html head body
); 



sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}


sub math1 
{
	my $self = shift; 
	
	my ($num1, $num2) = @_;
	
	if ($num1 eq '') { $num1 = '2'; }
	if ($num2 eq '') { $num2 = '4'; }
	
	my $out;
	
	my $m = $num1 * $num2;
	my $a  = $num1 + $num2;
	my $s  = $num1 - $num2;
	my $s1 = $num2 - $num1;
	my $d = $num1 / $num2;
	my $d1 = $num2 / $num1;
	
	$out .= qq{<div class="math">
	<table class="table table-responsive table-bordered table-condensed table-hover">
	
		<thead><tr><td colspan="6">Multiplication</td></tr></thead>
		<tr> 
			<td></td>
			<td>$num1</td> 
			<td>x</td> 
			<td>$num2</td> 
			<td>\=</td> 
			<td>$m</td> 
		</tr>
	
		<thead><tr><td colspan="6">Addition</td></tr></thead> 
		<tr> <td></td> <td>$num1 </td> <td>\+</td> <td> $num2</td> <td> \=</td> <td> $a</td> </tr>
		
		<thead><tr><td colspan="6">Subtraction</td></tr></thead>
		<tr> <td></td> <td>$num1</td> <td> \-</td> <td> $num2</td> <td> \=</td> <td> $s</td> </tr>
		<tr> <td></td> <td>$num2</td> <td> \-</td> <td> $num1</td> <td> \=</td> <td> $s1</td> </tr>
		
		<thead><tr><td colspan="6">Division</td></tr></thead>
		<tr> <td></td> <td>$num1</td> <td> \/</td> <td> $num2</td> <td> \=</td> <td> $d </td></tr>
		<tr> <td></td> <td>$num2</td> <td> \/</td> <td> $num1</td> <td> \=</td> <td> $d1</td> </tr>
		
	</table>
	</div>
	};

	return qq{\n$out\n};
}



# begin timestable 
sub timestable 
{	
	my $self = shift;
	
	my ($num1) = @_;
	
	if ( $num1 eq '' ) { $num1 = '2'; }
	
	my $out;
	
	$out .= qq{<table class="table table-bordered table-condensed table-striped table-hover table-responsive">};
	
	for ('1'..'20') 
	{
		$out .= qq{<tr> <td>$num1</td> <td>x</td> <td>$_</td> <td>=</td> <td>} . $num1 * $_ . qq{</td></tr>} if ($_);
	}
	$out .= qq{</table>};
	
	return $out;
}
# end timestable 



# begin header 
sub header 
{
	my $self = shift; 
	
	my @keys; 
	if (@_) { @keys = @_; } 
	
	my $args = scalar(@keys); 
	
	my ($key, $key1) = @_;
	
	my %out;
	
	if ($ARGV and $ARGV > 0 and scalar(@keys) > 0) 
	{
		if ($key eq 'utf8')
		{
			$out{"$key"} = qq{Content-Type: text/html;charset=utf-8\n\n}; 
			
		} 
		elsif (!defined $key or $key eq '') 
		{
			$out{"$key"} = qq{Content-Type: text/html;charset=utf-8\n\n};
		}
		else 
		{
			$out{"$key"} = qq{Content-Type: text/html;charset=utf-8\n\n};
		}
	}
	else 
	{
		return qq{Content-Type: text/html;charset=utf-8\n\n}; 
	}
	
} 
# end header 



# begin start html 01
sub start_html  
{ 
	my $self = shift;
	
	my @keys; 
	if (@_) { @keys = @_; } 
	
	my $args = scalar @keys; 
	
	my ($key, $key1) = @_; 
	
	my %out; 
	
	if ($args and $args >= 0) 
	{
		# have your own custom header, backwards compatibility 
		
		my $out; 
		
		$out .= qq{@_ }; 
		
		return $out; 
		
	}
	else 
	{
		my $out; 
		
		$out .= qq{<!DOCTYPE html>\n<html>\n};  
		$out .= qq{<head>\n}; 
	
		return $out; 
		
	}
} 
# end start_html 




sub body_js_css 
{
	my $self = shift;
	
	my $key = "@_"; 
	
	my @keys; 
	if (@_) { @keys = @_; } 
	
	my $args = scalar (@keys); 
	
	my $out; 
	
	$out .= qq^
		<!--jquery-->
		<script src="https://code.jquery.com/jquery-1.12.4.min.js"></script>
		<!--bootstrap/jQueryUI-->
		<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.0/js/bootstrap.min.js"></script>
		<script src="https://code.jquery.com/ui/1.11.4/jquery-ui.min.js"></script>

		<!-- IE10 viewport hack for Surface/desktop Windows 8 bug -->
		<script  src="https://www.a1z.us/jquery/bootstrap/fixed-top/ie10-viewport-bug-workaround.js"></script>

		<script>
		
		// for tabs 
		\$( function() {
			var tabs = \$("#tabs").tabs();
			tabs.find( ".ui-tabs-nav" ).sortable({
				axis: "x",
				stop: function() { tabs.tabs( "refresh" ); }
			});
		}); 
		  
		// dialog 
		\$( function() {
			\$( "#dialog" ).dialog({
			  autoOpen: false,
			  show: {
				effect: "blind",
				duration: 1000
			  },
			  hide: {
				effect: "explode",
				duration: 1000
			  }
			});
		 
			\$( "#opener" ).click(function() {
			  \$( "#dialog" ).dialog( "open" );
			});
		});
		  
		\$('#menu').menu(); 
		\$('#accordion').accordion(); 
		\$('#accordion1').accordion(); 
		\$('#accordion2').accordion(); 
		\$('#accordion3').accordion(); 
		\$('#tabs').tabs(); 
		
		</script>
	
	^; 
	
	
	if ( $args ) 
	{
		
		if ( $args >= 0) 
		{
			my $return;
			
			for (@keys ) 
			{
				chomp;
				if ($_ =~ /.js$/)
				{
					$return .= qq{<script  src="$_"></script>\n}; 
				}
				elsif ($_ =~ /.css$/)
				{
					$return .= qq{<link href="$_" rel="stylesheet" style="text/css">\n}; 
				}
				else 
				{
					# do nothing
				}
			}
			
			return qq{$return}; 	#
		}
		else 
		{
			return qq{$out}; 
		}
		
	}
	else 
	{
		return qq{<!--229 noParams-->$out}; 	# 
	} 
	
}





# start end_html 
sub end_html 
{ 
	my $self = shift;
	
	my @keys; 
	if (@_) { @keys = @_; } 
	
	my ($key, $key1) = @_;
	
	my $out; 
		
	$out .= qq{</html>\n\n};
	
	if ($ARGV and $ARGV > 0 or scalar(@keys) > 0) 
	{
		return qq{@_};
	}
	else 
	{	
		return $out; 
	}
} 
# end end_html




# start head title 02 
sub head_title
{
	my $self = shift;
	
	my $key = "@_"; 
	
	my @keys; 
	if (@_) { @keys = @_; } 
	
	my $out; 
	
	$out .= qq{}; 
	
	if ($ARGV and $ARGV > 0 or scalar(@keys) > 0) 
	{
		
		if ($key) 
		{
			return qq{<title>@_</title>\n}; 
		}
		else 
		{
			return qq{<title>Template</title>\n}; 
		}
		
	}
	else 
	{
		return qq{<title>Package Html5</title>\n}; 	# this works but does not ask the user
	}
	
} 
# end head title 




# begin head meta 03
sub head_meta
{
	my $self = shift;
	
	my $key = "@_"; 
	
	my @keys; 
	if (@_) { @keys = @_; } 
	
	my $args = scalar @keys; 
	
	my $out; 
	
	$out .= qq{<meta charset="utf-8">
<meta lang="en">
<meta http-equiv="X-UA-Compatible" content="IE=edge"> 
<meta name="HandheldFriendly" content="true"> 
<meta name="viewport" content="width=device-width, initial-scale=1"> 
}; 
	
	if ($args) 
	{
		
		if ($args >= 0) 
		{
			my $return;
			
			for (@keys ) 
			{
				chomp;
				
				my ( $meta_name, $meta_cont) = split(/---/, $_, 2);
				
				$return .= qq{<meta name="$meta_name" content="$meta_cont">\n}; 
			}
			
			return qq{$return<!--360-->}; 
		}
		else 
		{
			$out .= qq{<meta name="description" content="HTML5 by Business Impact Solutions - bislinks.com"/><!--364-->}; 
			# add default meta if user has not called one of his own
			return qq{$out}; 
		}
		
	}
	else 
	{
		return qq{$out}; 	# this works but does not ask the user
	}
	
} 
# end head meta 03 




# begin body top nav bar
sub body_topnavbar
{
	my $self = shift;
	
	my %in;
	
	%in = (
		file => "https://www.a1z.us/js/utils/top-nav-bar.js",
		name => "Menu",
		@_,
	);
	
	my $out; 
	
	$out .= qq{<!--top nav bar begin-->
<script src="$in{file}"></script>
<script>
	fixed_top_navbar('', '', '$in{name}', '', '');
</script>
<!-- top nav bar end--> 
}; 
	
	return qq{$out\n}; 	# this works but does not ask the user
	
} 
# end body top nav bar




sub head_js_css
{
	my $self = shift;
	
	my $key = "@_"; 
	
	my @keys; 
	if (@_) { @keys = @_; } 
	
	my $args = scalar (@keys); 
	
	my $out; 
	
	$out .= qq{
	
	<!-- Bootstrap/jqueryUI -->

	<link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.0/css/bootstrap.min.css" rel="stylesheet" type="text/css">
	<link href="https://www.a1z.us/jquery/bootstrap/fixed-top/navbar-fixed-top.css" rel="stylesheet">
	<link href="https://code.jquery.com/ui/1.12.1/themes/smoothness/jquery-ui.css" rel="stylesheet">

	<!--HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries-->

	<!--[if lt IE 9]>
	<script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
	<script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
	<![endif]-->

}; 
	
	if ($args) 
	{
		
		if ($args >= 0) 
		{
			my $return;
			
			for (@keys) 
			{
				chomp;
				if ($_ =~ /.js$/)
				{
					$return .= qq{<!--442--> \n<script  src="$_"></script> \n}; 
				}
				elsif ($_ =~ /.css$/)
				{
					$return .= qq{<!--446--> \n<link href="$_" rel="stylesheet" style="text/css"> \n}; 
				}
				else 
				{
					# do nothing
					return qq{@keys<!--469-->\n}; 
				}
			}
			
			return qq{$return<!--473 jQ-->\n}; 
		}
		else 
		{
			return qq{$out\n}; 
		}
		
	}
	else 
	{
		return qq{$out\n}; 	# this works but does not ask the user
	}
	
} 
# end head js css




# begin end head
sub end_head 
{ 
	my $self = shift;
	
	my $key = "@_"; 
	
	my @keys; 
	if (@_) { @keys = @_; } 
	
	my $out; 
	
	$out .= qq{</head>}; 
	
	if ($ARGV and $ARGV > 0 or scalar(@keys) > 0) 
	{
		
		if (@_) 
		{
			return qq{@_\n}; 
		}
		else 
		{
			return qq{$out\n}; 
		}
		
	}
	else 
	{
		return qq{$out\n}; 	# this works but does not ask the user
	}
} 
# end end head 



# begin begin body 
sub begin_body 
{ 
	my $self = shift;
	
	my $key = "@_"; 
	
	my @keys;  
	if (@_) { @keys = @_; } 
	
	my $out; 
	
	$out .= qq{<body>}; 
	
	if ($ARGV and $ARGV > 0 or scalar(@keys) > 0) 
	{
		
		if (@_) 
		{
			return qq{@_\n}; 
		}
		else 
		{
			return qq{$out\n}; 
		}
		
	}
	else 
	{
		return qq{$out\n}; 	# this works but does not ask the user
	}
} 
# end begin body



# begin accordion or rather file content.  Need to change name of this method
sub body_accordion 
{
	my $self = shift;
	
	my $key = "@_"; 
	
	my @keys;  
	if (@_) { @keys = @_; } 
	
	my $out; 
	
	$out .= qq{<!--begin Content--> 
<div id="accordion617" class="accordion">
	<h3>Who is it for</h3>
	<div>For those who know/uderstand Perl/HTML/jQuery</div>
	<h3>What about a bigger number?</h3>
	<div>Sure.  Use the custom form to get the times table for a number greater than 30?</div>
	<h3>How about any number/range?</h3>
	<div>Yes, of course!  Once again, use the custom form bearing the heading "Or enter your own"</div>
	<h3>Can I customize it for own use?</h3>
	<div>In that case, you need to purchase the software and/or order a customization</div>
</div>

<!--end Content-->

}; 
	
	if ($ARGV and $ARGV > 0 or scalar(@keys) > 0) 
	{
		
		if (@_) 
		{
			return qq{\n@_\n}; 
		}
		else 
		{
			return qq{\n$out\n}; 
		}
		
	}
	else 
	{
		return qq{\n$out\n}; 	#
	}
} 
# end accordion




sub body_article 
{  
	my $self = shift;
	
	my $out;
	
	my %in;
	%in = 
	(
		content => "",
		type => "article",
		header => "Content Header",
		@_,
	);
	
	if ( !defined $in{content} or $in{content} eq '' )
	{
		return qq{
			No Content
		};
	}
	else
	{
		return qq{<article class="container"><h2>$in{header}</h2>
			$in{content}
		</article>
		};
	}
}




# begin begin body 
sub end_body 
{ 
	my $self = shift;
	
	my $key = "@_"; 
	
	my @keys;  
	if (@_) { @keys = @_; } 
	
	my $out; 
	
	$out .= qq{\n</body>\n}; 
	
	if ($ARGV and $ARGV > 0 or scalar(@keys) > 0) 
	{
		
		if (@_) 
		{
			return qq{@_\n}; 
		}
		else 
		{
			return qq{$out\n}; 
		}
		
	}
	else 
	{
		return qq{$out\n}; 	# this works but does not ask the user
	}
} 
# end end body





# begin content folder to select form 
sub body_form 
{
	my $self = shift; 
	
	my $out; 
	
	my @keys;  
	if (@_) { @keys = @_; } 
	
	my ($vars, $vals) = (''); 
	for (@keys) 
	{
		$vars = $_ if ($_ =~ /^vars/); 

		# $vals not used
		$vals = $_ if ($_ =~ /^vals/); 
	}
	
	my @form_vars = split(/\;/, $vars); 
	
	my @form_vals = split(/\;/, $vals); 
	
	# get params for hidden fields if given 
	my @hidden; 
	if ($form_vars[4] and $form_vars[4] =~ /\,/) 
	{
		 @hidden = split(/\,/, $form_vars[4]); 
	}
	else 
	{
		@hidden = ("No", "Vals"); 
	}
	
	# if SELECT .... 
	
	my $select; 
	
	if ($form_vars[3] and $form_vars[3] =~ /^select/) 
	{
		# get the params for the form 
		#   select,   
		my ($sel_key, $sel_name, $sel_default, $folder_or_file, $selectLabelText) = split(/\,/, $form_vars[3], 5); 

		$select .= qq{
	<label for="$sel_name">$selectLabelText</label>
	<div class="form-group"><!--begin select-->
	\t<select name="$sel_name">
	\t\t<option selected value="$sel_default">$sel_default</option>
	};
		
		#now open file/folder to fill "options" 
		if ( -f $folder_or_file ) 
		{
			# open as file 
			#$select .= qq{none}; 
		}
		elsif (-d $folder_or_file)
		{
			# open as dir and add all files in it to "options" 
			opendir(D, "$folder_or_file") or $select .= qq{<div class="error">$!</div>};
			my @DIR = readdir(D);
			
			while ( my $file = <each @DIR> )
			{
				# only if file contains alphabets, numbers, and dashes 
				next unless $file =~ /[a-zA-Z0-9\-]/; 

				# comment if you want subfolders also listed 
				next unless -f "$folder_or_file/$file"; 

				# get rid of . and ..
				next if $file =~ /^(\.|\.\.)/; 

				# do not add hidden files to the options list
				next if $file =~ /^\./; 
				
				# get the size of th file 
				my $size = -s "$folder_or_file/$file"; 
				my $original = $size; 
					$size /= 1024; 
					#$size /= 1024;
					$size = sprintf "%.2f", $size; 
				$select .= qq{\n\t\t\t<option value="$file">$file [$size kb]</option>} if $file; 
			}

			close D;
		}

		$select .= qq{\n\t\t</select>\n\t</div>\n}; 
	}
	else 
	{
		# no select
		$select .= qq{}; 
	}
	 
	
	$out .= qq{<form action="$form_vars[2]" method="$form_vars[1]">};  
	
		# add hidden fields/values # from $form_vars[4] 
		for (@hidden)
		{
			my ($name, $value) = split(/\-\-\-/, $_, 2) if $_; 
			$out .= qq{\n\t<input type="hidden" name="$name" value="$value"/>} if $_; 
		}
		# add select 
		$out .= qq{$select};  
	$out .= qq{\n\t<button type="submit" class="btn btn-default">Submit</button>\n</form>\n}; 
	
	return qq{<div class="body_form">$out</div>}; 
}

# end body_form 



sub defaults_begin
{
	my $self = shift; 
	
	my $out;
	
	$out .= sprintf header(),  
		start_html(),  
		head_title("$_[0]"),  
		head_meta(), 
		head_meta("$_[1]"), 
		head_js_css(),  
		head_js_css("$_[2]"),  
		end_head(),  
		begin_body(),  
		body_topnavbar()
	;
		
		return $out; 
}



sub defaults_end 
{
	my $self = shift; 
	
	my $out;
	
	$out .= sprintf body_js_css(),
		body_js_css("$_[0]"),
		end_body(), 
		end_html() 
	;
	
	return $out;
}



# HTML 
my %HTML;

%HTML = (
	-defaultjquery => qq{\n<!-- -defaultjquery-->

		<!-- jquery-->
		<script src="https://code.jquery.com/jquery-1.12.4.min.js"></script>

		<!--bootstrap-->
		<script  src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.0/js/bootstrap.min.js"></script>

		<!--blueimp gallery-->
		<script src="https://blueimp.github.io/Gallery/js/jquery.blueimp-gallery.min.js"></script>

		<!-- jquery ui -->
		<script src="https://code.jquery.com/ui/1.11.4/jquery-ui.min.js"></script>

		<!-- IE10 viewport hack for Surface/desktop Windows 8 bug -->
		<script  src="https://www.a1z.us/jquery/bootstrap/fixed-top/ie10-viewport-bug-workaround.js"></script>
		<script >
		
		// for tabs 
		\$( function() {
			var tabs = \$( "#tabs" ).tabs();
			
			tabs.find( ".ui-tabs-nav" ).sortable({
				axis: "x",
				stop: function() { tabs.tabs( "refresh" ); }
			});
		}); 
		  
		// dialog 
		\$(function() {
			\$( "#dialog" ).dialog({
			  autoOpen: false,
			  show: {
				effect: "blind",
				duration: 1000
			  },
			  hide: {
				effect: "explode",
				duration: 1000
			  }
			});
		 
			\$( "#opener" ).click(function() {
			  \$( "#dialog" ).dialog( "open" );
			});
		});
		  
		\$('#menu').menu(); 
		\$('#accordion').accordion(); 
		\$('#accordion1').accordion(); 
		\$('#accordion2').accordion(); 
		\$('#accordion3').accordion(); 
		\$('accordion617').accordion();
		\$('#tabs').tabs(); 

		
		</script>
	},
	
	-default_LastItem => qq{},
	
);


sub html_bootstrap_css   
{
	return qq{<!-- Bootstrap/jqueryUI -->
<link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.0/css/bootstrap.min.css" rel="stylesheet" type="text/css">
<link href="https://www.a1z.us/jquery/bootstrap/fixed-top/navbar-fixed-top.css" rel="stylesheet">
};
  
}




sub html_jqueryui_css 
{
	# jquery ui theme jquery-ui.css #1.12.0
	return qq{<link href="https://code.jquery.com/ui/1.12.0/themes/smoothness/jquery-ui.css" rel="stylesheet">}; 
}




sub html_shim_respond 
{
	return qq{<!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
<!--[if lt IE 9]>
<script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
<script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
<![endif]-->
};

}



sub html_navbar 
{
	#my $self = shift; 

	#serverName, pageName, menuName, dropDownLinks
	
	my %in;
	%in = (
		-nbMenuName 	=>	"", 
		-nbPageName 	=> 	"",
		-nbServer    =>  "",
		-nbLinks => "blog-support-help-contact-sale",
		@_,		
	);
	
	return qq{<script src="https://www.a1z.us/js/utils/top-nav-bar.js"></script>
<!--top nav bar begin-->
<script>
//<-- 
fixed_top_navbar('$in{-nbServer}', '$in{-nbPageName}', '$in{-nbMenuName}', '$in{-nbLinks}');
//-->
</script>
<!-- top nav bar end--> 
}; 

}


 

sub html_bootstrap_js  
{
	# jquery:3.3.0 ui:1/12/1

	return qq{<!-- Bootstrap/jqueryUI -->
<link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.0/js/bootstrap.min.js" rel="stylesheet" type="text/css">

}; 

}

sub html_js_css 
{
	
}

sub html_jquery 
{
	
}



sub html_setTitle 
{
	my $out;

	my %in;
	
	%in = (
		ta => qq{},
		tb => qq{},
		tc => qq{},
		@_,
	);

	$out .= qq{<script>		
<!-- Begin
	function setTitle() 
	{
		var a = "$in{ta}";
		var b = "$in{tb}";
		var c = "$in{tc}";
		var t = new Date();
		s = t.getSeconds();
		if (s == 10) { document.title = a;}
		else if (s == 20) { document.title = b;}
		else if (s == 30) { document.title = c;}
		else if (s == 40) { document.title = a;}
		else if (s == 50) { document.title = b;}
		else if (s == 00) { document.title = c;}
		setTimeout("setTitle()", 1000);
	}
//  End -->
</script>
	};

	return $out; 
}




sub html_humanejs_css
{
	return qq{<link rel='stylesheet' href='https://cdnjs.cloudflare.com/ajax/libs/humane-js/3.2.2/themes/bigbox.css'>
      <link rel='stylesheet' href='https://cdnjs.cloudflare.com/ajax/libs/humane-js/3.2.2/themes/boldlight.css'>
      <link rel='stylesheet' href='https://cdnjs.cloudflare.com/ajax/libs/humane-js/3.2.2/themes/jackedup.css'>
      <link rel='stylesheet' href='https://cdnjs.cloudflare.com/ajax/libs/humane-js/3.2.2/themes/libnotify.css'>
      <link rel='stylesheet' href='https://cdnjs.cloudflare.com/ajax/libs/humane-js/3.2.2/themes/original.css'>
<link rel='stylesheet' href='https://cdnjs.cloudflare.com/ajax/libs/humane-js/3.2.2/themes/flatty.min.css'>
<link href='https://fonts.googleapis.com/css?family=Ubuntu&v2' rel='stylesheet' type='text/css'>
<link href='https://fonts.googleapis.com/css?family=Ubuntu+Mono' rel='stylesheet' type='text/css'>
<link href='https://fonts.googleapis.com/css?family=Cabin+Sketch:700&v2' rel='stylesheet' type='text/css'>
}; 

}




sub html_bootstrap_bluimp 
{
	return qq{<!-- The Bootstrap Image Gallery lightbox, should be a child element of the document body -->
		<div id="blueimp-gallery" class="blueimp-gallery blueimp-gallery-controls" data-use-bootstrap-modal="false">
	    <!-- The container for the modal slides -->
	    <div class="slides"></div>
	    <!-- Controls for the borderless lightbox -->
	    <h3 class="title"></h3>
	    <a class="prev">‹</a>
	    <a class="next">›</a>
	    <a class="close">×</a>
	    <a class="play-pause"></a>
	    <ol class="indicator"></ol>
	    <!-- The modal dialog, which will be used to wrap the lightbox content -->
	    <div class="modal fade">
	        <div class="modal-dialog">
	            <div class="modal-content">
	                <div class="modal-header">
	                    <button type="button" class="close" aria-hidden="true">&times;</button>
	                    <h4 class="modal-title"></h4>
	                </div>
	                <div class="modal-body next"></div>
	                <div class="modal-footer">
	                    <button type="button" class="btn btn-default pull-left prev">
	                        <i class="glyphicon glyphicon-chevron-left"></i>
	                        Previous
	                    </button>
	                    <button type="button" class="btn btn-primary next">
	                        Next
	                        <i class="glyphicon glyphicon-chevron-right"></i>
	                    </button>
	                </div>
	            </div>
	        </div>
	    </div>
	</div>
	};
}
# end sub html_bootstrap_bluimp 




sub head 
{
	my $self = shift; 
	
	my $out; 
	
	my %in = (
		-type 	=> "Content-Type: text/html;charset=utf-8\n\n", 
		-bootstrap 	=> html_bootstrap_css, 
		-jqueryui 	=> html_jqueryui_css, 
		-htmlshim	=> html_shim_respond, 
		-humanejs  => html_humanejs_css, 
		-title 		=> "A1Z .us", 
		-cssLinks => "https://code.jquery.com/ui/1.11.4/themes/ui-lightness/jquery-ui.css,https://blueimp.github.io/Gallery/css/blueimp-gallery.min.css,https://www.a1z.us/A1z/HTML5/Template.css", 
		-cssCode => "", 
		-mobilemeta => qq{<meta name="HandheldFriendly" content="true">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
}, 
		-charsetmeta => qq{<meta charset="utf-8">}, 
		-usermeta => "",
		-titleRotatingText => qq{text1,text2,text3},
		@_,
		
	); 


# rotating title function and text 
my $setTitle;
if ( $in{-titleRotatingText} and $in{-titleRotatingText} =~ /\,/ )
{
	my @a;
	@a = split(/\,/, $in{-titleRotatingText}, 3);

	$setTitle = html_setTitle(ta => "$a[0]", tb => "$a[1]", tc => "$a[2]");
}
else
{
	$setTitle = html_setTitle(ta => "Text01", tb => "text02", tc => "text03");
}

# css multiple links/files 
my $css; my @css; 
if ($in{-cssLinks} )
{
	if  ( $in{-cssLinks} =~ /\,/ ) 
	{
		@css = split(/\,/, $in{-cssLinks});
		for (@css) 
		{
			if ($_ =~ /\.css$/) 
			{
				$css .= qq{<link type="text/css" rel="stylesheet" href="$_">\n} ; 
			}
			else 
			{
				$css = ''; 
			}
		}
	}
}
else 
{
	$css = qq{}; 
}


	return qq{$in{-type}<!DOCTYPE html>
<html>
<head>
<title>$in{-title}</title> 
$in{-charsetmeta}
$in{-mobilemeta}
$in{-usermeta}
$in{-bootstrap} 
$in{-jqueryui} 
$in{-htmlshim} 
$in{-humanejs}
$css
<style type="text/css">
$in{-cssCode}
</style>

$setTitle

</head>
}; 	# thats orderly 

}
# end head 



sub body 
{
	my $self = shift; 
	
	my $out; 
	
	my %in; 
	
	%in = (
		-h1 => qq{A1Z .us},
		-onload => qq{setTitle();},  
		-nbhead => qq{},
		-nbpage => qq{}, 
		-nbmenu => qq{More}, 
		-defaultjquery => qq{$HTML{-defaultjquery}}, 
		-humanejs => qq{<script src="https://cdnjs.cloudflare.com/ajax/libs/humane-js/3.2.2/humane.min.js">},
		-userjquery => qq{}, 
		-navbar => html_navbar( $in{-nbmenu}, $in{-nbpage}, "", ""), 
		-content => qq{<div class="content">Content</div>}, 
		-footer => qq{All rights reserved &copy; A1Z .us}, 	
		-bootstrapbluimp => html_bootstrap_bluimp,
		-nbLinks => qq{contact-help-feedback},
		@_, 		
	); 
	
	return qq{<body onload="$in{-onload}">
<div id="main" class="container">
	<!--top nav bar begin-->
	<script  src="https://www.a1z.us/js/utils/top-nav-bar.js"></script>
	<script >
	//<-- 
	fixed_top_navbar('$in{-nbhead}', '$in{-nbpage}', '$in{-nbmenu}', '$in{-nbLinks}');
	//-->
	</script>

	$in{-bootstrapbluimp}

	$in{-h1}

	$in{-content}
	
	$in{-footer}

</div>

$in{-defaultjquery}

$in{-humanejs}
 
<script>
//<!--
$in{-userjquery}
//--> 
</script>

</body>
	
</html>
	
}; 

}
# end body 





sub open_file 
{
	my $self =shift;



	my %in;
	%in = 
	(
		file => "",
		
		output_header => "",

		output_format => "",

		@_,
	);

	my $file = "$in{file}" || "$_[0]"; 
	
	my $output_format = "$in{output_format}" || "$_[1]"; 	
	
	my $output_header = "$in{output_header}" || "$_[2]"; 
	
	my $out; 

	my $div4tabs;
	
	my @data; 
	
	if (-e -f "$file")
	{ 

		open(FILE, "$file") or die "$!";

		$out .= qq{\n<!--begin file output-->\n<div class="file_output">\n}; 
		
		# Step 1 
		# set the header as per format  
		if ($output_format eq 'table') 
		{ 
			$out .= qq{<table class="table table-striped table-bordered table-hover table-condensed table-responsive">
				<thead>
					<tr><th colspan="2">$output_header</th></tr>
				</thead>
				<tbody>
			}; 
		}
		elsif ($output_format eq 'accordion')
		{
			$out .= qq{<h2>$output_header</h2>\n<div id="accordion2" class="accordion"><!--118-->\n};
		} 
		elsif ($output_format eq 'menu') 
		{
			$out .= qq{<ul class="menu" id="menu">\n<li><a href="/">$output_header</a>\n<ul>};
		}
		elsif ($output_format eq 'tabs')
		{
			# special case for tabs since the data needs to be formatted a little differently 
			
			$out .= qq{<h2>$output_header</h2>\n<div id="tabs">\n<ul>\n};
			
			my $sl = '0'; 
			
				while ( my $line = <FILE>) 
				{
					$sl++ if $line; 
					
					my ($h1, $div) = (''); 
					
					if ($line =~ /\|/) 		
					{ 
						($h1, $div) = split(/\|/, $line, 2); 
					} 			# no (\|) # i.e., do not enclose with brackets
					elsif ($line =~ /\t+/) { 
						($h1, $div) = split(/\t+/, $line, 2); 
					} 
					elsif ($line =~ /\s+/) 
					{ 
						($h1, $div) = split(/\s+/, $line, 2); 
					}
					
					# Keep only those items that have '==' in the beginning  

					if ( $h1 =~ /^\s+/ or $div =~ /^\s+/ ) 
					{
						next unless ($h1 =~ /^\s+==/ or $div =~ /^\s+==/);
						$div =~ s!^\s+==!!g;
						$h1 =~ s!^\s+==!!g;
					}
					else
					{
						next unless ($h1 =~ /^==/ or $div =~ /^==/);
						$div =~ s!^==!!g;
						$h1 =~ s!^==!!g;
					}
				
					$out .= qq{\t<li><a href="#tabs-$sl">$h1</a></li>\n}; 

					$div4tabs .= qq{<div id="tabs-$sl">$div</div>};
				}
			$out .= qq{</ul>\n}; 

			$out .= $div4tabs;

			close FILE;
		}
		elsif ($output_format eq 'dialog')
		{
			$out .= qq{<h2>Dialog: <a href="#opener" id="opener" title="Opens the Dialog">$output_header</a></h2>
<div id="dialog">\n}; 
		}
		else 
		{
			$out .= qq{\n<h2>$output_header</h2>\n}; 
		}
		# End Step 1
		
		# now work on file 
		
		my $serial = '0'; 
		
		while ( my $line = <FILE> ) 
		{ 
			chomp $line; 
			
			$serial++ if $line; 
			
			my ($h1, $div) = (''); 
			
			if ($line) 				# make sure no output if line is empty
			{	
				$line =~ s! RN !\r\n!g;
				
				# split the file's lines into usable data according to separator used.
				if ($line =~ /\|/) 		
				{ 
					($h1, $div) = split(/\|/, $line, 2); 
				} 			# no (\|) # i.e., no enclosing with brackets.  was the culprit 
				elsif ($line =~ /\t+/) { 
					($h1, $div) = split(/\t+/, $line, 2); 
				} 
				elsif ($line =~ /\s+/) 
				{ 
					($h1, $div) = split(/\s+/, $line, 2); 
				}
				# end split the file's line according to match: 3 options: |, \t+, or \s+ 

			}
			
			# Step 2 
			#Now set the content as per output format 
			if ($output_format eq 'table') 
			{ 
				# Keep only those items that have a # in the beginning 
				 
				if ( $h1 =~ /^\s+/ or $div =~ /^\s+/ ) 
				{
					next unless ($h1 =~ /^\s+#/ or $div =~ /^\s+#/);
					$div =~ s!^\s+#!!g;
					$h1 =~ s!^\s+#!!g;
				}
				else
				{
					next unless ($h1 =~ /^#/ or $div =~ /^#/);
					$div =~ s!^#!!g;
					$h1 =~ s!^#!!g;
				}
				$out .= qq{\t<tr><td>$h1</td><td>$div</td></tr>\n}; 
			}
			elsif ($output_format eq 'accordion')
			{
				# Keep only those items that have -- in the beginning 
					
				if ( $h1 =~ /^\s+/ or $div =~ /^\s+/ ) 
				{
					next unless ($h1 =~ /^\s+--/ or $div =~ /^\s+--/);
					$div =~ s!^\s+--!!g;
					$h1 =~ s!^\s+--!!g;
				}
				else
				{
					next unless ($h1 =~ /^--/ or $div =~ /^--/);
					$div =~ s!^--!!g;
					$h1 =~ s!^--!!g;
				} 
				
				$out .= qq{\t<h3>$h1</h3>\n\t<div>$div</div>\n} if $line; 
			} 
			elsif ($output_format eq 'menu') 
			{
				# the first item will be used as link title and name
				# the second item will be used as the actual link  
				# no extensions added automatically by the script 
				# an id for each link/li is also provided in case, may be it is not needed 
				
				# Remove items with a # in the beginning; Sat Feb 21 18:48:19 2015
				next if ($h1 =~ /^#http/ or $div =~ /^#http/); 
				
				# Keep only those items that have a 'http' in the beginning 
				 
				if ( $h1 =~ /^\s+/ or $div =~ /^\s+/ ) 
				{
					next unless ($h1 =~ /^\s+http/ or $div =~ /^\s+http/);					
					#$div =~ s!^\s+http!!g;
					#$h1 =~ s!^\s+http!!g;
				}
				else
				{
					next unless ($h1 =~ /^http/ or $div =~ /^http/);
					#$div =~ s!^http!!g;
					#$h1 =~ s!^http!!g;
				}
				$out .= qq{\t<li id="li-$serial"><a id="a-$serial" href="$div" title="$h1">$h1</a></li>\n};
			}
			elsif ($output_format eq 'tabs') 
			{
				# Keep only those items that have a == in the beginning  
				
				if ( $h1 =~ /^\s+/ or $div =~ /^\s+/ ) 
				{
					next unless ($h1 =~ /^\s+==/ or $div =~ /^\s+==/);
					$div =~ s!^\s+==!!g;
					$h1 =~ s!^\s+==!!g;
				}
				else
				{
					next unless ($h1 =~ /^==/ or $div =~ /^==/);
					$div =~ s!^==!!g;
					$h1 =~ s!^==!!g;
				}
				
				# Mismatching fragment identifier. See 1797.
				# $div not available here as <FILE> is not open here.
				$out .= qq{\t<div id="tabs-$serial"><p>$div</p></div>\n}; 
				
			}
			elsif ($output_format eq 'dialog')
			{
				# includes everything; So, no filtering.
				
				# But, just remove symbols in both $h1 and $div
				$div =~ s!^(==|\#|--)!!g;
				$h1 =~ s!^(==|\#|--)!!g;
					
				$out .= qq{\t\t<h4 class="dialog-header">$h1</h4>\n\t\t<div class="dialog-content">$div <hr/></div>\n}; 
			}
			else 
			{
				$out .= qq{$h1 $div}; 	# or $line
			}
		} 
		
		# add an extra item at the end of file output 
		
		# Step 3 
		# set the output ending as per format  
		if ($output_format eq 'table') 
		{ 
			$out .= qq{\n</tbody>\n</table>\n\n}; 
		}
		elsif ($output_format eq 'accordion')
		{
			$out .= qq{\n<!--end accordion--></div>\n\n};
		} 
		elsif ($output_format eq 'menu') 
		{
			$out .= qq{</ul></ul>};
		}
		elsif ($output_format eq 'tabs')
		{
			$out .= qq{</div><!--end tabs-->\n}; 
		}
		elsif ($output_format eq 'dialog') 
		{
			$out .= qq{</div><!--end dialog-->\n}; 
		}
		else 
		{
			$out .= qq{\n\n}; 
		}
		
		# end file output wrapper
		$out .= qq{</div><!--end file output-->\n};  
		
		return $out; 
	}
	else 
	{
		my $out;

		
	
		$out .= qq{\n<!--begin accord 112-->\n<div id="accordion1460" class="accordion">\n}; 
		while ( my $line = <FILE> ) 
		{ 
			chomp $line; 
			
			my ($h1, $div) = (''); 
			
			($h1, $div) = split(/\t+/, $line, 2) if $line; 
			
			$out .= qq{\t<h3>$h1</h3>\n\t<div>$div</div>\n} if $line; 
		} 
		$out .= qq{\t<h3>Powered by</h3>\n\t<div>Perl/CPAN</div>\n}; 
		
		$out .= qq{</div>\n<!--end accord-->\n}; 
		
		return $out; 
	}

	close FILE;
	
}
# end open_file




sub edit_file
{
	my $self = shift;
	
	my $out;
	
	my %in;
	
	%in = (
		file => "",
		error => "",
		action => "TemplateAdmin.cgi",
		serial => '', 
		output_type => '',
		@_,
	);
	
	if (-e -f "$in{file}")
	{
		open(FILE, "$in{file}") or $in{error} = "unable to open $in{file}";
		my @file = <FILE>;
		close FILE;
		
		$out .= qq{
		<article class="container">
			
			<form action="$in{action}" method="post">
			<input type="hidden" name="action" value="write">
		};
		
		for (@file)
		{
			chomp;
			
			next if $_ =~ /^$/;
			
			$in{serial}++ if $_;
			
			my ( $type, $content ) = split(/\|/, $_, 2);
			
			$type =~ s!\s+$!!g;
			
			my $identifiers = substr "$content", 0, 4;	# has to be 4 to cover 'http.'  Also, assuming no spaces in the beginning (removed by write_file)
			
			# determine output type
			if ( $identifiers =~ /^\#/ ) { $in{output_type} = 'Table'; }
			elsif ( $identifiers =~ /^\-/ ) { $in{output_type} = 'Accordion'; }
			elsif ( $identifiers =~ /^\=/ ) { $in{output_type} = 'Tabs'; }
			elsif ( $identifiers =~ /^http/ ) { $in{output_type} = 'Menu'; }
			else { $in{output_type} = 'None'; }
			
			# remove all nonmeta characters for web page display 
			$identifiers =~ s!(\s+|[a-zA-z0-9])!!g;	# removes http also.
			
			$content =~ s!\<!&lt\;!g;
			$content =~ s!\>!&gt\;!g;
			
			$content =~ s! RN !\r\n!g; # &#13;&#10;
			
			$out .= qq`<div>
				<span class="serial">$in{serial} </span> 
				<span class="type">$type </span> 
				<span class="identifiers">$identifiers </span>
				<span class="type type-$in{output_type}">Type:$in{output_type} </span>
			</div>
			<div>
				<textarea name="ta-$type" id="ta-$type" rows="5" cols="98%" class="type-$in{output_type}">$type , $content</textarea>
			</div>
				<br/>
			`;
		}
		
		$out .= qq{<input type='submit' value="Save"></form></article>};
		
		
		return $out;
		
	}
}



sub write_file
{
	my $self = shift;
	
	my $out; 
	
	my %in;
	%in = 
	(
		file => "",
		error => "",
		powershell => "C:/WINDOWS/system32/WindowsPowerShell/v1.0/powershell.exe ",
		@_,
	);
	
	my %vars;
	
	use CGI;
	my $q = new CGI;
	%vars = $q->Vars();
	
	my $action = $q->param('action');
	
	if ( $action eq 'write')
	{

		if (-e -f "$in{file}")
		{
			
			# First, get file content to backup to another file
			open(F, "$in{file}") or $in{error} .= "#1565 Unable to open file for reading. '$!' <br/>";
			my @f = <F>;
			
			# save original file content to backup file
			open(BAK, ">$in{file},bak.txt") or $in{error} .= "#1570 Unable to create backup file '$in{file},bak.txt' '$!' <br/>";
			for (@f)
			{
				print BAK qq{$_};	
			}
			close BAK;
			
			close F;
			
			# recreate file, thereby deleting original content 
			open(DEL, ">$in{file}") or $in{error} .= "#1579 Unable to recreate file '$in{file}' '$!' <br/>";
			print DEL "File ReCreated";
			close DEL;
			
			my %out;
			for (keys %vars)
			{
				chomp $_; 
				chomp $vars{$_}; 
				
				next if $_ eq 'action';
				my ( $name, $value ) = split(/\,/, $vars{"$_"}, 2);
				
				$name =~ s!(\r\n+|\n+)! RN !g;
				$value =~ s!(\r\n+|\n+)! RN !g;
				
				$value =~ s!^\s+!!g;
				
				$out{"$name"} = "$value";
			}			
			
			# Insert/Add new content
			open(FILE, ">$in{file}") or $in{error} .= "#1582 Error writing to file '$in{file}' '$!' <br/>";			
			for (keys %out) 
			{
				print FILE qq{$_\|$out{$_}\n};
			}
			close FILE;
			
			
			if (-e -f "$in{file},bak.txt" and -e -f "$in{file}")
			{	
				return "<div class='success'>Saved</div> <div class='error'>$in{error}</div>";
			}
			else
			{
				return "<div>#1605 Error saving file '$in{file}'</div> <div class='error'>$in{error}</div>";
			}
		}
		else
		{
			return "File not found";
		}
	}
	elsif ( $action eq 'newItem' )
	{
		return "$action";
	}
	else
	{
		return '* ' x 10;
	}
	
}

# end write_file




sub display_gallery_thumbnails
{
	my $self = shift;

	my $out;

	my %in;

	%in = (
		
		error => "",

		images_dir => "/images/a1z-html5-template/",
		thumbs_dir => "/images/a1z-html5-template/thumbs",
		
		images_url => "/images/a1z-html5-template",
		thumbs_url => "/thumbs/a1z-html5-template/thumbs",

		width => "100",
		height => "100",

		@_,
	);

	if (-e -d "$in{images_dir}" and "$in{thumbs_dir}" )
	{
		opendir(TH, "$in{thumbs_dir}") or $in{error} .= qq{<p>$!</p>};
		my @thumbs = readdir(TH);
		close TH;

		foreach ( @thumbs ) 
		{
			if ( $_ and $_ =~ /(.jpg|.gif|.jpeg|.png|.tiff)$/ )
			{
				$out .= qq{\n<a href="$in{images_url}/$_" title="$_" data-gallery> <img src="$in{thumbs_url}/$_" alt="Image $_" width="$in{width}" height="$in{height}"> </a> \n};
			}
		}
	}
	else
	{
		$in{error} .= qq{<p>Image directory does not exist or is inaccessible. Make sure you provided the correct path.</p>};

		$out = $in{error};
	}

	return $out;
}
# end display gallery thumbnails 









1;

__END__

=pod

=encoding UTF-8

=head1 NAME

A1z::HTML5::Template - Fast and easy Web Apps

=head1 VERSION

version 0.22

=head1 SYNOPSIS

    use A1z::HTML5::Template;
    my $h = A1z::HTML5::Template->new();

    This directory should be writable by the web server, required to create/hold page content files.
	This may also contain your custom JavaScript/CSS libraries.
	Works for both Windows and Linux
	
		use lib '/home/user/path/to/app';
		or
		use lib 'C:/Inetpub/wwwroot/path/to/app';

	# for features like 'say'
	use 5.10.0;

	my $h = A1z::HTML5::Template->new(); 

	Fast, Easy, and Simple: Just Two Lines!
	
		say $h->head( -title => "My Brand Name" );
		say $h->body( -content => qq{ Coming Soon });

	For More Control/Customization: Not for the lazy!
	
	say $h->header('utf8');  
	say $h->start_html(); 
	say $h->head_title("My New App"); 
	say $h->head_meta(); 

	Load basic/required JavaScript/CSS libraries
	say $h->head_js_css(); 

	Add your own custom JavaScript/CSS files
	say $h->head_js_css('/url/to/app/Template.css'); 

	say $h->end_head(); 
	say $h->begin_body();

	say qq{<h1>My New App/Website</h1>};

	say qq{<main class="container">}; 

		# output file content as menu
		say $h->body_accordion( $h->open_file("/home/user/path/to/app/open_file_example.txt", 'menu', 'Menu') ); 

		# as a HTML5 table 
		say $h->body_accordion( $h->open_file("$sys{cgibase}/open_file_example.txt", 'table', 'Table Header') );
		
		# Simple mathematics 
		say $h->body_article( header => "Simple Mathematics", content => $h->math1("2", "4") );

		# Times Table  
		say $h->body_article( header => "Times Table", content => $h->timestable("2") );

	say qq{</main>};

	Required/Default JavaScript libraries.
		say $h->body_js_css(); 
	
	Add your own JavaScript libraries:
		say $h->body_js_css("complete-url_or_path-to-js-css-libraries")	

	say $h->end_body();
	say $h->end_html(); 

=head1 NAME

	Fast and Easy Web Apps

	"A1z::HTML5::Template" provides customizable HTML5 tags for creating "Fast and Easy Web Apps."

=head2 VERSION

	0.22

=head1 Installation

	cpan install A1z::HTML5::Template 
	or
	cpanm A1z::HTML5::Template

=head1 METHODS

	header start_html head_title head_meta head_js_css end_head begin_body body_js_css body_topnavbar body_accordion end_body end_html 

=head2 new

   use A1z::HTML5::Template;
   my $h = A1z::HTML5::Template->new();

=head2 math1

	$h->math1(num1, num2);
	
	$h->body_article( header => "Math", content => $h->math1(num1, num2) );

=head2 timestable

	$h->timestable("Number");

=head2 header

	Provides HTML Content-Header 
	
	$h->header("");

=head2 start_html

	Provides doctype html
	
	Default includes utf-8

		$h->start_html();
	
	Or, add your own charset to your app:

		$h->start_html('DifferentCharset');

=head2 body_js_css

	Add/include javascript and css files just above </body> section 
	
	Typically, CSS files should/are not be used here. 
	
	Default behavior: 
	
		$h->body_js_css();
		
		Includes 
			jquery 1.12.4, jquery ui 1.11.4, bootstrap 3.3.0, 
			javascript for #dialog function, #menu, #accordion, #tabs 
	
	Add your own .js file: 
		
		use $h->body_js_css("/path/to/js/file.js");
		
	You can use both to include default .js files and your own custom .js file. 

=head2 end_html 

	Provides </html>

=head2 head_title

	Provides <title></title>
	
	$h->head_title("App/Page Title");

=head2 head_meta

	Provides <meta ... >. Includes the following by default:
		IE=Edge
		HandheldFriendly
		viewport
	
	$h->head_meta();
	
	Just like body_js_css, you can use both to add default values and your own meta 

=head2 body_topnavbar

	Provides top nav bar optionally.
	
	By default it is loaded from www.a1z.us which probably be removed in a future version.
	So, get a copy from bootstrap 3 and store it on your server.

=head2 head_js_css

	provides the ability to add/include .js/.css files in the </head> tag.
	
	$h->head_js_css();
	
		Default includes the following:
		
			bootstrap 3.3.0 .css from maxcdn 
			navbar-fixed-top.css from www.a1z.us
			jquery 1.12.1 smoothness theme from code.jquery.com 
			Shim and Respond.js from maxcdn 
	
	$h->head_js_css("/path/to/.js")
	$h->head_js_css("/path/to/.css")

=head2 end_head

	Provides </head>
	
	$h->end_head();

=head2 begin_body

	provides <body> tag.
	
	$h->begin_body();

=head2 body_accordion

	The accordion in 'body_accordion' is misleading. It is not limited to just an accordion but all kinds of content.

	C<say $h->body_accordion( $h->open_file("/path/to/app/open_file_example.txt", 'Type', 'Heading') );>

	C<say $h->body_accordion( $h->open_file("/path/to/app/open_file_example.txt", "table", "Name and Price");

	C<say $h->body_accordion( $h->open_file("/path/to/app/open_file_example.txt", "tabs", "Space Saving Tabs");

=head2 body_article

	provides the ability to add content into <main> tags. 
	
	$h->body_article( header => "", content => "");

=head2 end_body

	provides </body> tag.
	
	$h->end_body();

=head2 body_form

	Form, lists items from a directory in a neat drop-down list with each item's file size in KB!

	Should be in the exact format like below: 
	
	$h->body_form("vars;METHOD;Action.cgi;select,NameForSelectTag,DefaultOptionSelected,AbsPathToDir,TextForSelectLabel;hidN1---hidV1,hidN2---hidV2,hidN3---hidV3");

=head2 defaults_begin

	Internal Use Only

	Provides defaults for very lightweight template for those in a hurry; Can be used for apps/sites that are under construction! 
	
	$h->defaults_begin();

=head2 defaults_end

	Internal Use Only.

	provides defaults for lightweight or under construction app/website. 
	
	$h->defaults_end();

=head1 HTML Hash

	For Internal/Future Use

	Hash contains -defaultjquery which is used in body.

	-defaultjquery includes 
		
		jquery                1.12.4       from code.jquery
		jquery ui             1.11.4       
		bootstrap             3.3.0        from maxcdn
		blueimp-gallery
		ie-10 workaround                   from a1z.us
		
		functions
		
			tabs, dialog, menu, accordion

=head2 html_bootstrap_css 

	For Internal/Future Use

	Used in $h->head and $h->body internally.

	All methods starting with 'html_' are used internally!

	Include bootstrap.min.css, #3.3.0 from maxcdn and navbar-fixed-top.css from a1z.us
		
		$h->html_bootstrap_css()

=head2 html_jqueryui_css

	For Internal/Future Use

	Includes jquery ui theme jquery-ui.css #1.12.0

=head2 html_shim_respond

	For Internal/Future Use

	html5shiv.min.js   #3.7.2
	respond.min.js     #1.4.2

=head2 html_navbar

	For Internal/Future Use

	Customizations for top-nav-bar.js from a1z.us

	$h->html_navbar(
		-nbMenuName => "menuName", 
		-nbPageName => "pageName", 
		-nbServer => "serverName", 
		-nbLinks => "dropDownLinks: URLs separated by a dash, mostly relative URLs. E.g., blog-support-help-contact-sale"
	);

=head2 html_bootstrap_js

	For Internal/Future Use

	bootstrap.min.js, #3.3.0, from maxcdn

=head2 html_setTitle 

	For Internal/Future Use

	setTitle javascript function 

	Used in body

	Includes the C<script> tag pair

	C<$h->html_set_title( ta => "Text001", tb => "TExt002", tc => "TeXt003" );>

=head2 html_humanejs_css

	For Internal/Future Use

	humane-js #3.2.2 cdnjs.cloudflare
	fonts.googleapis.com

=head2 html_bootstrap_bluimp

	For Internal/Future Use

	bootstrap gallery lightbox controls for use immediately after C<body> tag

	C<&html_bootstrap_bluimp;>

	Used internally in C<$h->body()> 

=head2 head

	$h->head();

	$h-head (
		-type 	=> "Content-Type: text/html;charset=utf-8\n\n", 
		-bootstrap 	=> html_bootstrap_css, 
		-jqueryui 	=> html_jqueryui_css, 
		-htmlshim	=> html_shim_respond, 
		-humanejs  => html_humanejs_css, 
		-title 		=> "A1Z .us", 
		-cssLinks => "https://code.jquery.com/ui/1.11.4/themes/ui-lightness/jquery-ui.css,https://blueimp.github.io/Gallery/css/blueimp-gallery.min.css,https://www.a1z.us/A1z/HTML5/Template.css", 
		-cssCode => "", 
		-mobilemeta => qq{<meta name="HandheldFriendly" content="true">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
}, 
		-charsetmeta => qq{<meta charset="utf-8">}, 
		-usermeta => "",
		-titleRotatingText => qq{text1,text2,text3}	
	); 

=head2 body

	$h->body();

	$h->body(
		-h1	=> qq{A1Z .us},
		-onload => qq{setTitle();},  
		-nbhead => qq{},
		-nbpage => qq{}, 
		-nbmenu => qq{More}, 
		-defaultjquery => qq{$HTML{-defaultjquery}}, 
		-humanejs => qq{<script src="https://cdnjs.cloudflare.com/ajax/libs/humane-js/3.2.2/humane.min.js">},
		-userjquery => qq{}, 
		-navbar => html_navbar( $in{-nbmenu}, $in{-nbpage}, "", ""), 
		-content => qq{<div class="content">Content</div>}, 
		-footer => qq{All rights reserved &copy; A1Z .us}, 	
		-bootstrapbluimp => html_bootstrap_bluimp,
		-nbLinks => qq{contact-help-feedback}		
	); 

=head1 open_file

	Used for loading all kinds of custom elements for different output formats stored in simple text files.

	$h->open_file("/path/to/file", "outputFormat", "outputHeader");

	$h->open_file("C:/Inetpub/wwwroot/MyApp/menu.txt", "menu", "Menu");

	This is the heart of the App.

=head2 OUTPUT FORMAT OPTIONS: 

	table, accordion, menu, as is; where "as is" is the default

	$h->open_file( file => "abs/path/to/file", output_format => "table", output_header => "Heading" ); 

=head2 edit_file

	Edit your app/page/site. Customize HTML produced by A1z::HTML5::Template. 

	Creates a form to edit contents of a file. 

	The contents of this file should be in a special format. See open_file_example.txt. 

	Data is stored in simple text files in the app's home dir.  

	We recommend creating a separate file for editing/writing purposes, e.g., "TemplateAdmin.cgi"

	use lib '/path/to/app';

	use A1z::HTML5::Template;
	my $h = A1z::HTML5::Template->new();

	say $h->header('utf8');
	say $h->start_html(); 
	say $h->head_title("Edit App"); 
	say $h->head_meta();
	say $h->head_js_css();  
	say $h->end_head(); 
	say $h->begin_body();

	# Show edit form

 	say $h->body_article( 

		header => "Edit page items", 

		action => "TemplateAdmin.cgi",

		content => $h->edit_file( file => "/absolute/path/to/app/open_file_example.txt") 
	);

	# Save Customizations back to the same file.

	# include write_file if you submit form to the same file ( TemplateAdmin.cgi )

	say $h->body_article( 

		header => "<a href='$sys{cgiurl}/TemplateAdmin.cgi' title='Refresh to get the latest/saved content'>Refresh</a> ", 

		content => $h->write_file( file => "/absolute/path/to/app/open_file_example.txt")
	 
	);

	say $h->body_js_css(); 
	say $h->end_body();
	say $h->end_html(); 

=head2 write_file

	See documentation for 'edit_file.'

=head2 display_gallery_thumbnails

	my $images = $h->display_gallery_thumbnails(

		images_dir => "{images_dir}",
		thumbs_dir => "{thumbs_dir}",
		
		images_url => "{images_url}",
		thumbs_url => "{thumbs_url}",

		width => "100",
		height => "100"
	);

=head1 BUGS

Please report any bugs or feature requests to C<bug-a1z-html5-template at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=A1z-HTML5-Template>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc A1z::HTML5::Template

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=A1z-HTML5-Template>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/A1z-HTML5-Template>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/A1z-HTML5-Template>

=item * Search CPAN

L<https://metacpan.org/release/A1z-HTML5-Template>

=back

=head1 ACKNOWLEDGEMENTS

	I am greatly indebted to my family for letting me be 'addicted' and 'married' to my computers.

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Sudheer Murthy.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=head1 AUTHOR

Sudheer Murthy <pause@a1z.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Sudheer Murthy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
