use strict;
use Test::More tests => 10;

BEGIN {
  use_ok('Class::Data::Localize');
};

package Ray;
{ my ($mk_classdata,$self) = (\&Class::Data::Localize::mk_classdata,__PACKAGE__);
  $mk_classdata->($self,'Ubu');
  $mk_classdata->($self,DataFile => '/etc/stuff/data');
}

# "base" needs this.
sub emptysub {};

package Gun;
use base qw(Ray);
Gun->Ubu('Pere');

package Suitcase;
use base qw(Gun);
Suitcase->DataFile('/etc/otherstuff/data');

package main;

# Test that superclasses effect children.
is +Suitcase->Ubu, 'Pere', "Inherited into children";
is +Ray->Ubu, undef, "But not set in parent";

{ Gun->Ubu('Tremolo',my $local);
  is +Gun->Ubu,'Tremolo', 'Localized value';
};
is +Gun->Ubu, 'Pere', 'Ubu in Gun';

{ Ray->Ubu('tempo',my $temp);
  is +Ray->Ubu, 'tempo', "temporary set";
};
is +Ray->Ubu, undef, "But not set in parent";

{ Gun->Ubu('Tremolo',my $local);
  { Gun->Ubu('dup',my $local);
    is +Gun->Ubu,'dup', 'Inner localized value';
  };
  is +Gun->Ubu,'Tremolo', 'Outer localized value'; 
};

package Prince;

# Set up HomeDir as localizable, inheritable class data.
Class::Data::Localize::mk_classdata(__PACKAGE__,'HomeDir');

sub kiss { $_[1] =~ /ess$/ }

package main;

# Declare the location of the home dir for this class.
Prince->HomeDir('/wooden/house');

# Teporary move to
{ Prince->HomeDir('/stone/castle',my $move);
  if(Prince->kiss('princess')) {
          $move->cancel ;    
  }
};
     
is +Prince->HomeDir,'/stone/castle','canceled localization';
