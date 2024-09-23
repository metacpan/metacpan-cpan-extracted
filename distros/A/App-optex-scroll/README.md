[![Actions Status](https://github.com/kaz-utashiro/optex-scroll/workflows/test/badge.svg)](https://github.com/kaz-utashiro/optex-scroll/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-optex-scroll.svg)](https://metacpan.org/release/App-optex-scroll)
# NAME

App::optex::scroll - optex scroll region module

# SYNOPSIS

optex -Mscroll \[ options -- \] command

# VERSION

Version 0.9902

# DESCRIPTION

**optex**'s **scroll** module prevents a command that produces output
longer than terminal hight from causing the executed command line to
scroll out from the screen.

It sets the scroll region for the output of the command it executes.
The output of the command scrolls by default 10 lines from the cursor
position where it was executed.

# OPTIONS

- **--line**=_n_

    Set scroll region lines to _n_.
    Default is 10.

- **--interval**=_sec_

    Specifies the interval time in seconds between outputting each line.
    Default is 0 seconds.

# EXAMPLES

    optex -Mscroll ping localhost

    optex -Mscroll seq 100000

    optex -Mscroll tail -f /var/log/system.log

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/optex-scroll/main/images/ping.png">
</div>

    optex -Mpingu -Mscroll --line 20 -- ping --pingu -i0.2 -c75 localhost

<div>
    <p>
    <a href="https://www.youtube.com/watch?v=C3LoPAe7YB8">
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/optex-scroll/main/images/pingu.png">
    </a>
</div>

# INSTALL

Use [cpanminus(1)](http://man.he.net/man1/cpanminus) command:

    cpanm App::optex::scroll

# SEE ALSO

[App::optex](https://metacpan.org/pod/App%3A%3Aoptex),
[https://github.com/kaz-utashiro/optex/](https://github.com/kaz-utashiro/optex/)

[App::optex::scroll](https://metacpan.org/pod/App%3A%3Aoptex%3A%3Ascroll),
[https://github.com/kaz-utashiro/optex-scroll/](https://github.com/kaz-utashiro/optex-scroll/)

[App::optex::pingu](https://metacpan.org/pod/App%3A%3Aoptex%3A%3Apingu),
[https://github.com/kaz-utashiro/optex-pingu/](https://github.com/kaz-utashiro/optex-pingu/)

[https://vt100.net/docs/vt100-ug/](https://vt100.net/docs/vt100-ug/)

# LICENSE

Copyright ©︎ 2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kazumasa Utashiro
