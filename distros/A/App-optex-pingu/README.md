[![Actions Status](https://github.com/kaz-utashiro/optex-pingu/workflows/test/badge.svg)](https://github.com/kaz-utashiro/optex-pingu/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-optex-pingu.svg)](https://metacpan.org/release/App-optex-pingu)
# NAME

pingu - optex make-everything-pingu filter

# SYNOPSIS

**optex** -Mpingu \[ options -- \] _command_

# DESCRIPTION

This **optex** module is greatly inspired by [pingu(1)](http://man.he.net/man1/pingu) command and
make every command pingu not only [ping(1)](http://man.he.net/man1/ping).  As for original
command, see ["SEE ALSO"](#see-also) section.  All honor for this idea should go
to the original author.

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/optex-pingu/refs/heads/main/images/pingu2-light.png">
</div>

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/optex-pingu/refs/heads/main/images/pingu2-dark.png">
</div>

This module is a quite good example to demonstrate [optex(1)](http://man.he.net/man1/optex) command
features.

# OPTION

- **--**\[**no-**\]**pingu**

    Produce images.  Enabled by default.

- **--image**=_file_

    Set image file.  File is searched at current directory and module
    directory.  Standard **pingu** image is stored as `pingu.asc2`.  If
    string `pingu` is specified, module search the file in the following
    order.

        ./pingu
        ./pingu.asc2
        ./pingu.asc
        module-dir/pingu
        module-dir/pingu.asc2
        module-dir/pingu.asc

- **--interval**=_sec_

    Specifies the interval time in seconds between outputting each line.
    Default is 0.1 seconds.

# IMAGE FILE FORMAT

- ASCII (`.asc`)

    Each \[`RGBCMYWKrgbcmywk`\] character is converted to specified letter
    with color which the character itself describe.  Upper-case character
    represent normal ANSI color and lower-case means high-intensity color.

        R  r  Red
        G  g  Green
        B  b  Blue
        C  c  Cyan
        M  m  Magenta
        Y  y  Yellow
        K  k  Black
        W  w  White

    Line start with `#` is treated as a comment.

    `pingu.asc`:

         ...        .     ...   ..    ..     .........           
         ...     ....          ..  ..      ... .....  .. ..      
         ...    .......      ...         ... . ..... kkkkkkk     
        .....  ........ .kkkkkkkkkkkkkkk.....  ... kkkkkkkkkk.  .
         .... ........kkkkkkkkkkkkkkkkkkkkk.  ... kkkkkkkkkkk    
              ....... kkwwwwkkkkkkkkkkkkkkkk.... kkkkkkkkkkkk    
        .    .  .... kkwwkkwwkkkkkkkkkkwwwwkk... kkkkkkkkkkk     
           ..   ....kkkkwwwwkkrrrrrrkkwwkkwwk.. .kkkkkkkkkkk     
            .       kkkkkkkkrrrrrrrrrrkwwwwkk.   .kkkkkkkkkk     
           ....     .kkkkkkkkrrrrrrrrkkkkkkkk.      kkkkkkkk     
          .....      .  kkkkkkkkkkkkkkkkkkkk.        kkkkkkk.    
        ......     .. . kkkkkkkkkkkkkkkkkk . .      .kkkkkkk     
        ......       kkkkkkkkkkkkkkkkkkkkk  .      .kkkkkkk      
        ......   .kkkkkkkkkkkkkkkkkkyywwkkkkk  ..  kkkkkkk       
        ...    . kkkkkkkkkkkkkkkkywwwwwwwwwkkkkkkkkkkkkkk.       
               kkkkkkkkkkkkkkkkywwwwwwwwwwwwwkkkkkkkkk .         
              kkkkkkkkkkkkkkkywwwwwwwwwwwwwwwwkk    .            
             kkkkkkkkkkkkkkkywwwwwwwwwwwwwwwwwww  ........       
          .kkkkkkkkkkkkkkkkywwwwwwwwwwwwwwwwwwww    .........    
         .kkkkkkkkkkkkkkkkywwwwwwwwwwwwwwwwwwwwww       .... . . 

    <div>
            <p><img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/optex-pingu/refs/heads/main/images/pingu-light.png">
    </div>

    <div>
            <p><img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/optex-pingu/refs/heads/main/images/pingu-dark.png">
    </div>

- ASCII2 (`.asc2`)

    Each pixel is represented by two blocks, one in the upper half and one
    in the lower half, with each color represented by two lines of data.

    `pingu.asc2`:

         ...        .     ...   ..    ..     .........           
         ...        .     ...   ..    ..     .........           
         ...     ....          ..  ..      ... .....  .. ..      
         ...     ....          ..  ..      ... .....  .. ..      
         ...    .......      ...         ... . .....  kkkkk      
         ...    .......      kkkkkkk     ... . ..... kkkkkkk     
        .....  ........ . kkkkkkkkkkkkk .....  ...  kkkkkkkkk.  .
        .....  ........ kkkkkkkkkkkkkkkkk....  ... kkkkkkkkkk.  .
         .... ........ kkkkkkkkkkkkkkkkkkk .  ... kkkkkkkkkkkk   
         .... ........kkkkkkkkkkkkkkkkkkkkk.  ... kkkkkkkkkkkk   
              ....... kkkwwkkkkkkkkkkkkkkkkk.... kkkkkkkkkkkkk   
              .......kkkwwwwkkkkkkkkkkkkkkkk.... kkkkkkkkkkkk    
        .    .  .... kkwwKKwwkkkkkkkkkkkwwkkk...kkkkkkkkkkkkk    
        .    .  ....kkkwwKKwwkkkkkkkkkkwwwwkk...kkkkkkkkkkkkk    
           ..   ....kkkkwwwwkkkkkkkkkkwwKKwwkk. .kkkkkkkkkkkk    
           ..   ....kkkkkwwkkkkrrrrkkkwwKKwwkk. .kkkkkkkkkkk     
            .       kkkkkkkkkrrrrrrrrkkwwwwkkk   .kkkkkkkkkk     
            .        kkkkkkkrrrrrrrrrrkkwwkkkk   . kkkkkkkkk     
           ....     .kkkkkkkrrrrrrrrrrkkkkkkk.      kkkkkkkk     
           ....     . kkkkkkkrrrrrrrrkkkkkkkk.      kkkkkkkk     
          .....      . kkkkkkkkrrrrkkkkkkkkk.        kkkkkkk.    
          .....      .  kkkkkkkkkkkkkkkkkkkk.        kkkkkkk.    
        ......     .. .  kkkkkkkkkkkkkkkkkk. .      .kkkkkkk     
        ......     .. . kkkkkkkkkkkkkkkkk  . .      .kkkkkk      
        ......        kkkkkkkkkkkkkkkkkkkk  .      .kkkkkkk      
        ......      kkkkkkkkkkkkkkkkkkkkkkk .      .kkkkkkk      
        ......   . kkkkkkkkkkkkkkkkkyyykkkkk   ..  kkkkkkk       
        ......   .kkkkkkkkkkkkkkkkyyyWWWWkkkk  .. kkkkkkkk       
        ...    . kkkkkkkkkkkkkkkkyyWWWWWWWkkkkk  kkkkkkkk.       
        ...    .kkkkkkkkkkkkkkkkyyWWWWWWWWWkkkkkkkkkkkkk .       
               kkkkkkkkkkkkkkkkyyWWWWWWWWWWWkkkkkkkkkk .         
               kkkkkkkkkkkkkkkyyWWWWWWWWWWWWWkkkkkkkk  .         
              kkkkkkkkkkkkkkkyyWWWWWWWWWWWWWWWkkkkk .            
             kkkkkkkkkkkkkkkkyWWWWWWWWWWWWWWWWWkk   .            
             kkkkkkkkkkkkkkkyyWWWWWWWWWWWWWWWWW   ........       
            kkkkkkkkkkkkkkkkyWWWWWWWWWWWWWWWWWWW  ........       
          .kkkkkkkkkkkkkkkkyyWWWWWWWWWWWWWWWWWWW    .........    
          .kkkkkkkkkkkkkkkkyWWWWWWWWWWWWWWWWWWWWW   .........    
         .kkkkkkkkkkkkkkkkyyWWWWWWWWWWWWWWWWWWWWW       .... . . 
         .kkkkkkkkkkkkkkkkyWWWWWWWWWWWWWWWWWWWWWW       .... . . 

Other file format is not supported yet.

Coloring is done by [Getopt::EX::Colormap](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AColormap) module.  See its document
for detail.

# INSTALL

Use [cpanminus(1)](http://man.he.net/man1/cpanminus) command:

    cpanm App::optex::pingu

# PINGU ALIAS

You can set shell alias **pingu** to call [ping(1)](http://man.he.net/man1/ping) command through
**optex**.

    alias pingu='optex -Mpingu --pingu ping'

However, there is more sophisticated way to use **optex** alias
function.  Next command will make symbolic link `pingu->optex` in
`~/.optex.d/bin` directory:

    $ optex --ln pingu

Executing this symbolic link, optex will call system installed
**pingu** command.  So make an alias in `~/.optex.d/config.toml` to
call [ping(1)](http://man.he.net/man1/ping) command instead:

    [alias]
        pingu = "ping -Mpingu"

# MAKING NEW PING OPTION

You can add, say, **--pingu** option to the original [ping(1)](http://man.he.net/man1/ping)
command.  Make a symbolic link `ping->optex` in `~/.optex.d/bin`
directory:

    $ optex --ln ping

And create an rc file `~/.optex.d/ping.rc` for **ping**:

    option --pingu -Mpingu

Then pingu will show up when you use **--pingu** option to execute
[ping(1)](http://man.he.net/man1/ping) command:

    $ ping --pingu localhost -c15

If you want to enable this option always (really?), put next line in
your `~/.optex.d/ping.rc`:

    option default --pingu

# SEE ALSO

[https://github.com/sheepla/pingu](https://github.com/sheepla/pingu)

[App::optex](https://metacpan.org/pod/App%3A%3Aoptex),
[https://github.com/kaz-utashiro/optex/](https://github.com/kaz-utashiro/optex/)

[App::optex::pingu](https://metacpan.org/pod/App%3A%3Aoptex%3A%3Apingu),
[https://github.com/kaz-utashiro/optex-pingu/](https://github.com/kaz-utashiro/optex-pingu/)

## ARTICLES

[https://qiita.com/kaz-utashiro/items/abb436d7df349fe84e69](https://qiita.com/kaz-utashiro/items/abb436d7df349fe84e69)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright ©︎ 2022-2024 Kazumasa Utashiro.

You can redistribute it and/or modify it under the same terms
as Perl itself.
