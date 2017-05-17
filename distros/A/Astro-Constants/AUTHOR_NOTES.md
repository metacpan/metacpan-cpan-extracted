# To Do list

* precision() - make the function aware of the difference between 
absolute and relative uncertainty

As always check 
[the github repository] (https://github.com/duffee/Astro-Constants/issues "Astro::Constants issues")
for current status on issues.

# Author Notes

The author keeps forgetting how to run dzil.

* dzil build	- builds the module
* dzil test		- tests the module
* dzil release	- builds a distribution for uploading

## Perl Critic

Errors that appear on perlcritic and why the design ignores them

### stern
* use constant	- it's faster than other constant modules
* unpack @_		- just because
* Module does not end with "1;"	- it ends with a string.  that's just how I roll

