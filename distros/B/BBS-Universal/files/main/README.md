# BBS::Universal User Menus

![BBS::Universal Logo](../files/BBS/BBS_Universal.png?raw=true "BBS::Universal")

# Creating Custom Menu Files

The files in "files/main/" are specifically for the server side of the software that users will see

## Naming

The file must have the suffix that describes the text mode it will be used for processing.

* ```ANSI```    - ANSI mode files
* ```ASCII```   - ASCII mode files
* ```ATASCII``` - ATASCII mode (Atari) files
* ```PETSCII``` - PETSCII mode (Commodore) files

## Format

Custom menus follow a specific format

* Menu descriptors (KEY|COMMAND|COLOR|ACCESS LEVEL|DESCRIPTION)
* Divider "---"
* Text header

### Menu Descriptors

* **KEY**          - A single key used to activate the feature.  It is case insensitive.
* **COMMAND**      - The specific command token to activate the feature.  Use only the token name
* **COLOR**        - The color of the menu choice.  This only works in ANSI and PETSCII text mode, but is still required for other modes.
* **ACCESS LEVEL** - The access level of the command.  The menu option will only be showed and acted upon if the user's access level is equal to or above the specified access level.
* **DESCRIPTION**  - The text to be displayed after the menu option

Note: All menu keys will be sorted on output

#### Access Levels

* **USER**         - The access level for the average user.  The lowest level possible, the default.  It is recommended to use this as a read-only access level.
* **VETERAN**      - Can be treated as a level for approved users, giving them normal access.
* **JUNIOR SYSOP** - A higher level the SysOp can give a special user with mod level style access.
* **SYSOP**        - Full access to everything.

### Divider

The divider MUST be "---" on a line by itself.  This signals to the menu processor the end of the menu descriptors.

### Text Header

This is the actual menu text shown above the actual menu options when parsed and shown.  The text can have embedded tokens appropriate to the text mode the file is created for.

## ANSI Sample

```
# KEY|COMMAND|COLOR|ACCESS LEVEL|DESCRIPTION
B|BBS LISTING|BRIGHT BLUE|USER|Show BBS List
O|FORUMS|MAGENTA|USER|Go To Forums
M|ACCOUNT MANAGER|WHITE|USER|Manage Your Account
F|FILES|GREEN|USER|Go To Files
N|NEWS|CYAN|USER|System News
A|ABOUT|YELLOW|USER|About This BBS
U|LIST USERS|BRIGHT WHITE|USER|List Users
X|DISCONNECT|RED|USER|Disconnect
---
[% RED     %]       [% BLACK LOWER RIGHT TRIANGLE %][% B_RED     %] [% RESET %]   __  __       _          __  __                    [% B_RED     %] [% RESET %][% RED %][% BLACK LOWER LEFT TRIANGLE %][% RESET %]
[% YELLOW  %]      [% BLACK LOWER RIGHT TRIANGLE %][% B_YELLOW  %]  [% RESET %]  |  \/  | __ _(_)_ __    |  \/  | ___ _ __  _   _   [% B_YELLOW  %]  [% RESET %][% YELLOW %][% BLACK LOWER LEFT TRIANGLE %][% RESET %]
[% GREEN   %]     [% BLACK LOWER RIGHT TRIANGLE %][% B_GREEN   %]   [% RESET %]  | |\/| |/ _` | | '_ \   | |\/| |/ _ \ '_ \| | | |  [% B_GREEN   %]   [% RESET %][% GREEN %][% BLACK LOWER LEFT TRIANGLE %][% RESET %]
[% MAGENTA %]    [% BLACK LOWER RIGHT TRIANGLE %][% B_MAGENTA %]    [% RESET %]  | |  | | (_| | | | | |  | |  | |  __/ | | | |_| |  [% B_MAGENTA %]    [% RESET %][% MAGENTA %][% BLACK LOWER LEFT TRIANGLE %][% RESET %]
[% BLUE    %]   [% BLACK LOWER RIGHT TRIANGLE %][% B_BLUE    %]     [% RESET %]  |_|  |_|\__,_|_|_| |_|  |_|  |_|\___|_| |_|\__,_|  [% B_BLUE    %]     [% RESET %][% BLUE %][% BLACK LOWER LEFT TRIANGLE %][% RESET %]
[% FORTUNE %]
```

## ASCII Sample

```
# KEY|COMMAND|COLOR|ACCESS LEVEL|DESCRIPTION
B|BBS LISTING|WHITE|USER|Show BBS List
O|FORUMS|WHITE|USER|Go To Forums
M|ACCOUNT MANAGER|WHITE|USER|Manage Your Account
F|FILES|WHITE|USER|Go To Files
N|NEWS|WHITE|USER|System News
A|ABOUT|WHITE|USER|About This BBS
U|LIST USERS|WHITE|USER|List Users
X|DISCONNECT|WHITE|USER|Disconnect
---
 __  __
|  \/  |___ _ _ _  _
| |\/| / -_) ' \ || |
|_|  |_\___|_||_\_,_|
[% FORTUNE %]
```

## ATASCII Example

* **NOTE**  The "COLOR" parameter only works with "WHITE", since Atari text mode is only global two color.

```
# KEY|COMMAND|COLOR|ACCESS LEVEL|DESCRIPTION
B|BBS LISTING|WHITE|USER|Show BBS List
O|FORUMS|WHITE|USER|Go To Forums
M|ACCOUNT MANAGER|WHITE|USER|Manage Your Account
F|FILES|WHITE|USER|Go To Files
N|NEWS|WHITE|USER|System News
A|ABOUT|WHITE|USER|About This BBS
U|LIST USERS|WHITE|USER|List Users
X|DISCONNECT|WHITE|USER|Disconnect
---
  ## # ##    __  __
  ## # ##   |  \/  |___ _ _ _  _
 ### # ###  | |\/| / -_) ' \ || |
###  #  ### |_|  |_\___|_||_\_,_|
[% FORTUNE %]
```

## PETSCII Example

```
# KEY|COMMAND|COLOR|ACCESS LEVEL|DESCRIPTION
B|BBS LISTING|BLUE|USER|Show BBS List
O|FORUMS|WHITE|USER|Go To Forums
M|ACCOUNT MANAGER|WHITE|USER|Manage Your Account
F|FILES|WHITE|USER|Go To Files
N|NEWS|WHITE|USER|System News
A|ABOUT|WHITE|USER|About This BBS
U|LIST USERS|BRIGHT WHITE|USER|List Users
X|DISCONNECT|WHITE|USER|Disconnect
---
[% RED    %] __  __
[% YELLOW %]|  \/  |___ _ _ _  _
[% GREEN  %]| |\/| / -_) ' \ || |
[% BLUE   %]|_|  |_\___|_||_\_,_|
[% FORTUNE %]
```
