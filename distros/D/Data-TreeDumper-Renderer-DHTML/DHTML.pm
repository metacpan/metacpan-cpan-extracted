package Data::TreeDumper::Renderer::DHTML;

use 5.006;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '0.09';

use constant DHTML_CLASS => 'data_treedumper_dhtml' ;

my $uuuid = int(rand(100_000)) ;

my %ascii_to_html =
	(
	'<' => '&lt;',
	'>' => '&gt;',
	'&' => '&amp;',
	"'" => '&apos;',
	'"' => '&quot;',
	' ' => '&nbsp;',
	) ;

#-------------------------------------------------------------------------------------------

sub GetRenderer
{
my $expand_collapse_button_id = "expand_collapse_button_${uuuid}" ;
$uuuid++ ;

my $search_button_id = "search_button_${uuuid}" ;
$uuuid++ ;

return
	(
		{
		BEGIN => \&RenderDhtmlBegin,
		NODE  => \&RenderDhtmlNode,
		END   => \&RenderDhtmlEnd,
		
		# data needed by the renderer
		EXPAND_COLLAPSE_BUTTON_ID => $expand_collapse_button_id,
		SEARCH_BUTTON_ID          => $search_button_id,
		
		PREVIOUS_LEVEL   => -1,
		PREVIOUS_ADDRESS => "c_${uuuid}_ROOT",
		TABULATION       => 0,
		@_,
		}
	) ;
}


#-------------------------------------------------------------------------------------------

sub RenderDhtmlBegin
{
my ($title, $td_address, $element, $perl_size, $perl_address, $setup) = @_ ;

my $class = $setup->{RENDERER}{CLASS} || DHTML_CLASS ;

my $button_container = '' ;
if(exists $setup->{RENDERER}{BUTTON})
	{
	$button_container .= "<div class='tdump_button_container'>\n" ;
	
	if($setup->{RENDERER}{BUTTON}{COLLAPSE_EXPAND})
		{
		if($setup->{RENDERER}{COLLAPSED})
			{
			$button_container .= "   <input type='button' id='$setup->{RENDERER}{EXPAND_COLLAPSE_BUTTON_ID}' onclick='expand_collapse_${class}(true)' value='Expand'/>\n" ;
			}
		else
			{
			$button_container .= "   <input type='button' id='$setup->{RENDERER}{EXPAND_COLLAPSE_BUTTON_ID}' onclick='expand_collapse_${class}(true)' value='Collapse'/>\n" ;
			}
		}
		
	if($setup->{RENDERER}{BUTTON}{SEARCH})
		{
		$button_container .= "   <input type='button' id='$setup->{RENDERER}{SEARCH_BUTTON_ID}' onclick='search_${class}()' value='Search'/>\n" ;
		}
		
	$button_container .= "</div>\n\n" ;
	}

my $collapsed = '' ;
if($setup->{RENDERER}{COLLAPSED})
	{
	$collapsed = "ul.$class ul {display: none}" ;
	}

my $style = <<EOS;
<style type='text/css' >
.$class li {list-style-type:none ; margin:0 ; padding:0 ; line-height: 1em ;}

.$class ul {margin:0 ; padding:0 ;}
ul.$class {font-family:monospace ; white-space: nowrap ;}

$collapsed

</style>
EOS

if(defined $setup->{RENDERER}{STYLE})
	{
	if('SCALAR' eq ref $setup->{RENDERER}{STYLE})
		{
		${$setup->{RENDERER}{STYLE}} = $style ;
		$style = '' ;
		}
	else
		{
		$style = $setup->{RENDERER}{STYLE} ;
		}
	}
	
$style = '' if(exists $setup->{RENDERER}{NO_STYLE}) ;

$perl_size = "&lt;$perl_size&gt;" if $perl_size ne '' ;

my $address = $setup->{DISPLAY_ADDRESS} ? "<a>[$td_address] </a>" : '';

my $header = <<EOH ;
<ul class = '$class'>
   <li class='$class'>
      <a id='a_${uuuid}_ROOT' href='javascript:void(0);' onclick='toggleList_${class}(\"$setup->{RENDERER}{PREVIOUS_ADDRESS}\")'>$title</a><a> $address $perl_size $perl_address</a>
EOH

$setup->{RENDERER}{TABULATION} = 2 ;
push @{$setup->{RENDERER}{NODES}{A_IDS}}, "\"a_${uuuid}_ROOT\"";
push @{$setup->{RENDERER}{NODES}{COLLAPSABLE_IDS}}, "\"c_${uuuid}_ROOT\"" ;

$setup->{RENDERER}{PREVIOUS_ADDRESS} = "c_${uuuid}_ROOT" ;
$uuuid++ ;

return($style . $button_container . $header) ;
}

#-------------------------------------------------------------------------------------------

sub RenderDhtmlNode
{
my
	(
	$element,
	$level,
	$is_terminal,
	$previous_level_separator,
	$separator,
	$element_name,
	$element_value,
	$td_address,
	$address_link,
	$perl_size,
	$perl_address,
	$setup,
	) = @_ ;
	
# HTMLify args
my $glyph = '' ;
unless ($setup->{RENDERER}{NO_GLYPH})
	{
	$glyph = $previous_level_separator. $separator ;
	$glyph =~ s/ /&nbsp;/g ;
	}

$perl_size = "&lt;$perl_size&gt;" if $perl_size ne '' ;

if($element_value ne '')
	{
	$element_value =~ s/(<|>|&|\'|\"|\ )/$ascii_to_html{$1}/eg ;
	$element_value = " = $element_value" ;
	}

#setup
my $tabulation = $setup->{RENDERER}{TABULATION} ;
my $class = $setup->{RENDERER}{CLASS} || DHTML_CLASS ;

my $node = '' ;

# HTML list formating
if($level > $setup->{RENDERER}{PREVIOUS_LEVEL})
	{
	if($setup->{RENDERER}{COLLAPSED})
		{
		$node = '   ' x $tabulation . "<ul id='$setup->{RENDERER}{PREVIOUS_ADDRESS}' style = 'display:none'>\n" ;
		}
	else
		{
		$node = '   ' x $tabulation . "<ul id='$setup->{RENDERER}{PREVIOUS_ADDRESS}' style = 'display:block'>\n" ;
		}
		
	$tabulation++ ;
	}
else
	{
	if($level < $setup->{RENDERER}{PREVIOUS_LEVEL})
		{
		for (my $i = 0 ; $i < $setup->{RENDERER}{PREVIOUS_LEVEL} - $level ; $i++)
			{
			$tabulation-- ;
			$node .= '   ' x $tabulation . "</ul>\n" ;
			
			$tabulation-- ;
			$node .= '   ' x $tabulation . "</li>\n" ;
			}
		}
	}

# keep nodes id for search
push @{$setup->{RENDERER}{NODES}{A_IDS}}, "\"a_${uuuid}_$td_address\"" ;

if($is_terminal)
	{
	my $list_format_head = '   ' x $tabulation . "<li>" ;
	my $id               = "<a id='a_${uuuid}_$td_address' name=\"$td_address\"></a>" ;
	my $name_value       = "<a> $glyph$element_name$element_value</a>" ;
	
	my $address = '' ;
	if($setup->{DISPLAY_ADDRESS})
		{
		$address .= "<a> [$td_address</a>" ;
		
		$address .= "<a> -&gt; </a><a href=\"#$address_link\">$address_link</a>" if(defined $address_link) ;
			
		$address .= "<a> ]</a>" ;
		}
		
	my $perl_data        = "<a> $perl_size $perl_address</a>" ;
	my $list_format_foot = "</li>" ;
	
	$node .= $list_format_head . $id . $name_value . $address . $perl_data . $list_format_foot . "\n" ;
	}
else
	{
	if($setup->{RENDERER}{BUTTON}{COLLAPSE_EXPAND})
		{
		push @{$setup->{RENDERER}{NODES}{COLLAPSABLE_IDS}}, "\"c_${uuuid}_$td_address\"" ;
		}
		
	my $list_format_head = ('   ' x $tabulation) . "<li>\n" ;
	$tabulation++ ;
	
	my $alignment         = '   ' x $tabulation ;
	
	my $id_and_click_head = "<a id='a_${uuuid}_$td_address' name='$td_address' href='javascript:void(0);' onclick='toggleList_${class}(\"c_${uuuid}_$td_address\")'>" ;
	my $name_value        = "$glyph$element_name$element_value" ;
	my $id_and_click_foot = "</a>" ;
	
	my $address           = $setup->{DISPLAY_ADDRESS} ? "<a>[$td_address] </a>" : '';
	my $perl_data         = "<a> $perl_size $perl_address</a>" ;

	$node .= $list_format_head . $alignment . $id_and_click_head . $name_value . $id_and_click_foot . $address . $perl_data . "\n";
	}
	
# setup
$setup->{RENDERER}{TABULATION}       = $tabulation ;
$setup->{RENDERER}{PREVIOUS_LEVEL}   = $level ;
$setup->{RENDERER}{PREVIOUS_ADDRESS} = "c_${uuuid}_$td_address" ;
$uuuid++ ;

return($node) ;
}
	
#-------------------------------------------------------------------------------------------

sub RenderDhtmlEnd
{
my $setup = shift ;

my $closing_ul_li = '' ;
my $tabulation = $setup->{RENDERER}{TABULATION} ;

for (my $i = 0 ; $i < $setup->{RENDERER}{PREVIOUS_LEVEL} ; $i++)
	{
	$tabulation-- ;
	$closing_ul_li .= '   ' x $tabulation . "</ul>\n" ;
	
	$tabulation-- ;
	$closing_ul_li .= '   ' x $tabulation . "</li>\n" ;
	}
	
unless(exists $setup->{RENDERER}{BUTTON})
	{
	"$closing_ul_li   </ul>   </li>\n</ul>\n" ;
	}
else
	{
	my $a_ids = join "\n\t\t, ", @{$setup->{RENDERER}{NODES}{A_IDS}} ;
	my $collapsable_ids = join "\n\t\t\t\t, ", @{$setup->{RENDERER}{NODES}{COLLAPSABLE_IDS}} ;
	
	my $collapsed = 0 ;
	$collapsed++ if($setup->{RENDERER}{COLLAPSED}) ;
	
	my $class = $setup->{RENDERER}{CLASS} || DHTML_CLASS ;

<<EOS
$closing_ul_li
     </ul>
   </li>
</ul>

<script type='text/javascript'>
<!--

var a_id_array_${class}= new Array
		(
		$a_ids
		) ;

function search_${class}()
{
var string_to_search = prompt('DTD::DHTML Search','');
var regexp = new RegExp(string_to_search, 'i') ;

var i ;
for (i = 0; i < a_id_array_${class}.length; i++)
	{
	if (document.getElementById) 
		{
		document.getElementById(a_id_array_${class}[i]).style.color = '' ;
		}
	else if (document.all) 
		{
		document.all[a_id_array_${class}[0]].style.color = '' ;
		}
	else if (document.layers) 
		{
		document.layers[a_id_array_${class}[0]].style.color = '' ;
		}
	}

for (i = 0 ; i < a_id_array_${class}.length; i++)
	{
	if (document.getElementById) 
		{
		if(regexp.test(document.getElementById(a_id_array_${class}[i]).text))
			{
			show_specific_node_${class}(document.getElementById(a_id_array_${class}[i])) ;
			document.getElementById(a_id_array_${class}[i]).style.color = '#FF0000' ;
			break ;
			}
		}
	else if (document.all) 
		{
		if(regexp.test(document.all[a_id_array_${class}[0]].text))
			{
			show_specific_node_${class}(document.all[a_id_array_${class}[0]]) ;
			break ;
			}
		}
	else if (document.layers) 
		{
		if(regexp.test(document.layers[a_id_array_${class}[0]].text))
			{
			show_specific_node_${class}(document.layers[a_id_array_${class}[0]]) ;
			break ;
			}
		}
	}
}

function show_specific_node_${class} (node)
{
/* Hide all first.*/
collapsed_${class} = 0;
expand_collapse_${class}();

do
	{
	node = node.parentNode;
	
	if (node && node.tagName == 'UL')
		node.style.display = 'block';
		
	} while (node && node.parentNode);
}

var collapsable_id_array_${class} = new Array
				(
				$collapsable_ids
				) ;

var collapsed_${class} = $collapsed ;

function expand_collapse_${class}() 
{
var style ;
if(collapsed_${class}== 1)
	{
	collapsed_${class} = 0 ;
	style = "block" ;
	replace_button_text("$setup->{RENDERER}{EXPAND_COLLAPSE_BUTTON_ID}", "Collapse") ;
	}
else
	{
	collapsed_${class} = 1 ;
	style = "none" ;
	replace_button_text("$setup->{RENDERER}{EXPAND_COLLAPSE_BUTTON_ID}", " Expand ") ;
	}

var i;
for (i = 0; i < collapsable_id_array_${class}.length; i++)
	{
	if (document.getElementById) 
		{
		document.getElementById(collapsable_id_array_${class}[i]).style.display = style ;
		}
	else if (document.all) 
		{
		document.all[collapsable_id_array_${class}[i]].style.display = style ;
		}
	else if (document.layers) 
		{
		document.layers[collapsable_id_array_${class}[i]].display = style ;
		}
	}
}

function replace_button_text(buttonId, text)
{
if (document.getElementById)
	{
	var button=document.getElementById(buttonId);
	if (button)
		{
		if (button.childNodes[0])
			{
			button.childNodes[0].nodeValue=text;
			}
		else if (button.value)
			{
			button.value=text;
			}
		else //if (button.innerHTML)
			{
			button.innerHTML=text;
			}
		}
	}
}

function toggleList_${class}(tree_id) 
{
if (document.getElementById) 
	{
	var element = document.getElementById(tree_id);
	if (element) 
		{
		if (element.style.display == 'none') 
			{
			element.style.display = 'block';
			}
		else
			{
			element.style.display = 'none';
			}
		}
	}
else if (document.all) 
	{
	var element = document.all[tree_id];
	
	if (element) 
		{
		if (element.style.display == 'none') 
			{
			element.style.display = 'block';
			}
		else
			{
			element.style.display = 'none';
			}
		}
	}
else if (document.layers) 
	{
	var element = document.layers[tree_id];
	
	if (element) 
		{
		if (element.display == 'none') 
			{
			element.display = 'block';
			}
		else
			{
			element.display = 'none';
			}
		}
	}
} 

-->
</script>
EOS
	}
} 

#-------------------------------------------------------------------------------------------
1 ;

__END__

=head1 NAME

Data::TreeDumper::Renderer::DHTML - DHTML renderer for B<Data::TreeDumper>

=head1 SYNOPSIS

  use Data::TreeDumper ;
  
  #-------------------------------------------------------------------------------
  
  my $style ;
  my $body = DumpTree
  		(
		GetData(), 'Data',
  		DISPLAY_ROOT_ADDRESS => 1,
  		DISPLAY_PERL_ADDRESS => 1,
  		DISPLAY_PERL_SIZE => 1,
  		RENDERER => 
  			{
			NAME => 'DHTML',
  			STYLE => \$style,
  			BUTTON =>
  				{
				COLLAPSE_EXPAND => 1,
  				SEARCH => 1,
  				},
  			},
  		) ;
  		
  		
  print <<EOT;
  <?xml version="1.0" encoding="iso-8859-1"?>
  <!DOCTYPE html 
       PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
       "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
  >
  
  <html>
  
  <!--
  Automatically generated by Perl and Data::TreeDumper::DHTML
  -->
  
  <head>
  <title>Data</title>
  
  $style
  </head>
  <body>
  $body
  
  <p>
     <img src='http://www.w3.org/Icons/valid-xhtml10' alt='Valid HTML 4.01!' height="15" width='44' />
  </p>
  
  </body>
  </html>
  EOT

=head1 DESCRIPTION

Simple DHTML renderer for B<Data::TreeDumper>. 

Thanks to Stevan Little author of Tree::Simple::View
for giving me the idea and providing some code I could snatch.

=head1 EXAMPLE

Check B<dhtml_test.pl> for a complete example of two  structure dumps within the same HTML file.

=head1 OPTIONS

=head2 Style

CSS style is dumped to $setup->{RENDERER}{STYLE} (a ref to a scalar) if it exists. This allows you to collect
all the CSS then output it at the top of the HTML code.

  my $style ;
  my $body = DumpTree
  		(
		...
		
  		RENDERER => 
  			{
  			NAME => 'DHTML',
  			STYLE => \$style,
  			},
  		) ;
  
{RENDERER}{NO_STYLE} removes style section generation. This is usefull when you defined your styles by hand.

  my $style ;
  my $body = DumpTree
  		(
		...
		
  		RENDERER => 
  			{
			NAME => 'DHTML',
  			NO_STYLE => 1,
  			},
  		) ;

=head2 Class

The output will use class 'data_tree_dumper_dhtml' for <li> and <ul>. The class can be renamed with the help of 
{RENDERER}{CLASS}. This allows you to dump multiple data structures and display them with a diffrent styles.

  my $style ;
  my $body = DumpTree
  		(
		...
		
  		RENDERER => 
  			{
			NAME => 'DHTML',
  			CLASS => 'my_class_name',
  			},
  		) ;

=head2 Glyphs

B<Data::TreeDumper> outputs the tree lines as ASCII text by default. If {RENDERER}{NO_GLYPH} and RENDERER}{NO_STYLE}
are defined, no lines are output and the indentation will be the default <li> style. If you would like to specify a 
specific style for your tree dump, defined you own CSS and set the appropriate class through {RENDERER}{CLASS}. 

=head2 Expand/Collapse

Setting {RENDERER}{COLLAPSED} to a true value will display the tree collapsed. this is false by default.

  $setup->{RENDERER}{COLLAPSED}++ ; 

If {RENDERER}{BUTTON}{COLLAPSE_EXPAND} is set, the rendered will add a button to allow the user to collapse and expand the
tree.

  $setup->{RENDERER}{BUTTON}{COLLAPSE_EXPAND}

=head2 Search

If {RENDERER}{BUTTON}{SEARCH} is set, the rendered will add a button to allow the user to search the tree. This is 
a primitive search and has no other value than for test.

=head1 Bugs

I'll hapilly hand this module over to someone who knows what he does :-)

Check the TODO file.

=head1 EXPORT

None

=head1 AUTHORS

Khemir Nadim ibn Hamouda. <nadim@khemir.net>

Staffan Maahlén.

  Copyright (c) 2003 Nadim Ibn Hamouda el Khemir and 
  Staffan Maahlén. All rights reserved.
  
  This program is free software; you can redistribute
  it and/or modify it under the same terms as Perlitself.
  
If you find any value in this module, mail me!  All hints, tips, flames and wishes
are welcome at <nadim@khemir.net>.

=head1 SEE ALSO

B<Data::TreeDumper>.

=cut

