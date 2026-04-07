# BBS::Universal SysOp Menus

![BBS::Universal Logo](../files/BBS/BBS_Universal.png?raw=true "BBS::Universal")

# Creating Custom Menu Files

The files in ```files/sysop/``` are specifically for the local SysOp mode.  ALL are in ANSI format and thus will always have the ```ANSI``` suffix.  They are similar to the user menus, but the formatting is slightly different.

## Format

Custom menus follow a specific format

* Menu descriptors (KEY|COMMAND|COLOR|DESCRIPTION)
* Divider "---"
* Text header

### Menu Descriptors

* **KEY**          - A single key used to activate the feature.  It is case insensitive.
* **COMMAND**      - The specific command token to activate the feature.  Use only the token name
* **COLOR**        - The color of the menu choice.
* **DESCRIPTION**  - The text to be displayed after the menu option

Note: All menu keys will be sorted on output

### Divider

The divider MUST be "---" on a line by itself.  This signals to the menu processor the end of the menu descriptors.

### Text Header

This is the actual menu text shown above the actual menu options when parsed and shown.  The text can have embedded tokens appropriate to the text mode the file is created for.

## Sample

```
[% CLS %][% BRIGHT CYAN %][% BLACK UPPER RIGHT TRIANGLE %][% B_BRIGHT CYAN %] [% RESET %][% BRIGHT CYAN %][% INVERT %][% BLACK UPPER RIGHT TRIANGLE %][% RESET %]  [% BRIGHT WHITE %] ____            _                   __  __[% RESET %]
[% BRIGHT RED     %] [% BLACK UPPER RIGHT TRIANGLE %][% B_BRIGHT RED     %] [% RESET %][% BRIGHT RED     %][% INVERT %][% BLACK UPPER RIGHT TRIANGLE %][% RESET %] [% BRIGHT WHITE %]/ ___| _   _ ___| |_ ___ _ __ ___   |  \/  | ___ _ __  _   _[% RESET %]
[% BRIGHT YELLOW  %]  [% BLACK UPPER RIGHT TRIANGLE %][% B_BRIGHT YELLOW  %] [% RESET %][% BRIGHT YELLOW  %][% INVERT %][% BLACK UPPER RIGHT TRIANGLE %][% RESET %][% BRIGHT WHITE %]\___ \| | | / __| __/ _ \ '_ ` _ \  | |\/| |/ _ \ '_ \| | | |[% RESET %]
[% BRIGHT GREEN   %]  [% BLACK LOWER RIGHT TRIANGLE %][% B_BRIGHT GREEN   %] [% RESET %][% BRIGHT GREEN   %][% INVERT %][% BLACK LOWER RIGHT TRIANGLE %][% RESET %][% BRIGHT WHITE %] ___) | |_| \__ \ ||  __/ | | | | | | |  | |  __/ | | | |_| |[% RESET %]
[% BRIGHT MAGENTA %] [% BLACK LOWER RIGHT TRIANGLE %][% B_BRIGHT MAGENTA %] [% RESET %][% BRIGHT MAGENTA %][% INVERT %][% BLACK LOWER RIGHT TRIANGLE %][% RESET %] [% BRIGHT WHITE %]|____/ \__, |___/\__\___|_| |_| |_| |_|  |_|\___|_| |_|\__,_|[% RESET %]
[% BRIGHT BLUE    %][% BLACK LOWER RIGHT TRIANGLE %][% B_BRIGHT BLUE    %] [% RESET %][% BRIGHT BLUE    %][% INVERT %][% BLACK LOWER RIGHT TRIANGLE %][% RESET %]  [% BRIGHT WHITE %]       |___/[% RESET %]
```

![BBS::Universal SysOp System Menu](SysOpSystemMenu.png?raw=true "BBS::Universal SysOp System Menu")
