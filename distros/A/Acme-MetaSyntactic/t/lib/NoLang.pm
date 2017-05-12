package main;
$INC{"Win32/Locale.pm"} = 1;
{
    local $^W = 0;
    *Win32::Locale::get_language = sub { '' };
}
delete $ENV{LANGUAGE};
delete $ENV{LANG};
1;
