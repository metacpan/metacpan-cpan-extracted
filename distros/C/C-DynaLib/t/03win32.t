# -*- perl -*-
# Win32/cygwin/mingw tests only
BEGIN {
    if ($^O !~ /(cygwin|MSWin32)/) {
	print"1..0 # skip This module does only work on Windows\n";
	exit 0;
    }
};
use Test::More tests => 8;

use C::DynaLib;
use sigtrap;

=pod

This file tests the C::DynaLib package on Windows
To run it after installation, type `perl <thisfile>'.
If successful, it will create a window with a message in the
center.

The program is modeled after the kind of "hello world" examples found
in introductory books on Windows programming in C.  However, Perl
lacks an important feature of C, namely the preprocessor (unless
someone has written a Cpp module that I don't know about?)  Therefore,
all function declarations and constants from <windows.h> are
hard-coded.

Another difficulty is the use of resources.  Windows resources are
binary data associated with an application; for example, menus,
bitmaps, and dialog box templates.  Typically, resources are linked
into the program's .exe file.  Of course, Perl programs are text and
don't use the binary format which can contain resources.  Although it
is possible to construct at run time the objects which would otherwise
be stored as resources, this is rather wasteful and complicated.

One alternative is to put the resources in a DLL or EXE which the Perl
program would then load via LoadLibrary().  A more radical solution
would be to generate a cross-breed file which has the EXE format and
is at the same time parsable by perl.  A similar principle is used by
the pl2bat utility in the Win32 Perl distribution.  However, the
"Portable Executable" format used by Win32 is quite a bit nastier on
text editors than are .bat files.  Wordpad, for instance, won't open
them at all, and Notepad leaves them hopelessly corrupt when you save.

Be that as it may, John has developed a pl2exe.pl program that does what
its name suggests.  It takes a perl script and adds some stuff at the
beginning to make it have the PE format (well, close enough to fool
Windows).  When executed, the program invokes perl on itself the way a
pl2bat script does (and avoids the 9-argument limit on Windows 95,
btw).  The thing lacking in pl2exe that would make it really useful is
a way to link in resources without disrupting the delicate PE/script
balance.

One final note about this file.  This is a demo/test program.  It is
not necessarily good coding style.

About DeclareSubA:
Previously Windows versions were consistent in their user32.dll,
gdi32.dll function names.
All names worked with the final A suffix.
Now (XP and newer) the A function is sometimes not exported anymore.

=cut

use 5.00402;

use C::DynaLib::Struct;
use strict;
use DynaLoader;

my $user32 = new C::DynaLib("USER32");
ok ($user32, "user32.dll loaded");
my $gdi32 = new C::DynaLib("GDI32");
ok ($gdi32, "gdi32.dll loaded");

if ($Convert::Binary::C::VERSION) {
  C::DynaLib::Struct::Parse(<<CCODE);

#include <windows.h>
typedef struct _WNDCLASS {
    UINT    style;
    WNDPROC lpfnWndProc;
    int     cbClsExtra;
    int     cbWndExtra;
    HANDLE  hInstance;
    HICON   hIcon;
    HCURSOR hCursor;
    HBRUSH  hbrBackground;
    LPCTSTR lpszMenuName;
    LPCTSTR lpszClassName;
} WNDCLASS;

CCODE
}

Define C::DynaLib::Struct('WNDCLASS',
	I => ['style'],
        I => ['lpfnWndProc'],
        i => ['cbClsExtra'],
        i => ['cbWndExtra'],
        I => ['hInstance'],
        I => ['hIcon'],
        I => ['hCursor'],
        I => ['hbrBackground'],
        p => ['lpszMenuName'],
        p => ['lpszClassName'],
);

sub DeclareSubA {
  my ($lib, $name, @args) = @_;
  no strict 'refs';
  if (DynaLoader::dl_find_symbol($lib->LibRef(),$name)) {
    return $lib->DeclareSub($name, @args);
  } elsif (DynaLoader::dl_find_symbol($lib->LibRef(),$name."A")) {
    $name .= "A";
    return $lib->DeclareSub($name, @args);
  } else {
    warn "$name and $name"."A not found";
  }
}

# The results of much sifting through C header files:
my $PostQuitMessage = DeclareSubA($user32,"PostQuitMessage",
	"i",   # return type
        "i");  # argument type(s)
ok ($PostQuitMessage, "PostQuitMessage declared");
my $GetClientRect = DeclareSubA($user32,"GetClientRect",
	"i",
        "i", "P");
my $BeginPaint = DeclareSubA($user32, "BeginPaint",
	"i",
        "i", "P");
my $DrawText = DeclareSubA($user32, "DrawText",
	"i",
        "I", "p", "I", "P", "I");
my $EndPaint = DeclareSubA($user32, "EndPaint",
	"i",
        "i", "P");
my $DefWindowProc = DeclareSubA($user32, "DefWindowProc",
	"i",
        "i", "i", "i", "i");
my $LoadIcon = DeclareSubA($user32, "LoadIcon",
	"i",
        "i", "i");
my $LoadCursor = DeclareSubA($user32, "LoadCursor",
	"i",
        "i", "i");
my $GetStockObject = DeclareSubA($gdi32, "GetStockObject",
	"i",
        "i");
my $RegisterClass = DeclareSubA($user32, "RegisterClass",
	"i",
        "P");
my $UnregisterClass = DeclareSubA($user32, "UnregisterClass",
	"i",
        "p", "i");
my $CreateWindowEx = DeclareSubA($user32, "CreateWindowEx",
	"i",
        "i", "p", "p", "i", "i", "i", "i", "i", "i", "i", "i", "p");
ok ($CreateWindowEx, "CreateWindowEx declared");
my $ShowWindow = DeclareSubA($user32, "ShowWindow",
	"i",
        "i", "i");
my $UpdateWindow = DeclareSubA($user32, "UpdateWindow",
	"i",
        "i");
my $GetMessage = DeclareSubA($user32, "GetMessage",
	"i",
        "P", "i", "i", "i");
my $TranslateMessage = DeclareSubA($user32, "TranslateMessage",
	"i",
        "P");
my $DispatchMessage = DeclareSubA($user32, "DispatchMessage",
	"i",
        "P");

#
# Main window's callback.
#
sub window_proc {
  my ($hwnd, $uMsg, $wParam, $lParam) = @_;

  # Wanna log your window messages?
  #print "hwnd=$hwnd, uMsg=$uMsg, wParam=$wParam, lParam=$lParam\n";

  if ($uMsg == 0x0201		# WM_LBUTTONDOWN
      || $uMsg == 0x0002	# WM_DESTROY
     ) {
    &$PostQuitMessage(0);
    return 0;
  }
  elsif ($uMsg == 0x000F) {	# WM_PAINT
    my $text = "Hello from Perl!  Please click somewhere into this window to continue...";
    # This should be big enough for a PAINTSTRUCT, I hope:
    my $ps = "\0" x 1024;
    my $rect = "\0" x 64;
    my $hdc;
    &$GetClientRect($hwnd, $rect);
    $hdc = &$BeginPaint($hwnd, $ps);
    &$DrawText($hdc, $text, length($text), $rect,
	       0x00000025);	# DT_SINGLELINE | DT_CENTER | DT_VCENTER
    &$EndPaint($hwnd, $ps);
    return 0;
  }
  return &$DefWindowProc($hwnd, $uMsg, $wParam, $lParam);
}

my $wnd_proc = new C::DynaLib::Callback
  (\&window_proc, "i", "i", "i", "i", "i");
ok ($wnd_proc, "wnd_proc Callback declared");

#
# Register the window class.
#
my $wc;
my $rwc = tie $wc, 'WNDCLASS';
ok ($wc, "tied WNDCLASS");
$rwc->style(0x0003);				# CS_HREDRAW | CS_VREDRAW
$rwc->lpfnWndProc($wnd_proc->Ptr());
$rwc->hInstance(0x00400000);
$rwc->cbClsExtra(0);
$rwc->cbWndExtra(0);

my $have_Win32 = eval { require Win32; 1; };
my ($desc, $major, $minor, $build, $id) = $have_Win32 ? Win32::GetOSVersion() : (0,0,0,0,0);
if (($major > 5) or ($major == 5 and $minor >= 1)) {
  # FIXME: XP crashes with LoadIcon. Need Wide?
  $rwc->hIcon(0);
  $rwc->hCursor(0);
  #$rwc->hbrBackground(&$GetStockObject(0));  	# WHITE_BRUSH
  $rwc->hbrBackground(0);
} else {
  $rwc->hIcon(&$LoadIcon(0, 32512));     	# IDI_APPLICATION
  $rwc->hCursor(&$LoadCursor(0, 32512));	# IDI_ARROW
  $rwc->hbrBackground(&$GetStockObject(0));  	# WHITE_BRUSH
}
$rwc->lpszMenuName(0);
$rwc->lpszClassName("w32test");
ok ($rwc->lpszClassName, "rwc->lpszClassName");

if (($major > 5) or ($major == 5 and $minor >= 1)) {
  ok 1;
  exit;
} else {
  # &$UnregisterClass( $rwc->lpszClassName, 0x00400000 );
  unless (&$RegisterClass($wc)) {
    diag "can't register window class. try again unregistering before\n";
    &$UnregisterClass( $rwc->lpszClassName, 0x00400000 );
    &$RegisterClass($wc) or die "can't register window class";
  }
}

#
# Create the window.
#
my $title_text = "Perl Does Win32";
no strict 'refs';
my $hwnd = &$CreateWindowEx(0, $rwc->lpszClassName,
			    $title_text,
			    0x00CF0000,		# WS_OVERLAPPEDWINDOW
			    0x80000000,     	# CW_USEDEFAULT
			    0x80000000, 0x80000000, 0x80000000,
			    0, 0, $rwc->hInstance,
			    0) or die "can't create window";

ok ($hwnd, "CreateWindowEx called");

&$ShowWindow($hwnd, 10);	# SW_SHOWDEFAULT
&$UpdateWindow($hwnd);

#
# Message loop.
#
my $msg = "\0" x 64;
while (&$GetMessage($msg, 0, 0, 0)) {
  &$TranslateMessage($msg);
  &$DispatchMessage($msg);
}
&$UnregisterClass( $rwc->lpszClassName, 0x00400000 );
