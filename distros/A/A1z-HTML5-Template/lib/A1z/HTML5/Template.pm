use strict;
use warnings;
package A1z::HTML5::Template;

# ABSTRACT: turns baubles into trinkets


our $VERSION = '0.07';



use parent qw(Exporter); 
require Exporter; 
our @ISA = ("Exporter"); 

our @EXPORT_OK = qw(header start_html head_title head_meta head_js_css end_head begin_body body_js_css body_topnavbar 
body_accordion end_body end_html 
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
	#$out .= "Repeat this line 4 times\n"  x 4 . "\n";
	
	my $m = $num1 * $num2;		# To avoid error: #Argument "Addition 8 + 4 = 8" isn't numeric in addition <+> at Template.PM line 70# do the math in a new var
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
	
	# my %in = (
		# -type => "Content-Type: text/html",  
		# -char => "charset=utf-8\n\n", 
		# @_,
		
	# ); 
	
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
	
	$out .= qq{<!--jquery-->
<script src="/jquery/jquery-1.11.1.min.js"></script>
<!--bootstrap/jQueryUI-->
<script src="/jquery/bootstrap/js/bootstrap.min.js"></script>
<script src="/jquery/ui/1.11.2.lightness/jquery-ui.min.js"></script>

<!-- IE10 viewport hack for Surface/desktop Windows 8 bug -->
<script type="text/javascript" src="/jquery/bootstrap/fixed-top/ie10-viewport-bug-workaround.js"></script>
<script type="text/javascript">
// for tabs 
\$(function() {
    var tabs = \$( "#tabs" ).tabs();
    tabs.find( ".ui-tabs-nav" ).sortable({
      axis: "x",
      stop: function() {
        tabs.tabs( "refresh" );
      }
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
\$('#tabs').tabs(); 
//\$('#dialog').dialog(); // no need, is taken care by the animation dialog above.  enabling this will make the dialog appear on load instead of on click of a/the link
</script>
}; 
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
					$return .= qq{<script type="text/javascript" src="$_"></script>\n}; 
				}
				elsif ($_ =~ /.css$/)
				{
					$return .= qq{<link href="$_" rel="stylesheet" style="text/css">\n}; 
				}
				else 
				{
					# do nothing
					#return qq{<!--213--> @keys\n}; 
				}
			}
			
			return qq{<!--216 jQ-->$return}; 	#
		}
		else 
		{
			return qq{<!--223 noArgs-->$out}; 
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
		
	$out .= qq~</html>\n\n~;
	
	if ($ARGV and $ARGV > 0 or scalar(@keys) > 0) 
	{
		return qq~@_~;
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
	
	$out .= qq~~; 
	
	if ($ARGV and $ARGV > 0 or scalar(@keys) > 0) 
	{
		
		if ($key) 
		{
			return qq~<title>@_</title>\n~; 
		}
		else 
		{
			return qq~<title>Template</title>\n~; 
		}
		
	}
	else 
	{
		return qq~<title>Package Html5</title>\n~; 	# this works but does not ask the user
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
	
	$out .= qq~<meta charset="utf-8">
<meta lang="en">
<meta http-equiv="X-UA-Compatible" content="IE=edge"> 
<meta name="HandheldFriendly" content="true"> 
<meta name="viewport" content="width=device-width, initial-scale=1"> 
~; 
	
	if ($args) 
	{
		
		if ($args >= 0) 
		{
			my $return;
			
			for (@keys ) 
			{
				chomp;
				
				my ( $meta_name, $meta_cont) = split(/---/, $_, 2);
				
				$return .= qq~<meta name="$meta_name" content="$meta_cont">\n~; 
			}
			
			return qq~$return<!--360-->~; 
		}
		else 
		{
			$out .= qq~<meta name="description" content="HTML5 by Business Impact Solutions - bislinks.com"/><!--364-->~; 
			# add default meta if user has not called one of his own
			return qq~$out~; 
		}
		
	}
	else 
	{
		return qq~$out~; 	# this works but does not ask the user
	}
	
} 
# end head meta 03 

# begin body top nav bar
sub body_topnavbar
{
	my $self = shift;
	
	my %in;
	
	%in = (
		file => "/A1z/Html5/Template/tob-nav-bar.js",
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
	
	return qq~$out\n~; 	# this works but does not ask the user
	
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
	
	$out .= qq~<!-- Bootstrap/jqueryUI -->

<link href="/jquery/bootstrap/css/bootstrap.min.css" rel="stylesheet" type="text/css">
<link href="/jquery/bootstrap/fixed-top/navbar-fixed-top.css" rel="stylesheet">
<link href="/jquery/ui/themes/smoothness/jquery-ui.min.css" rel="stylesheet">
<link href="/jquery/ui/themes/smoothness/theme.css" rel="stylesheet">

<!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
<!--[if lt IE 9]>
<script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
<script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
<![endif]-->

~; 
	
	if ($args) 
	{
		
		if ($args >= 0) 
		{
			my $return;
			
			for (@keys ) 
			{
				chomp;
				if ($_ =~ /.js$/)
				{
					$return .= qq~<!--442--> \n<script type="text/javascript" src="$_"></script> \n~; 
				}
				elsif ($_ =~ /.css$/)
				{
					$return .= qq~<!--446--> \n<link href="$_" rel="stylesheet" style="text/css"> \n~; 
				}
				else 
				{
					# do nothing
					return qq~@keys<!--469-->\n~; 
				}
			}
			
			return qq~$return<!--473 jQ-->\n~; 
		}
		else 
		{
			return qq~$out\n~; 
		}
		
	}
	else 
	{
		return qq~$out\n~; 	# this works but does not ask the user
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
	
	$out .= qq~</head>~; 
	
	if ($ARGV and $ARGV > 0 or scalar(@keys) > 0) 
	{
		
		if (@_) 
		{
			return qq~@_\n~; 
		}
		else 
		{
			return qq~$out\n~; 
		}
		
	}
	else 
	{
		return qq~$out\n~; 	# this works but does not ask the user
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
	
	$out .= qq~<body>~; 
	
	if ($ARGV and $ARGV > 0 or scalar(@keys) > 0) 
	{
		
		if (@_) 
		{
			return qq~@_\n~; 
		}
		else 
		{
			return qq~$out\n~; 
		}
		
	}
	else 
	{
		return qq~$out\n~; 	# this works but does not ask the user
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
	
	$out .= qq~<!--begin Content--> 
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
~; 
	
	if ($ARGV and $ARGV > 0 or scalar(@keys) > 0) 
	{
		
		if (@_) 
		{
			return qq~@_\n~; 
		}
		else 
		{
			return qq~\n<!--525--> \n$out\n~; 
		}
		
	}
	else 
	{
		return qq~\n$out\n~; 	#
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
	
	$out .= qq~\n</body>\n~; 
	
	if ($ARGV and $ARGV > 0 or scalar(@keys) > 0) 
	{
		
		if (@_) 
		{
			return qq~@_\n~; 
		}
		else 
		{
			return qq~$out\n~; 
		}
		
	}
	else 
	{
		return qq~$out\n~; 	# this works but does not ask the user
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
	
	my ($vars, $vals) = ''; 
	for (@keys) 
	{
		$vars = $_ if ($_ =~ /^vars/); 
		$vals = $_ if ($_ =~ /^vals/); 
	}
	
	my @form_vars = split(/\;/, $vars); 
	
	my @form_vals = split(/\;/, $vals); 
	
	# get params for hidden fields if given 
	my @hidden; 
	if ($form_vars[4] and $form_vars[4] =~ /\,/) 
	{
		 @hidden = split(/\,/, $_) if $_; 
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
		my ($sel_key, $sel_name, $sel_default, $folder_or_file) = split(/\,/, $form_vars[3], 4); 
		$select .= qq~<label for"$sel_name">$sel_default</label>
<div class="form-group"><!--begin select-->
<select name="$sel_name">
	<option selected value="$sel_default">$sel_default</option>
~;
		
		#now open file/folder to fill "options" 
		if ( -f $folder_or_file ) 
		{
			# open as file 
			#$select .= qq~none~; 
		}
		elsif (-d $folder_or_file)
		{
			# open as dir and add all files in it to "options" 
			opendir (D, "$folder_or_file") or print "$!";
			my @dir = readdir(D); 
			close D;
			
			for my $file (@dir)
			{
				next unless $file =~ /[a-zA-Z0-9]/; 
				# comment if your want subfolders also listed 
				next unless -f "$folder_or_file/$file"; 
				# get rid of . and ..
				next if $file =~ /^(\.|\.\.)/; 
				# do not add hidden files to the options list
				next if $file =~ /^\./; 
				#$select .= '  ' x 8 . qq~<option value="$file">$file</option>\n~ if $file; 	# ' ' x 8 = 8 spaces 
				
				# get the size of th file 
				my $size = -s "$folder_or_file/$file"; 
				my $original = $size; 
					$size /= 1024; 
					$size /= 1024;
					$size = sprintf "%.2f", $size; 
				$select .= qq~\t<option value="$file">$file [$size mb]</option>\n~ if $file; 	# ' ' x 9 #= spaces
			}
		}

$select .= qq~</select>
</div><!--end select-->
~; 
	}
	else 
	{
		# no select
		$select .= qq~~; 
	}
	 
	
	$out .= qq~<form action="$form_vars[2]" method="$form_vars[1]">~;  
	
		# add hidden fields/values # from $form_vars[4] 
		for (@hidden)
		{
			my ($name, $value) = split(/---/, $_, 2) if $_; 
			$out .= qq~<input type="hidden" name="$name" value="$value"/>\n~ if $_; 
		}
		# add select 
		$out .= qq~$select~;  
	$out .= qq~\n<button type="submit" class="btn btn-default">Submit</button>\n</form>\n\n~; 
	
	return qq~$out~; 
	
	
}

# 

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



# Begin Fri Mar 13 00:15:20 2015


# HTML 
my %HTML = (
	-defaultjquery => qq~<script type="text/javascript" src="/jquery/jquery-1.11.1.min.js"></script>
<!--bootstrap/jQueryUI-->
<script type="text/javascript" src="/jquery/bootstrap/js/bootstrap.min.js"></script>
<script type="text/javascript" src="/jquery/ui/1.11.2.lightness/jquery-ui.min.js"></script>
<!-- IE10 viewport hack for Surface/desktop Windows 8 bug -->
<script type="text/javascript" src="/jquery/bootstrap/fixed-top/ie10-viewport-bug-workaround.js"></script>
<script type="text/javascript">
// for tabs 
\$(function() {
    var tabs = \$( "#tabs" ).tabs();
    tabs.find( ".ui-tabs-nav" ).sortable({
      axis: "x",
      stop: function() {
        tabs.tabs( "refresh" );
      }
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
~,
	 
);

sub html_bootstrap_css   
{
	return qq~<!-- Bootstrap/jqueryUI -->
<link href="/jquery/bootstrap/css/bootstrap.min.css" rel="stylesheet" type="text/css">
<link href="/jquery/bootstrap/fixed-top/navbar-fixed-top.css" rel="stylesheet">
~;  
}

sub html_jqueryui_css 
{
	return qq~<link href="/jquery/ui/themes/smoothness/jquery-ui.min.css" rel="stylesheet">
<link href="/jquery/ui/themes/smoothness/theme.css" rel="stylesheet"> 
~; 
}

sub html_shim_respond 
{
	return qq~<!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
<!--[if lt IE 9]>
<script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
<script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
<![endif]-->
~;

}

sub html_navbar 
{
	#my $self = shift; 
	
	my %i;
	%i = (
		-nbmenu 	=>	"", 
		-nbpage 	=> 	"",
		-nbpage1    =>  "",
		-nbmenu1    =>  "",
		@_,		
	);
	
	return qq~<script type="text/javascript" src="/jquery/top-nav-bar.js"></script>
<!--top nav bar begin-->
<script type="text/javascript">
//<-- 
//fixed_top_navbar('$i{-nbpage1}', '', '$i{-nbmenu1}', '', '');
fixed_top_navbar('$_[0]', '', '$_[1]', '', '');
//-->
</script>
<!-- top nav bar end--> 
~; 

}


sub html_bootstrap_js  
{
	return qq~<!-- Bootstrap/jqueryUI -->
<link href="/jquery/bootstrap/css/bootstrap.min.css" rel="stylesheet" type="text/css">
<link href="/jquery/bootstrap/fixed-top/navbar-fixed-top.css" rel="stylesheet">
<link href="/jquery/ui/themes/smoothness/jquery-ui.min.css" rel="stylesheet">
<link href="/jquery/ui/themes/smoothness/theme.css" rel="stylesheet">
<!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
<!--[if lt IE 9]>
<script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
<script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
<![endif]-->
~; 

}

sub html_js_css 
{
	
}

sub html_jquery 
{
	
}

sub html_humanejs_css
{
	return qq~<link rel='stylesheet' href='/jquery/humane-js/themes/bigbox.css'>
      <link rel='stylesheet' href='/jquery/humane-js/themes/boldlight.css'>
      <link rel='stylesheet' href='/jquery/humane-js/themes/jackedup.css'>
      <link rel='stylesheet' href='/jquery/humane-js/themes/libnotify.css'>
      <link rel='stylesheet' href='/jquery/humane-js/themes/original.css'>
<link rel='stylesheet' href='/jquery/humane-js/themes/flatty.css'>
<link href='http://fonts.googleapis.com/css?family=Ubuntu&v2' rel='stylesheet' type='text/css'>
<link href='http://fonts.googleapis.com/css?family=Ubuntu+Mono' rel='stylesheet' type='text/css'>
<link href='http://fonts.googleapis.com/css?family=Cabin+Sketch:700&v2' rel='stylesheet' type='text/css'>
~; 
}

sub html_bootstrap_bluimp 
{
	return qq~<!-- The Bootstrap Image Gallery lightbox, should be a child element of the document body -->
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
	~;
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
		-title 		=> "Page Title", 
		-cssLinks => "", 
		-cssCode => "", 
		-mobilemeta => qq~<meta name="HandheldFriendly" content="true">
<meta name="viewport" content="width=device-width, initial-scale=1.0">~, 
		-charsetmeta => qq~<meta charset="utf-8">~, 
		-usermeta => "",
		@_,
		
	); 
	
	for (keys %in) 
	{
		#$out .= qq~$in{$_}\n~;  # disordered 
		
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
				$css .= qq~<link type="text/css" rel="stylesheet" href="$_">\n~ ; 
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
	$css = qq~~; 
}


	return qq~$in{-type}<!DOCTYPE html>
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
</head>
~; 	# thats orderly 

}
# end head 

sub body 
{
	my $self = shift; 
	
	my $out; 
	
	my %in; 
	
	%in = (
		-h1		=> qq~$ENV{SERVER_NAME}~,
		-onload => qq~setTitle();~,  
		-nbhead 	=> qq~~,
		-nbpage => qq~~, 
		-nbmenu => qq~~, 
		-defaultjquery => qq~$HTML{-defaultjquery}~, 
		-humanejs => qq~<script type="text/javascript" src="/jquery/js/humane-js/humane.min.js">~, 
		-userjquery => qq~~, 
		-navbar => html_navbar( $in{-nbmenu}, $in{-nbpage}, "Obselete Thu Mar 26 10:03:47 2015") , 
		-content => qq~<div class="content">Content</div>~, 
		-footer => qq~All rights reserved &copy; $ENV{SERVER_NAME}~, 	
		-bootstrapbluimp => html_bootstrap_bluimp, 	
		@_, 		
	); 
	
	return qq~<body onload="$in{-onload}">
<div id="main" class="container">
		<script type="text/javascript" src="/jquery/utils/top-nav-bar.js"></script>
<!--top nav bar begin-->
<script type="text/javascript">
//<-- 
fixed_top_navbar('$in{-nbhead}', '$in{-nbpage}', '$in{-nbmenu}', '', '');
//-->
</script>

$in{-bootstrapbluimp}

	<div class="content">$in{-content}</div>
	<div class="footer">$in{-footer}</div>
</div>

$in{-defaultjquery}

$in{-humanejs}
 
<script type="text/javascript">
//<!--
$in{-userjquery}
//--> 
</script>

</body>
	
</html>
	
~; 

}
# end body 


sub create_accordion 
{
	my $out; 
	
	my $file = "@_"; 
	
	my @data; 
	
	if ($file and -e -f $file) 
	{ 
		$out .= open_file("$file");
	} 
	else 
	{
		$out .= qq~#55 Unable to open file $file~; 
	
	}
	
	return $out; 
	
} 
# end create accordion



sub open_file 
{
	my $self =shift;
	
	# OUTPUT FORMAT OPTIONS: table, accordion, menu, as is; where "as is" is the default
	
	my $file = "$_[0]"; 			# do not use @_ for a scalar: it puts all together and the file path was wrong.  # use $_[n] # use $_ if and only if there will be just one var passed to this sub
	
	my $output_format = "$_[1]"; 	
	
	my $output_header = "$_[2]"; 
	
	my $out; 
	
	my @data; 
	
	if (open(FILE, "$file") )
	{
		#open(FILE, "$file") or $out .= qq~77 $!~; 
		
		@data = <FILE>; 
		
		$out .= qq~\n<!--begin file output-->\n<div class="file_output">\n~; 
		
		# Step 1 
		# set the header as per format  
		if ($output_format eq 'table') 
		{ 
			$out .= qq~<table class="table table-striped table-bordered table-hover table-condensed table-responsive">
				<thead>
					<tr><th colspan="2">$output_header</th></tr>
				</thead>
				<tbody>
			~; 
		}
		elsif ($output_format eq 'accordion')
		{
			$out .= qq~<h2>$output_header</h2>\n<div id="accordion2" class="accordion"><!--118-->\n~;
		} 
		elsif ($output_format eq 'menu') 
		{
			$out .= qq~<ul class="menu" id="menu">\n<li><a href="/">$output_header</a>\n<ul>~;
		}
		elsif ($output_format eq 'tabs')
		{
			# special case for tabs since the data needs to be formatted a little differently 
			
			$out .= qq~<h2>$output_header</h2>\n<div id="tabs">\n<ul>\n~;
			
			my $sl = '0'; 
			
				foreach my $line (@data) 
				{
					$sl++ if $line; 
					
					my ($h1, $div) = (''); 
					
					if ($line =~ /\|/) 		
					{ 
						($h1, $div) = split(/\|/, $line, 2); 
					} 			# no (\|) # i.e., do not enclose with brackets.  Enclosing was the culprit 
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
				
					$out .= qq~\t<li><a href="#tabs-$sl">$h1</a></li>\n~; 
				}
			$out .= qq~</ul>\n~; 
		}
		elsif ($output_format eq 'dialog')
		{
			$out .= qq~<h2>Dialog: <a href="#opener" id="opener" title="Opens the Dialog">$output_header</a></h2>
<div id="dialog">\n~; 
		}
		else 
		{
			$out .= qq~\n<h2>$output_header</h2>\n~; 
		}
		# End Step 1
		
		# now work on file 
		
		my $serial = '0'; 
		
		foreach my $line (@data) 
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
				$out .= qq~\t<tr><td>$h1</td><td>$div</td></tr>\n~; 
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
				
				$out .= qq~\t<h3>$h1</h3>\n\t<div>$div</div>\n~ if $line; 
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
					$div =~ s!^\s+http!!g;
					$h1 =~ s!^\s+http!!g;
				}
				else
				{
					next unless ($h1 =~ /^http/ or $div =~ /^http/);
					$div =~ s!^http!!g;
					$h1 =~ s!^http!!g;
				}
				$out .= qq~\t<li id="li-$serial"><a id="a-$serial" href="$div" title="$h1">$h1</a></li>\n~;
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
				
				$out .= qq~\t<div id="tabs-$serial"><p>$div</p></div>\n~; 
			}
			elsif ($output_format eq 'dialog')
			{
				# includes everything; So, no filtering.
				
				# But, just remove symbols in both $h1 and $div
				$div =~ s!^(==|\#|--)!!g;
				$h1 =~ s!^(==|\#|--)!!g;
					
				$out .= qq~<p>$h1</p>\n<p>$div</p>\n~; 
			}
			else 
			{
				$out .= qq~$h1 $div~; 	# or $line
			}
		} 
		
		# add an extra item at the end of file output
		#$out .= qq~\t<h3>Powered by Business Impact Solutions</h3>\n\t<div>bislinks.com, bizImpactSolutions.com - Business Impact Solutions</div>\n~; 
		
		# Step 3 
		# set the output ending as per format  
		if ($output_format eq 'table') 
		{ 
			$out .= qq~\n</tbody>\n</table>\n\n~; 
		}
		elsif ($output_format eq 'accordion')
		{
			$out .= qq~\n<!--end accordion--></div>\n\n~;
		} 
		elsif ($output_format eq 'menu') 
		{
			$out .= qq~</ul></ul>~;
		}
		elsif ($output_format eq 'tabs')
		{
			$out .= qq~</div><!--end tabs-->\n~; 
		}
		elsif ($output_format eq 'dialog') 
		{
			$out .= qq~</div><!--end dialog-->\n~; 
		}
		else 
		{
			$out .= qq~\n\n~; 
		}
		
		# end file output wrapper
		$out .= qq~</div><!--end file output-->\n~; 
		
		close FILE; 
		
		return $out; 
	}
	else 
	{
		my $out;
		
		@data = <DATA>; 
	
		$out .= qq~\n<!--begin accord 112-->\n<div id="accordion1460" class="accordion">\n~; 
		foreach my $line (@data) 
		{ 
			chomp $line; 
			
			my ($h1, $div) = (''); 
			
			($h1, $div) = split(/\t+/, $line, 2) if $line; 
			
			$out .= qq~\t<h3>$h1</h3>\n\t<div>$div</div>\n~ if $line; 
		} 
		$out .= qq~\t<h3>Powered by</h3>\n\t<div>Package HTML5</div>\n~; 
		
		$out .= qq~</div>\n<!--end accord-->\n~; 
		
		return $out; 
	}
	
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
			open(BAK, ">$in{file}.bak.txt") or $in{error} .= "#1570 Unable to create backup file '$in{file}.bak.txt' '$!' <br/>";
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
			
			
			if (-e -f "$in{file}.bak.txt" and -e -f "$in{file}")
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




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

A1z::HTML5::Template - turns baubles into trinkets

=head1 VERSION

version 0.07

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use A1z::HTML5::Template;

    my $foo = A1z::HTML5::Template->new();
    ...

=head1 NAME

A1z::HTML5::Template

=head1 VERSION

Version 0.07

=head1 EXPORT

A list of functions that can be exported.

=head1 SUBROUTINES/METHODS

header start_html head_title head_meta head_js_css end_head begin_body body_js_css body_topnavbar 
body_accordion end_body end_html 

=head2 new

   use A1z::HTML5::Template;
   my $foo = A1z::HTML5::Template->new();

=head2 math1

Usage

$foo->math1(num1, num2);

=head1 Times Table
	usage $foo->timestable("Number");

=head1 Usage

	my $h = Template->new();
	say $h->body_accordion( $h->open_file("C:/Users/user/public/app/open_file_example.txt", 'Type', 'Header') ); 

=head1 AUTHOR

Sudheer Murthy, C<< <pause at a1z.us> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-html5-template at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML5-Template>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc A1z::HTML5::Template

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML5-Template>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML5-Template>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/HTML5-Template>

=item * Search CPAN

L<https://metacpan.org/release/HTML5-Template>

=back

=head1 ACKNOWLEDGEMENTS

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
