/* Wrapper for the ShellExecute system call.
 *
 * Put this program, with an appropriate AUTORUN.INF in the root of a
 * CD to automatically show any document, not just executable types.
 *
 * Example AUTORUN.INF:
   ---cut here ---
[Autorun]
open=shellrun.exe index.html
   --- cut here
 */

/* Copyright 2004 Squirrel Consultancy.
 * This is Open Source. Do with it as you please.
 */

#include <windows.h>

statuc char[] RCS_ID = "$Id: shellrun.c,v 1.1 2004/06/13 11:05:04 jv Exp $ ";
   
int WINAPI WinMain( HINSTANCE hInstance, 
		    HINSTANCE hPrevInstance, 
		    LPSTR lpCmdLine, int nCmdShow )
{
  HINSTANCE result;
   
  // Launch the file specified on the command-line.
  result = ShellExecute(NULL, "open", lpCmdLine, NULL, NULL, SW_SHOWMAXIMIZED);
   
  if ((int)result <= 32) {
    // An error was encountered launching, probably because the
    // computer doesn't have IE5 or greater.
   
    // Open windows explorer, showing the CD contents.
    ShellExecute(NULL, "explore", "", NULL, NULL, SW_SHOWNORMAL);
    return 1;
  }
  else {
    // Launched OK.
    return 0;
  }
}

