# Author Notes

These are the Author's notes to himself.

# To Do list

* ```precision()``` - make the function aware of the difference between 
absolute and relative uncertainty
* ~~do some benchmarking on the short forms vs the long names~~
* add_constants.pl shouldn't duplicate a constant
* deprecation should be semi-automated
* add symbols and sources to PhysicalConstants.xml
* check the data/XML_Schema.md file for notes on how to modify the schema
* consider adding Coulomb's constant k = 1/4 PI epsilon_0 for better readability (not speed)

As always check 
[the github repository](https://github.com/duffee/Astro-Constants/issues "Astro::Constants issues")
for current status on issues.


# How to Release

## Using Dzil

The author keeps forgetting how to run dzil.

* ```dzil build```	- builds the module
* ```dzil test```		- tests the module
* ```dzil release```	- builds a distribution for uploading to CPAN
* ```dzil authordeps --missing```	- find missing module dependancies
* ```dzil mkrpmspec```	- part of the Fedora RPM build process

## Release checklist

* tests pass
* update version in dist.ini
* check [CPANTS](http://matrix.cpantesters.org/?dist=Astro-Constants)
* check [RT](https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-Constants)
* check [Git Pulse](https://github.com/duffee/Astro-Constants/pulse/monthly) for pending issues and pull requests
* update ChangeLog with history from ```git log```
* link Constants.pm to Constants/DatasourceYear.pm or move old version of Constants.pm to Constants/2017.pm if changes to values in PhysicalConstants.xml
* update git repo tag to new version number
* build CPAN release - ```dzil release```
* [upload](https://pause.perl.org/pause/authenquery?ACTION=add_uri) to CPAN (dzil does this)
* email announcement to the Quantified Onion group
* add missing steps to this checklist

# Design Decisions

## Perl Critic

Errors that appear on perlcritic and why the design ignores them

### stern
* use constant	- it's faster than other constant modules
* unpack @_		- just because
* Module does not end with "1;"	- it ends with a string.  that's just how I roll


# Making changes to *PhysicalConstants.xml*

_Any changes should be kept_  
Look in ```data/old_versions/constants_YEAR_VERSION.xml```
As a change is made, make copy of PhysicalConstants.xml  to the year and 
upcoming release version of Astro::Constants


## Adding a Constant

There is a script that will add a number of constants to the Constants file
 script/add_constants.pl
assumes the following:
* value in units of MKS
* the uncertainty or precision is given relative to the value

## Modifying a Constant

For now I edit the XML with XML Copy Editor.
Rather than building an editor, I should have a validator.

## Deprecating a Constant

One step per version.  No faster.

* if changing name, move name to alternateName
* add to alternate tag
* announce decision to deprecate in upcoming version
* add deprecated tag
 * emit warning on using (in Constants.pm)
 * removed from long
* add notice of deprecation in ChangeLog

### Changing a Name

* add notice to change name to ChangeLog and POD
 * add new name to alternateName type="newName".  old name available in :long
* put new name as Name, old name as alternateName type="oldName".  old name available in :long and :alternate
* change type to ????.  old name available in :alternate
* change type to deprecated, add version attribute.  
 * use of constant emits warning (carp?)  old name available in :deprecated
 * add notice to description tag
 * note deprecation in ChangeLog
* wait minimum of 2 versions and 2 years
* remove deprecated alternateName from PhysicalConstants file
 * note removal in ChangeLog

### Removing a constant

* add notice to change name to ChangeLog and POD
* add deprecated tag, with date and version attributes.  
 * add notice to description tag
 * use of constant emits warning (carp?)  constant available in :deprecated
 * note deprecation in ChangeLog
* wait minimum of 2 versions and 2 years
* remove constant from PhysicalConstants file (to RemovedConstants.xml?)
 * note removal in ChangeLog

## Add *symbol* to PhysicalConstants.xml schema

* adding entity "symbol" to schema
  * no type attribute required if constant is a Latin character
  * otherwise
    * unicode
    * description, usually the unicode description of the character(s)
    * latex and html are the representations to produce the symbol
      * need to find the XML representation of & so that I can produce &pi; in valid XML
    * ascii - how symbol is traditionally rendered in ascii format
* take a look a the diff between PhysicalConstants.xml and PhysicalConstants_with_symbols.xml


# Design decisions

## PhysicalConstants

I chose to keep the Constant definitions in XML for its language independance and validation tools.
Other people have the ability to edit the file and I'd like a way of verifying that the definition
file is correct before the processing tools get blown out of the water.
