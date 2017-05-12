package App::XUL;

use 5.010000;
use strict;
use warnings;
use Directory::Scratch::Structured qw(create_structured_tree);
use File::Copy::Recursive qw(fcopy dircopy);
#use Data::Dumper;
use Data::Dumper::Concise;
use App::XUL::XML;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(AUTOLOAD);

our $VERSION = '0.07';
our $AUTOLOAD;

our $Singleton;

################################################################################

sub AUTOLOAD
{
	#print "auto1\n";
	$App::XUL::XML::AUTOLOAD = $AUTOLOAD;
	return App::XUL::XML::AUTOLOAD(@_);
}

################################################################################

sub new
{
  my ($class, @args) = @_;
  my $self = bless {}, $class;
  $Singleton = $self;
  return $self->init(@args);
}

sub init
{
  my ($self, %opts) = @_;
  $self->{'name'} = $opts{'name'} || do { die "Error: no app name given - new(name => <string>)\n" };
	$self->{'windows'} = [];
	$self->{'bindings'} = {};
  return $self
}

sub bind
{
	my ($id, $event, $coderef) = @_;
	$Singleton->{'bindings'}->{$id.':'.$event} = $coderef;
	return $Singleton;
}

sub add
{
	my ($self, $window_xml) = @_;
	die "Error: add() only accepts a single window tag as first argument\n"
		if $window_xml !~ /^<window/;
	push @{$self->{'windows'}}, $window_xml;
	return $self;
}

sub bundle
{
  my ($self, %opts) = @_;
  
  my $os = $opts{'os'} || die "Error: no os given - bundle(os => <string>)\n";
  my $path = $opts{'path'} || die "Error: no path given - bundle(path => <string>)\n";
  my $utilspath = $opts{'utilspath'} || die "Error: no utils path given - bundle(utilspath => <string>)\n";
  $self->{'debug'} = $opts{'debug'} || 0;
  
	#print Dumper($self);
	#exit;
	
	##############################################################################
	if ($os eq 'chrome') {
	
		my $name = $self->{'name'};
	
  	my $tmpdir = create_structured_tree(
			$name => {
				'start_macosx.pl' => [$self->_get_file_startpl('chrome','macosx')],
				'start_win.pl' => [$self->_get_file_startpl('chrome','win')],
				'start_linux.pl' => [$self->_get_file_startpl('chrome','linux')],
				'chrome.manifest' => ['manifest chrome/chrome.manifest'."\n"],
				'application.ini' => [$self->_get_file_macosx_appini()],
				#'MyApp.icns' => [],
				'chrome' => {
					# for older XUL.framework's we need the chrome.manifest here!
					'chrome.manifest' => [$self->_get_file_macosx_chromemanifest()],
					'content' => {
						#'AppXUL.js' => [],
						#'AppXULServer.js' => [],
						$self->_get_file_macosx_xulfiles(),
						#'main.xul' => [$self->_get_file_macosx_mainxul()],
					},
				},
				'defaults' => {
					'preferences' => {
						'prefs.js' => [$self->_get_file_macosx_prefs()],
					},
				},
				'perl' => {
					'server' => {
						#'server.pl' => [$self->_get_file_macosx_serverpl()],
					},
					'modules' => {
						'Eventhandlers.pm' => [$self->_get_file_macosx_eventhandlers()],
						'App' => {
							'XUL' => {
								#'XML' => [],
								#'Object' => [],
							},
						},
					},
				},
				'extensions' => {},
				'updates' => {
					'0' => {},
				},
			}
		);
		
		# copy misc files into tmpdir

		fcopy($utilspath.'/AppXUL.js', 
			$tmpdir->base().'/'.$name.'/chrome/content/AppXUL.js');

		fcopy($utilspath.'/server.pl', 
			$tmpdir->base().'/'.$name.'/perl/server/server.pl');

		fcopy($utilspath.'/../lib/App/XUL/XML.pm',
			$tmpdir->base().'/'.$name.'/perl/modules/App/XUL/XML.pm');

		fcopy($utilspath.'/../lib/App/XUL/Object.pm', 
			$tmpdir->base().'/'.$name.'/perl/modules/App/XUL/Object.pm');

		# chmod certain files
		chmod(0755, $tmpdir->base().'/'.$name.'/start_macosx.pl');
		chmod(0755, $tmpdir->base().'/'.$name.'/start_win.pl');
		chmod(0755, $tmpdir->base().'/'.$name.'/start_linux.pl');

		# move tmpdir to final destination		
		rename($tmpdir->base().'/'.$name, $path);
		
	}
	##############################################################################
	elsif ($os eq 'macosx') {

		my $name = $self->{'name'};

  	my $tmpdir = create_structured_tree(
			$name.'.app' => {
				'Contents' => {
					'Info.plist' => [$self->_get_file_maxosx_infoplist()],
					'Frameworks' => {
						#'XUL.framework' => {},
					},
					'MacOS' => {
						'start.pl' => [$self->_get_file_startpl('macosx')],
					},
					'Resources' => {
						'chrome.manifest' => ['manifest chrome/chrome.manifest'."\n"],
						'application.ini' => [$self->_get_file_macosx_appini()],
						#'MyApp.icns' => [],
						'chrome' => {
							# for older XUL.framework's we need the chrome.manifest here!
							'chrome.manifest' => [$self->_get_file_macosx_chromemanifest()],
						  'content' => {
							  #'AppXUL.js' => [],
							  #'AppXULServer.js' => [],
							  $self->_get_file_macosx_xulfiles(),
							  #'main.xul' => [$self->_get_file_macosx_mainxul()],
							},
						},
						'defaults' => {
							'preferences' => {
								'prefs.js' => [$self->_get_file_macosx_prefs()],
							},
						},
						'perl' => {
							'server' => {
								#'server.pl' => [$self->_get_file_macosx_serverpl()],
							},
							'modules' => {
								'Eventhandlers.pm' => [$self->_get_file_macosx_eventhandlers()],
								'App' => {
									'XUL' => {
										#'XML' => [],
										#'Object' => [],
									},
								},
							},
						},
						'extensions' => {},
						'updates' => {
							'0' => {},
						},
					},
				}
			}
		);
		
		# copy misc files into tmpdir
		die "Error: no XUL.framework found in /Library/Frameworks - please install XUL framework from mozilla.org\n"
			unless -d '/Library/Frameworks/XUL.framework';
		dircopy('/Library/Frameworks/XUL.framework', 
			$tmpdir->base().'/'.$name.'.app/Contents/Frameworks/XUL.framework');
			
		fcopy($utilspath.'/Appicon.icns',
			$tmpdir->base().'/'.$name.'.app/Contents/Resources/'.$name.'.icns');

		fcopy($utilspath.'/AppXUL.js', 
			$tmpdir->base().'/'.$name.'.app/Contents/Resources/chrome/content/AppXUL.js');

		#fcopy('../../misc/AppXULServer.js', 
		#	$tmpdir->base().'/'.$name.'.app/Contents/Resources/chrome/content/AppXULServer.js');

		fcopy($utilspath.'/server.pl', 
			$tmpdir->base().'/'.$name.'.app/Contents/Resources/perl/server/server.pl');

		fcopy($utilspath.'/../lib/App/XUL/XML.pm',
			$tmpdir->base().'/'.$name.'.app/Contents/Resources/perl/modules/App/XUL/XML.pm');

		fcopy($utilspath.'/../lib/App/XUL/Object.pm', 
			$tmpdir->base().'/'.$name.'.app/Contents/Resources/perl/modules/App/XUL/Object.pm');

		# chmod certain files
		chmod(0755, $tmpdir->base().'/'.$name.'.app/Contents/MacOS/start.pl');

		# move tmpdir to final destination		
		rename($tmpdir->base().'/'.$name.'.app', $path);
	}
	else {
		die "Error: os '$os' not implemented yet\n";
	}
}

################################################################################

sub _get_file_macosx_eventhandlers
{
	my ($self) = @_;
	my $eventhandlers = '';
	foreach my $name (keys %{$self->{'bindings'}}) {
		$eventhandlers .= "'".$name."' => \n".Dumper($self->{'bindings'}->{$name}).",\n";
	}
	return
		'package Eventhandlers;'."\n".
		'use App::XUL::XML;'."\n".
		'$App::XUL::XML::RunInsideServer = 1;'."\n".
		'our $AUTOLOAD;'."\n".
		'sub AUTOLOAD {'."\n".
		'	$App::XUL::XML::AUTOLOAD = $AUTOLOAD;'."\n".
		'	return App::XUL::XML::AUTOLOAD(@_);'."\n".
		'}'."\n".
		'sub get {'."\n".
		'	return {'."\n".
				$eventhandlers.		
		'	};'."\n".
		'}'."\n".
		'1;'."\n";
}

sub _get_file_macosx_prefs
{
	my ($self) = @_;
	return <<EOFSRC
pref("toolkit.defaultChromeURI", "chrome://$self->{'name'}/content/main.xul");

/* debugging prefs */
pref("browser.dom.window.dump.enabled", true);
pref("javascript.options.showInConsole", true);
pref("javascript.options.strict", true);
pref("nglayout.debug.disable_xul_cache", true);
pref("nglayout.debug.disable_xul_fastload", true);
EOFSRC
}

sub _get_file_macosx_xulfiles
{
	my ($self) = @_;
	my @files = ();
	my $w = 0;
	foreach my $window_xml (@{$self->{'windows'}}) {
		my $xml = 
			'<?xml version="1.0"?>'."\n".
			'<?xml-stylesheet href="chrome://global/skin/" type="text/css"?>'."\n".
			$window_xml;
		push @files, ($w == 0 ? 'main' : 'sub'.$w).'.xul', [$xml];
		$w++;
	}
	return @files;
#	return
#		'<?xml version="1.0"?>'."\n".
#		'<?xml-stylesheet href="chrome://global/skin/" type="text/css"?>'."\n".
#		$self->{'xml'};
#<window id="mw" title="$self->{'name'}" width="800" height="200"
#     xmlns="http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul"
#     xmlns:html="http://www.w3.org/1999/xhtml">
#  <script src="AppXUL.js"/>
#  ...
#</window>
}

sub _get_file_macosx_chromemanifest
{
	my ($self) = @_;
	return 'content '.$self->{'name'}.' file:content/'."\n";
}

sub _get_file_macosx_appini
{
	my ($self) = @_;
	return <<EOFSRC
[App]
Version=1.0
Vendor=Me
Name=$self->{'name'}
BuildID=myid
ID={generated id}

[Gecko]
MinVersion=1.8
MaxVersion=2.*
EOFSRC
}

sub _get_file_startpl
{
	my ($self, $os, $type) = @_;
	
	if ($os eq 'chrome') {
		my $xulrunnerpath = {
			macosx => '/Library/Frameworks/XUL.framework/xulrunner-bin',
			win    => 'c:\Program Files\xulrunner\xulrunner',
			linux  => 'xulrunner',
		};
		return
			'#!/usr/bin/perl -w'."\n".
			q{use strict;
			use Cwd 'abs_path';
			my $path = abs_path($0);
				 $path =~ s/\/start\_[a-z]+.pl$//;
			system(
				'"'.$path."/perl/server/server.pl".'" '.
				'"'.$path."/perl/modules/".'" 3000 &'
			);
			exec(
				"}.$xulrunnerpath->{$type}.q{", 
				"-app", $path."/application.ini",}.
				($self->{'debug'} ? '"-jsconsole"' : '').
			');'."\n";
	}
	elsif ($os eq 'macosx') {
		return 
			'#!/usr/bin/perl -w'."\n".
			q{use strict;
			use Cwd 'abs_path';		
			my $path = abs_path($0);
				 $path =~ s/\/MacOS\/[^\/]+//;
			system(
				'"'.$path."/Resources/perl/server/server.pl".'" '.
				'"'.$path."/Resources/perl/modules/".'" 3000 &'
			);
			exec(
				$path."/Frameworks/XUL.framework/xulrunner-bin", 
				"-app", $path."/Resources/application.ini",}.
				($self->{'debug'} ? '"-jsconsole"' : '').
			');'."\n";
	}
	else {
		return '';
	}
}

sub _get_file_maxosx_infoplist
{
	my ($self) = @_;
	return <<EOFSRC
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>English</string>
	<key>CFBundleExecutable</key>
	<string>start.pl</string>
	<key>CFBundleGetInfoString</key>
	<string>XULExplorer 1.0a1pre, © 2007-2008 Contributors</string>
	<key>CFBundleIconFile</key>
	<string>$self->{'name'}</string>
	<key>CFBundleIdentifier</key>
	<string>org.mozilla.mccoy</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$self->{'name'}</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0a1pre</string>
	<key>CFBundleSignature</key>
	<string>MOZB</string>
	<key>CFBundleVersion</key>
	<string>1.0a1pre</string>
	<key>NSAppleScriptEnabled</key>
	<true/>
</dict>
</plist>
EOFSRC
}

1;
__END__

=head1 NAME

App::XUL - Perl extension for creating deployable platform-independent
standalone desktop applications based on XUL and XULRunner.

=for html <span style="color:red">WARNING: PRE-ALPHA - DON'T USE FOR PRODUCTION!</span>

=head1 SYNOPSIS

  use App::XUL;
  my $app = App::XUL->new(name => 'MyApp');
  
  $app->add(
    Window(id => 'main',
      Div(id => 'container', 'style' => 'background:black', 
        Button(label => 'click', oncommand => sub {
          ID('container')->style('background:red');
        }),
      ),
    ),
  );
  
  $app->bundle(path => '/path/to/myapp.app', os => 'macosx');  

XUL (+ XULRunner) makes it easy to create applications based
on XML, CSS and JavaScript. App::XUL tries to simplify this
even more by exchanging XML and JavaScript with Perl and
providing an easy way to create deployable applications for the
platforms XULRunner exists for.

=head1 WHY XUL/XULRUNNER

XUL provides a set of powerful user widgets that look good
and work as expected. They can be created with minimal effort
and their appearance can be manipulated using CSS.

XUL is based on B<web technologies like XML, CSS and JavaScript>.
So anyone who is able to use these is able to create cool
desktop applications.

Here is the homepage of the L<XUL|https://developer.mozilla.org/En/XUL>
and L<XULRunner|https://developer.mozilla.org/en/xulrunner> projects at Mozilla.

=head1 DESCRIPTION

=head2 new() - Creating an application

The constructor new() is used to create a new application

  my $app = App::XUL->new(name => 'MyApp');

=head3 Options

=head4 name => I<string>

The name of the application. Later also used as the application executable's name.

=head2 add() - Add a window to an application
 
add() adds a window to the XUL application. The XML for the window tag
and its contained tags is created using Perl functions. The names of
the Perl functions used to create the XML tags corresponds to the
tagnames, just the first letter is uppercase:
 
  $app->add(
    Window(id => 'main',
      Div(id => 'container', 'style' => 'background:black', 
        Button(label => 'click', oncommand => sub {
          ID('container')->style('background:red');
        }),
      );
    )
  );

Keep in mind, that add will fail if the added tag is NOT a window tag.
In XUL the root is always a window tag.

The first window beeing added is considered the main window and shown
on startup.

=head2 bundle() - Creating a deployable executable

  $app->bundle(path => '/path/to/myapp.app', os => 'macosx');  

This will create a complete standalone XUL application containing all XML code.

Some general information about
L<XUL application deployment|https://wiki.mozilla.org/XUL:XUL_Application_Packaging>.

=head3 Options

=head4 path => I<string>

=head4 os => I<string>

The systems currently supported are:

=over 1

=item chrome (native Chrome application)

This creates the usual directory for a XULRunner based application containing
all needed files, except the XULRunner executable itself. A start Perl
script for various operation systems is created as well, e.g. you can start
the application by executing the start_macosx.pl file for Mac OS X.

Note for Linux users: You have to add the directory containing the
xulrunner (or xulrunner-bin) executable to your $PATH variable or
adjust the start_linux.pl script accordingly. This is due to the fact
that XULRunner for Linux us currently in beta phase and can only
be used by unpacking it into a local directory.

=item macosx (Mac OS X)

L<Apple Documentation|http://developer.apple.com/library/mac/#documentation/CoreFoundation/Conceptual/CFBundles/BundleTypes/BundleTypes.html#//apple_ref/doc/uid/10000123i-CH101-SW1>

=item win (Windows)

coming soon

=item deb or rpm (Ubuntu Linux)

tbd. Either a *.deb or *.rpm Paket.

=back

=head4 debug => I<1/0>

If debug is set to 1, a jsconsole is started together with the application
which can be used to debugging messages. The default is debug = 0, so no
jsconsole is started.

=head2 Creating interface components

=head2 Handling events

Events can be handled by attaching an event handler to
an interface component. Event handlers can either be written
in Perl or in JavaScript.

Here is an example of a Perl event handler that reacts on
the mouse click of a button:

  Button(label => 'click', oncommand => sub {
    # access environment and evtl. change it
    # ...
  });

Here is a similar JavaScript event handler:

  Button(id => 'btn', label => 'click', oncommand => <<EOFJS);
    // here is some js code
    $('btn').update('Alrighty!');
  EOFJS

JavaScript event handlers are executed faster than the Perl ones,
due to the architecture (see below).


=head2 Changing the environment from Perl

This refers to all activities within Perl event handlers that
change the DOM of the XUL application. An example is the
addition of another window, the insertion or update of a button
label or the deletion of a style attribute etc.

Some things are important here:

=over 1

=item Changes happen on the server side first and are
  transferred to the client side (the XUL application)
  when the event handler terminates.

=item To manually transfer the latest changes to the client side
  use the PUSH() function.

=back

=head4 Get (XML) element

The first step of changing the DOM is to get an element on which
the changes are applied. The ID() function is used for that:

  my $elem = ID('main');

The ID() function only works WHILE the application is running.
Any changes to the object returned by the ID() function are transferred
immedietly (asynchronous) to the XUL application/client.

=head4 Get child (XML) elements

  my $child1 = ID('main')->child(0);
  my $numchildren = ID('main')->numchildren();

=head4 Create/insert/append (XML) elements

  my $e = Div(id => 'container', 'style' => 'background:black', 
            Button(label => 'click'));
  ID('main')->insert($e, 'end'); # end|start|...

=head4 Edit (XML) element

  ID('container')->style('background:red')->content(Span('Hello!'));

=head4 Delete/remove (XML) element

  my $e = ID('container')->remove();

=head4 Call event handler on (XML) element

  ID('container')->click();

=head4 Register event handler on (XML) element

  ID('container')->oncommand(sub {
    # do stuff here
    # ...
  });

=head4 Un-register event handler on (XML) element

  ID('container')->oncommand(undef);
            

=head2 EXPORT

None by default.

=head1 INTERNALS

This chapter is meant for informational purposes. Sometimes it is nessessary
to know how things are implemented to decide, for example, if you should
use a Perl or a JavaScript event handler etc.

App::XUL is client-server based. The client is the instance of
XULRunner running and the server is a pure Perl based webserver
that reacts on the events that are triggered by the XUL interface.

=head3 Event handling

Essentially all events are dispatched from XUL as Ajax calls to the
Perl webserver which handles the event, makes changes to the DOM etc.
The changes are then transferred back to the XUL app where they
are applied.

Here is a rough workflow for event handling:

=over 1

=item 1. Client registers an event (e.g. "mouseover", "click", "idle" etc.)

=item 2. Client sends message to server (incl. parameters and environment)

=item 3. Server calls appropriate Perl event handler subroutine
  (which may manipulate the environment)

=item 4. Server sends the environment changes to the client as response

=item 5. Client integrates environment changes

=back    

=head3 Communication protocol

The communication between XUL and server is based on a simple
JSON based protocol. The following syntax definition tries to
define the protocol. Everything in curly brackets is a JSON object,
strings are quoted and non-terminals are written within "<",">" brackets.
The pipe symbol ("|") means "OR".

  <CLIENT-REQUEST> := <EVENT>
  
  <SERVER-RESPONSE> := <ACTION>

  <SERVER-REQUEST> := <ACTION>

  <CLIENT-RESPONSE> := <STRING>
  
  <EVENT> := {
    event: <EVENTNAME>,
    id: <ID>
  }

    <EVENTNAME> := 
      "abort" |
      "blur" |
      "change" |
      "click" |
      "dblclick" |
      "dragdrop" |
      "error" |
      "focus" |
      "keydown" |
      "keypress" |
      "keyup" |
      "load" |
      "mousedown" |
      "mousemove" |
      "mouseout" |
      "mouseover" |
      "mouseup" |
      "move" |
      "reset" |
      "resize" |
      "select" |
      "submit" |
      "unload"

  <ACTION> := 
    <UPDATE> | 
    <REMOVE> | 
    <CREATE> | 
    <QUIT> |
    <CHILD> | 
    <NUMCHILDREN> |
    <INSERT> |
    <TRIGGER> |
    <REGISTER> |
    <UNREGISTER> |
    <SETATTR> |
    <GETATTR>
    
    <UPDATE> := {
      action: "update",
      id: <ID>,
      attributes: <ATTRIBUTES>,
      subactions: [ <ACTION>, ... ]
    }

      <ATTRIBUTES> := {<NAME>: <STRING>, ...}
  
    <REMOVE> := {
      action: "remove",
      id: <ID>,
      subactions: [ <ACTION>, ... ]
    }

    <CREATE> := {
      action: "create",
      parent: <ID>,
      attributes: <ATTRIBUTES>,
      content: <STRING>,
      subactions: [ <ACTION>, ... ]
    }
    
    <QUIT> := {
      action: "quit"
    }

    <CHILD> := {
      action: "child",
      id: <ID>,
      number: <NUMBER>
    }
    
    <NUMCHILDREN> := {
      action: "numchildren",
      id: <ID>
    }
    
    <INSERT> := {
      action: "insert",
      id: <ID>,
      position: <POSITION>,
      content: <STRING>
    }
    
    <TRIGGER> := {
      action: "trigger",
      id: <ID>,
      name: <STRING>
    }
    
    <REGISTER> := {
      action: "register",
      id: <ID>,
      name: <STRING>,
      callback: <STRING>
    }
    
    <UNREGISTER> := {
      action: "unregister",
      id: <ID>,
      name: <STRING>
    }
    
    <SETATTR> := {
      action: "setattr",
      id: <ID>,
      name: <STRING>,
      value: <STRING>
    }
    
    <GETATTR> := {
      action: "getattr",
      id: <ID>,
      name: <STRING>
    }

Here are some examples of client requests:

  {event:"click", id:"btn"}

Here are some examples of server responses:

  {action:"update", id:"btn", attributes:{label:"Alrighty!"}}

  {action:"remove", id:"btn"}

  {action:"create", parent:"main", content:"<button .../>"}

=head3 Application bundling for Mac OS X

Mac applications are simply directories whose names end with ".app"
and have a certain structure and demand certain files to exist.

This is the structure of a XUL application wrapped inside a Mac application
as created by App::XUL (files are blue, directories are black):

=begin html

<pre>
  MyApp.app/
    Contents/
      <span style="color:blue;font-weight:bold">Info.plist</span>
      Frameworks/
        XUL.framework/
          <i>The XUL Mac framework</i>
      MacOS
        <span style="color:blue;font-weight:bold">start.pl</span> (Perl-Script)
      Resources
        <span style="color:blue;font-weight:bold">application.ini</span>
        <span style="color:blue;font-weight:bold">MyApp.icns</span>
        chrome/
          <span style="color:blue;font-weight:bold">chrome.manifest</span>
          content/
            <span style="color:blue;font-weight:bold">AppXUL.js</span>
            <span style="color:blue;font-weight:bold">myapp.xul</span>
        defaults/
          preferences/
            <span style="color:blue;font-weight:bold">prefs.js</span>
        perl/
          server/
            <span style="color:blue;font-weight:bold">server.pl</span>
          modules/
            <i>All Perl modules the server depends on</i>
        extensions/
        updates/
          0/
</pre>

=end html

The various files have specific functions. When the MyApp.app is
clicked, the B<start.pl> program is executed which then starts the
server and the client:

=over 1

=item Info.plist

Required by Mac OS X. This is the place where certain basic information
about the application is read by Mac OS X, before anything else is done.
For example, here the start.pl program is defined as the entry point
of the application.

=item start.pl

First program to be executed. Starts server and client.

=item application.ini

Setups the XUL application. Defines which *.xul files to load,
name of application etc.

=item AppXUL.js

Defines all Javascript functions used by App::XUL to manage the
communication with the server.

=item myapp.xul

Defines the basic UI for the XUL application.

=item prefs.js

Sets some preferences for the XUL application.

=item server.pl

This starts the server.

=back

=head3 Application bundling for Windows

tbd. Use L<NSIS|http://nsis.sourceforge.net/Main_Page> or
L<InstallJammer|http://www.installjammer.com/>.

=head3 Application bundling as DEB package

tbd. See L<Link|http://www.webupd8.org/2010/01/how-to-create-deb-package-ubuntu-debian.html>.

=head3 Application bundling as RPM package

tbd.

=head1 ROADMAP

One thing on the todo list is to create a full-duplex connection
between client and server so that the client can react on
server events directly. This may be implemented using the HTML5
WebSocket protocol. For now all communication is iniciated from
the client using AJAX calls.

=head1 SEE ALSO

This module actually stands a bit on its own with its approach.
XUL modules exist though - XUL::Gui, XUL::Node and a few more.

=head1 AUTHOR

Tom Kirchner, E<lt>tom@tomkirchner.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Tom Kirchner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
