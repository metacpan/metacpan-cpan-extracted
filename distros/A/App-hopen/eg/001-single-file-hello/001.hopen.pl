# 001-single-file-hello/001.hopen.pl

use language 'C';   # uses <toolset>::C, and makes `C` an alias for it.
    # The "language" package is synthesized by App::hopen::HopenFileKit.

on check => {};     # Nothing to do during the Check phase

$Build
    ->H::files('hello.c', -name=>'FilesHello')  # H is automatically loaded
    ->C::compile(-name=>'CompileHello')
    ->C::link('hello', -name=>'LinkHello')
    ->default_goal;
