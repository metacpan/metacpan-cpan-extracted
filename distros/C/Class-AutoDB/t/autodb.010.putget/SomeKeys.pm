package SomeKeys;
use t::lib;
use strict;
use Carp;
use autodbUtil;
use Exporter();

our @ISA=qw(Exporter);
our @EXPORT=(@autodbUtil::EXPORT,
	     qw($class2colls $class2transients $coll2keys label %test_args));

our $class2colls=
  {B00L00=>['B00L00'],
   B01L00=>['B01L00'],
   B02L00=>['B02L00'],
   B03L00=>['B03L00'],
   B00L01=>['B00L01'],
   B01L01=>['B01L01'],
   B02L01=>['B02L01'],
   B03L01=>['B03L01'],
   B00L02=>['B00L02'],
   B01L02=>['B01L02'],
   B02L02=>['B02L02'],
   B03L02=>['B03L02'],
   B00L03=>['B00L03'],
   B01L03=>['B01L03'],
   B02L03=>['B02L03'],
   B03L03=>['B03L03'],
  };

our $coll2keys=
  {B00L00=>[[qw()],[qw()]],
   B01L00=>[[qw(base_key0)],[qw()]],
   B02L00=>[[qw(base_key0 base_key1)],[qw()]],
   B03L00=>[[qw(base_key0 base_key1 base_key2)],[qw()]],
   B00L01=>[[qw()],[qw(list_key0)]],
   B01L01=>[[qw(base_key0)],[qw(list_key0)]],
   B02L01=>[[qw(base_key0 base_key1)],[qw(list_key0)]],
   B03L01=>[[qw(base_key0 base_key1 base_key2)],[qw(list_key0)]],
   B00L02=>[[qw()],[qw(list_key0 list_key1)]],
   B01L02=>[[qw(base_key0)],[qw(list_key0 list_key1)]],
   B02L02=>[[qw(base_key0 base_key1)],[qw(list_key0 list_key1)]],
   B03L02=>[[qw(base_key0 base_key1 base_key2)],[qw(list_key0 list_key1)]],
   B00L03=>[[qw()],[qw(list_key0 list_key1 list_key2)]],
   B01L03=>[[qw(base_key0)],[qw(list_key0 list_key1 list_key2)]],
   B02L03=>[[qw(base_key0 base_key1)],[qw(list_key0 list_key1 list_key2)]],
   B03L03=>[[qw(base_key0 base_key1 base_key2)],[qw(list_key0 list_key1 list_key2)]],
  };

our $class2transients={};

sub label {
  my $test=shift;
  my $object=$test->current_object;
#  $object->id.' '.$object->name if $object;
  (UNIVERSAL::can($object,'name')? $object->name:
   (UNIVERSAL::can($object,'desc')? $object->desc:
    (UNIVERSAL::can($object,'id')? $object->id: '')));
}

our %test_args=(class2colls=>$class2colls,class2transients=>$class2transients,
		coll2keys=>$coll2keys,label=>\&label);

########################################
package B00L00;
use base qw(Class::AutoClass);
use autodbUtil;			# NOT putgetUtil! because we define our own %test_args above
 
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name base_key0 base_key1 base_key2 list_key0 list_key1 list_key2);
%AUTODB=(collection=>'B00L00',keys=>'');
Class::AutoClass::declare;

########################################
package B01L00;
use base qw(Class::AutoClass);
use autodbUtil;			# NOT putgetUtil! because we define our own %test_args above
 
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name base_key0 base_key1 base_key2 list_key0 list_key1 list_key2);
%AUTODB=(collection=>'B01L00',keys=>'base_key0 string');
Class::AutoClass::declare;

########################################
package B02L00;
use base qw(Class::AutoClass);
use autodbUtil;			# NOT putgetUtil! because we define our own %test_args above
 
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name base_key0 base_key1 base_key2 list_key0 list_key1 list_key2);
%AUTODB=(collection=>'B02L00',keys=>'base_key0 string, base_key1 string');
Class::AutoClass::declare;

########################################
package B03L00;
use base qw(Class::AutoClass);
use autodbUtil;			# NOT putgetUtil! because we define our own %test_args above
 
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name base_key0 base_key1 base_key2 list_key0 list_key1 list_key2);
%AUTODB=(collection=>'B03L00',keys=>'base_key0 string, base_key1 string, base_key2 string');
Class::AutoClass::declare;

########################################
package B00L01;
use base qw(Class::AutoClass);
use autodbUtil;			# NOT putgetUtil! because we define our own %test_args above
 
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name base_key0 base_key1 base_key2 list_key0 list_key1 list_key2);
%AUTODB=(collection=>'B00L01',keys=>'list_key0 list(string)');
Class::AutoClass::declare;

########################################
package B01L01;
use base qw(Class::AutoClass);
use autodbUtil;			# NOT putgetUtil! because we define our own %test_args above
 
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name base_key0 base_key1 base_key2 list_key0 list_key1 list_key2);
%AUTODB=(collection=>'B01L01',keys=>'base_key0 string, list_key0 list(string)');
Class::AutoClass::declare;

########################################
package B02L01;
use base qw(Class::AutoClass);
use autodbUtil;			# NOT putgetUtil! because we define our own %test_args above
 
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name base_key0 base_key1 base_key2 list_key0 list_key1 list_key2);
%AUTODB=(collection=>'B02L01',keys=>'base_key0 string, base_key1 string, list_key0 list(string)');
Class::AutoClass::declare;

########################################
package B03L01;
use base qw(Class::AutoClass);
use autodbUtil;			# NOT putgetUtil! because we define our own %test_args above
 
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name base_key0 base_key1 base_key2 list_key0 list_key1 list_key2);
%AUTODB=(collection=>'B03L01',keys=>'base_key0 string, base_key1 string, base_key2 string, list_key0 list(string)');
Class::AutoClass::declare;

########################################
package B00L02;
use base qw(Class::AutoClass);
use autodbUtil;			# NOT putgetUtil! because we define our own %test_args above
 
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name base_key0 base_key1 base_key2 list_key0 list_key1 list_key2);
%AUTODB=(collection=>'B00L02',keys=>'list_key0 list(string), list_key1 list(string)');
Class::AutoClass::declare;

########################################
package B01L02;
use base qw(Class::AutoClass);
use autodbUtil;			# NOT putgetUtil! because we define our own %test_args above
 
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name base_key0 base_key1 base_key2 list_key0 list_key1 list_key2);
%AUTODB=(collection=>'B01L02',keys=>'base_key0 string, list_key0 list(string), list_key1 list(string)');
Class::AutoClass::declare;

########################################
package B02L02;
use base qw(Class::AutoClass);
use autodbUtil;			# NOT putgetUtil! because we define our own %test_args above
 
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name base_key0 base_key1 base_key2 list_key0 list_key1 list_key2);
%AUTODB=(collection=>'B02L02',keys=>'base_key0 string, base_key1 string, list_key0 list(string), list_key1 list(string)');
Class::AutoClass::declare;

########################################
package B03L02;
use base qw(Class::AutoClass);
use autodbUtil;			# NOT putgetUtil! because we define our own %test_args above
 
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name base_key0 base_key1 base_key2 list_key0 list_key1 list_key2);
%AUTODB=(collection=>'B03L02',keys=>'base_key0 string, base_key1 string, base_key2 string, list_key0 list(string), list_key1 list(string)');
Class::AutoClass::declare;

########################################
package B00L03;
use base qw(Class::AutoClass);
use autodbUtil;			# NOT putgetUtil! because we define our own %test_args above
 
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name base_key0 base_key1 base_key2 list_key0 list_key1 list_key2);
%AUTODB=(collection=>'B00L03',keys=>'list_key0 list(string), list_key1 list(string), list_key2 list(string)');
Class::AutoClass::declare;

########################################
package B01L03;
use base qw(Class::AutoClass);
use autodbUtil;			# NOT putgetUtil! because we define our own %test_args above
 
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name base_key0 base_key1 base_key2 list_key0 list_key1 list_key2);
%AUTODB=(collection=>'B01L03',keys=>'base_key0 string, list_key0 list(string), list_key1 list(string), list_key2 list(string)');
Class::AutoClass::declare;

########################################
package B02L03;
use base qw(Class::AutoClass);
use autodbUtil;			# NOT putgetUtil! because we define our own %test_args above
 
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name base_key0 base_key1 base_key2 list_key0 list_key1 list_key2);
%AUTODB=(collection=>'B02L03',keys=>'base_key0 string, base_key1 string, list_key0 list(string), list_key1 list(string), list_key2 list(string)');
Class::AutoClass::declare;

########################################
package B03L03;
use base qw(Class::AutoClass);
use autodbUtil;			# NOT putgetUtil! because we define our own %test_args above
 
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name base_key0 base_key1 base_key2 list_key0 list_key1 list_key2);
%AUTODB=(collection=>'B03L03',keys=>'base_key0 string, base_key1 string, base_key2 string, list_key0 list(string), list_key1 list(string), list_key2 list(string)');
Class::AutoClass::declare;

1;
