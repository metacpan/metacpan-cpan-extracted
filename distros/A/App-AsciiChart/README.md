# NAME

App::AsciiChart - Simple Ascii Chart

# SYNOPSIS

    use App::AsciiChart;

    App::AsciiChart->new->plot([1, 5, 3, 9, 10, 12]);

# DESCRIPTION

App::AsciiChart is a port to Perl of [https://github.com/kroitor/asciichart](https://github.com/kroitor/asciichart) project.

    12| ....╭.
    11| ....│.
    10| ...╭╯.
     9| ..╭╯..
     8| ..│...
     7| ..│...
     6| ..│...
     5| ╭╮│...
     4| │││...
     3| │╰╯...
     2| │.....
     1| ╯.....

There is also a command line script [asciichart](https://metacpan.org/pod/asciichart).

# LICENSE

Copyright (C) Viacheslav Tykhanovskyi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Viacheslav Tykhanovskyi <viacheslav.t@gmail.com>
