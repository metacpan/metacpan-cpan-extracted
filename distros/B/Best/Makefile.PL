use inc::Module::Install;

# Generate our tests prior to WriteAll.
system $^X, '-T', 'Tests.PL';

name          ('Best');
license       ('MIT');
all_from      ('lib/Best.pm');
clean_files   (qw(t/5*.t t/6*.t));
build_requires('Test::More'      => 0,
               'Test::Exception' => 0);
sign;

auto_install;
WriteAll;
