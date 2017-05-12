package AIX::ODM;

$^W++;
use strict;
use vars qw(@ISA @EXPORT $VERSION);
require Exporter;

@ISA = qw(Exporter);

# %EXPORT_TAGS = ( 'all' => [ qw(   ) ] );

# @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw( odm_dump );

$VERSION = "1.0.2";

#======================================================================

$^O =~ /aix/i || die "This module only runs on AIX systems.\n";

sub odm_classes {
  my ${corp} = ${_[0]}?${_[0]}:'C';
  my @classes;
  my @devlist;
  my $class;
  my $devname;
  my %dev;
# Retrieve the list of classes from the ODM
  @classes = `lsdev -${corp} -r class`;
  foreach ${class} (@classes) {
    chomp(${class});
# Retrieve the list of devices associated with each class from the ODM
    @devlist = `lsdev -Cc ${class} -F name`;
    foreach ${devname} (@devlist) {
      chomp(${devname});
      ${dev{${devname}}} = ${class};
    }
  }
  return %dev;
};
################################################################
sub odm_class {
  my ${corp} = ${_[0]}?${_[0]}:'C';
  return -1 if ( ${corp} ne 'C' );
  return -1 if (!${_[1]});
# Retrieve the class of a device from the ODM
  my ${devclass} = `lsdev -${corp} -r class -l ${_[1]}`;
  chomp(${devclass});
  return ${devclass};
};
################################################################
sub odm_subclass {
  my ${corp} = ${_[0]}?${_[0]}:'C';
  return -1 if ( ${corp} ne 'C' );
  return -1 if (!${_[1]});
# Retrieve the subclass of a device from the ODM
  my ${devsub} = `lsdev -${corp} -r subclass -l ${_[1]}`;
  chomp(${devsub});
  return ${devsub};
};
################################################################
sub odm_attributes {
  my @{line};
  my ${ndx};
  my ${aname};
  my %attrib;

# Retrieve the attributes associated with the device from the ODM
# Two lines are returned, the attribute names are returned on the 
# first line, the attribute values returned on the second.
  my @lines = `lsattr -EOl ${_[0]}`;

  chomp(${lines[0]});
  ${lines[0]} =~ s/^#//g;
  my (@attr_name) = split(/:/,${lines[0]});

  chomp(${lines[1]});
  ${lines[1]} =~ s/^#//g;
  my (@attr_valu) = split(/:/,${lines[1]});

  ${ndx} = 0;
  foreach ${aname} (@attr_name) {
    ${attrib{${aname}}} = ${attr_valu[${ndx}]};
    ${ndx} = ${ndx} + 1;
  }
  return %{attrib};
};
################################################################
sub odm_dump {
# Create a hash of devices by their associated class
  my ${corp} = ${_[0]}?${_[0]}:'C';
  my %devlist = &odm_classes(${corp});
  my %attrout;
  my %devices;
  my $ndx;
  my $subndx;
  foreach $ndx (keys %devlist) {
# create a hash of attributes associated with each device
    %{attrout} = &odm_attributes(${ndx});
# Add a hash value for 'class' and 'devname'
    ${devices{${ndx}}{'class'}} = ${devlist{${ndx}}};
    ${devices{${ndx}}{'subclass'}} = odm_subclass(${corp},${ndx});
    chomp(${devices{${ndx}}{'subclass'}});
    ${devices{${ndx}}{'devname'}} = $ndx;
    foreach ${subndx} (keys %attrout) {
      ${devices{${ndx}}{${subndx}}} = ${attrout{${subndx}}};
    }
  }
  return %devices;
}

1;

__END__

=pod
=head1 NAME

AIX::ODM -  A Perl module for retrieving ODM information about an AIX (RS/6000/pSeries) system

=head1 SYNOPSIS

  use AIX::ODM;
  
  my %odm = odm_dump('C|P');
  while ( ($ndx1, $lev2) = each %odm ) {
    while ( ($ndx2, $val) = each %$lev2 ) {
        print "odm{${ndx1}}{${ndx2}} = ${odm{${ndx1}}{${ndx2}}}\n";
    }
  }

  my %dev = odm_classes('C|P');
  foreach ${devname} ( keys %dev ) {
    print "dev{${devname}} = ${dev{${devname}}}\n";
  }

  my %attribs = odm_attributes(${dev{'devname'}};
  foreach ${attrname} ( keys %attribs ) {
    print "attribs{${attrname}} = ${attribs{${attrname}}}\n";
  }

  my ${devclass} = odm_class('C|P',${dev{'devname'});
  my ${devsubcl} = odm_subclass('C|P',${dev{'devname'});

=head1 DESCRIPTION

This module provides a Perl interface for accessing ODM information about an RS/6000 / pSeries machine running the AIX operating system.  It makes available several functions, which return hashes of values containing device information and their attributes:

The syntax examples shown above as 'C|P' should be read as "C" OR "P", meaning the argument should consist of a single quoted letter "C" or "P", but NOT both.

=head1 VERSION

1.0.2 (released 2004-09-15)

=head1 BUGS

No bugs are known at this time.

=head1 TO-DO

=head1 AUTHOR

  Dana French
  mailto:dfrench@mtxia.com
  http://www.mtxia.com
  http://www.ridmail.com
  
=head1 COPYRIGHT/LICENSE

Copyright (c) 2004, Dana French.  This module is free software.  It may be used, redistributed, and/or modified under the terms of the Perl Artistic License.

=cut
