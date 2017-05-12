use inc::Module::Install 1.00;

use 5.006002;
perl_version '5.006002';

name      'Class-C3-Componentised';
author    'Ash Berlin <ash@cpan.org>';
all_from  'lib/Class/C3/Componentised.pm';

requires  'MRO::Compat';
requires  'Class::Inspector';
requires  'Carp';
requires  'Test::Exception';

# we don't actually need Class::C3. MRO::Compat loads it on 5.8. On 5.10 it
# isn't needed. However, some existing code relies on us loading Class::C3. We
# don't want to break it just yet. Therefore we depend directly on Class::C3 as
# well.

### !!! IMPORTANT !!! ###
# tests currently rely on Class::C3 availability, by requiring it directly
# will need adjustment if the require is removed
requires  'Class::C3' => '0.20';

resources repository => 'git://git.shadowcat.co.uk/p5sagit/Class-C3-Componentised.git';

WriteAll;
