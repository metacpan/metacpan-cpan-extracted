use v5.6.1;
use strict;

use File::Spec::Functions qw( catfile );

use constant MOD_REQS =>
  [
   { name    => 'Pod::Usage',
     version => '1.12', },

   { name    => 'Class::MethodMaker',
     package => 'Class-MethodMaker',
     version => '1.02', },

   { name    => 'IPC::Run',
     package => 'IPC-Run',
     version => '0.44', },

   { name    => 'Log::Info',
     package => 'Log-Info',
     version => '1.03', },
  ];

use constant EXEC_REQS =>
  [
   { name => 'par', },
  ];

use constant NAME         => 'Archive-Par';
use constant VERSION_FROM => catfile (qw( lib Archive Par.pm ));
use constant AUTHOR       => 'Martyn J. Pearce fluffy@cpan.org';
use constant ABSTRACT     => 'Tools for using & manipulating par files';

use make;

