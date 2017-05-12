## AHA Perl Modules

### Description

This small library allows programmatic access to AVM's home automation
system. It uses the HTTP protocol as specified in
http://www.avm.de/de/Extern/files/session_id/AHA-HTTP-Interface.pdf

To install and build the modules:

````bash
     perl ./Build.PL
     ./Build install
````

For more information, see the manpage to AHA.

### Example

````perl
    my $aha = new AHA({host: "fritz.box", password: "s!cr!t"});

    # Get all switches as array ref of AHA::Switch objects
    my $switches = $aha->list();

    # For all switches found
    for my $switch (@$switches) {
       say "Name:    ",$switch->name();
       say "State:   ",$switch->is_on();
       say "Present: ",$switch->is_present()
       say "Energy:  ",$switch->energy();
       say "Power:   ",$switch->power();

       # If switch is on, switch if off and vice versa
       $switch->is_on() ? $switch->off() : $switch->on();
    }

    # Access switch directly via name as configured 
    $aha->energy("Lava lamp");

    # ... or by AIN
    $aha->energy("087610077197");
````

### Disclaimer

This module is in no way associated with AVM and is a private
project. Use it on you own risk, see also below.

### License
  
AHA is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 2 of the License, or (at your
option) any later version.

AHA is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with AHA.  If not, see <http://www.gnu.org/licenses/>.

### Author

roland@cpan.org
