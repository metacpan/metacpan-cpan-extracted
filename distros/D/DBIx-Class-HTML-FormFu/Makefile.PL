use inc::Module::Install;

name 'DBIx-Class-HTML-FormFu';
all_from 'lib/DBIx/Class/HTML/FormFu.pm';

requires 'DBIx::Class';
requires 'HTML::FormFu';

license 'perl';

warn <<END;

**** WARNING
**** This module is deprecated.
**** For new applications, you're advised to use HTML::FormFu::Model::DBIC

END

auto_install();
&WriteAll;
