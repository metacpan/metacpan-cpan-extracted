# t/samples/01/01.hopen.pl

use language 'C';   # uses <toolset>::C, and makes `C` an alias for it.
    # The "language" package is synthesized by Data::Hopen::HopenFileKit.

on check => {};     # Nothing to do during the Check phase

$Build
    ->H::files('hello.c', -name=>'FilesHello')  # H is automatically loaded
    ->C::compile(-name=>'CompileHello')
    ->C::link('hello', -name=>'LinkHello')
    ->default_goal;
