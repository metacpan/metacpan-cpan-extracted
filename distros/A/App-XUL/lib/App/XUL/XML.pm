package App::XUL::XML;

use App::XUL::Object;
use Time::HiRes qw(time);

our $AUTOLOAD;

# this is 1 if the module is loaded from within a running server!
our $RunInsideServer = 0;

# regular expression that matches a HTML5 tagname
my $HTMLTagRegex = 
	'^('.
		join('|',
 			qw(a abbr acronym address applet area article aside audio
				 b base basefont bdo big blockquote body br button
				 canvas caption center cite code col colgroup command
				 datalist dd del details dfn dir div dl dt
				 em embed fieldset figcaption figure font footer form frame frameset
				 h1 h2 h3 h4 h5 h6 head header hgroup hr html
				 i iframe img input ins 
				 keygen kbd 
				 label legend li link
				 map mark menu meta meter
				 nav noframes noscript
				 object ol optgroup option output
				 p param pre progress
				 q
				 rp rt ruby
				 s samp script section select small source span strike strong style 
				   sub summary sup
				 table tbody td textarea tfoot th thead time title tr tt
				 u ul
				 var
				 video
				 wbr
				 xmp)).')$';

my $XULTagRegex = 
	'^('.
		join('|',
 			qw(action arrowscrollbox
 			   bbox binding bindings box broadcaster broadcasterset button browser
 			   caption checkbox colorpicker column columns command commandset conditions content
 			   deck description dialog dialogheader
 			   editor
 			   grid grippy groupbox
 			   hbox
 			   iframe image
 			   key keyset
 			   label listbox listcell listcol listcols listhead listheader listitem
 			   member menu menubar menuitem menulist menupopup menuseparator
 			   observes overlay
 			   page popup popupset preference preferences prefpane prefwindow progressmeter
 			   radio radiogroup resizer richlistbox richlistitem row rows rule
 			   script scrollbar scrollbox scrollcorner separator spacer splitter stack 
 			     statusbar statusbarpanel stringbundle stringbundleset
 			   tab tabbrowser tabbox tabpanels tabs template textnode textbox titlebar 
 			     toolbar toolbarbutton toolbaritem toolbarpalette toolbarseparator 
 			     toolbarset toolbarspacer toolbarspring toolbox tooltip tree
 			     treecell treechildren treecol treecols treeitem treerow treeseparator triple
 			   vbox
 			   window wizard wizardpage)).')$';

# function for XML creation, 
# e.g. Window('attr1'='val1', 'attr2'='val2', 'content...');
sub AUTOLOAD
{
	my (@rest) = @_;
	
	return if $AUTOLOAD =~ /::DESTROY$/;
	
	my $tagname = $AUTOLOAD;
	$tagname =~ s/.*://;
	#print "($tagname)\n";	
	
	if ($RunInsideServer && $tagname eq 'ID') {
		my ($id) = @rest;
		return App::XUL::Object->new($id);
	}
	elsif ($tagname =~ /$HTMLTagRegex/i || $tagname =~ /$XULTagRegex/i) {	
		$tagname = lcfirst $tagname;
		$tagname = 'html:'.$tagname 
			if $tagname =~ /$HTMLTagRegex/i && $tagname !~ /$XULTagRegex/i;
		
		my %attribs = ();
		my $content = '';
		foreach (my $i = 0; $i < scalar @rest; $i++) {
			my $attrname = $rest[$i];
			if ($attrname =~ /^[a-zA-Z0-9\:]+$/ && $i < scalar @rest -1) {	
				my $attrvalue = $rest[$i+1];
				$attribs{$attrname} = $attrvalue;
				$i++;
			} else {
				$content .= $attrname;
			}
		}

		# autogenerate ID if not provided
		unless (exists $attribs{'id'}) {
			$attribs{'id'} = 'e'.time();
			$attribs{'id'} =~	s/[^\w\d]//g;
		}

		if ($tagname eq 'button' && ref $attribs{'oncommand'} eq 'CODE') {
			# add eventhandler to App::XUL bindings
			if ($RunInsideServer) {
				main::bind($attribs{'id'}, 'click', $attribs{'oncommand'});
			} else {
				App::XUL::bind($attribs{'id'}, 'click', $attribs{'oncommand'});
			}
			$attribs{'oncommand'} = "AppXUL.send('click','".$attribs{'id'}."');";
		}
		if ($tagname eq 'window') {
			$attribs{'title'}  = $App::XUL::Singleton->{'name'} unless exists $attribs{'title'};
			$attribs{'width'}  = '800' unless exists $attribs{'width'};
			$attribs{'height'} = '200' unless exists $attribs{'height'};
			
			$attribs{'xmlns'}      = 'http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul';
			$attribs{'xmlns:html'} = 'http://www.w3.org/1999/xhtml';
			
			$attribs{'onclose'} = "quit(); return false;";
			
			$content = '<script src="AppXUL.js"/>'.$content;
		}
		
		# create and return XML string
		return 
			'<'.$tagname.
				(scalar keys %attribs ?
					' '.join(' ', map { $_.'="'.$attribs{$_}.'"' } keys %attribs) : 
					'').
				(length $content ? 
					'>'.$content.'</'.$tagname : 
					'/').
			'>';
	}
}

1;
