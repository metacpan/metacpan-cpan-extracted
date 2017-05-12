# $Author: domi $
# $Date: 2004/12/13 12:20:28 $
# $Name:  $
# $Revision: 1.4 $

use ExtUtils::MakeMaker;

WriteMakefile
  (
   NAME      => 'Class-IntrospectionMethods',
   VERSION   => '1.003',
   ABSTRACT  => 'Make methods with introspection',
   AUTHOR    => 'Dominique Dumont  (domi@komarr.grenoble.hp.com)',
   PM        =>
   {
    'IntrospectionMethods.pm' => '$(INST_LIB)/Class/IntrospectionMethods.pm',
    'Catalog.pm' => '$(INST_LIB)/Class/IntrospectionMethods/Catalog.pm',
    'Parent.pm' => '$(INST_LIB)/Class/IntrospectionMethods/Parent.pm',
   } ,
   PREREQ_PM =>
   {
    'Tie::Hash::CustomStorage' => 0,
    'Tie::Array::CustomStorage' => 0
   },
   MAN3PODS => 
   {
    'IntrospectionMethods.pm' => 
       '$(INST_MAN3DIR)/Class::IntrospectionMethods.3pm',
    'Legacy.pod' => '$(INST_MAN3DIR)/Class::IntrospectionMethods::Legacy.3pm'
   },
  );

