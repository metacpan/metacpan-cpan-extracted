# App::BS TODO:
- [x] finish pkgbase.sh rewrite in perl
    - [ ] decide whether or fall back to or start with `expac` and `pacsift`
          rather than `pacinfo` abd `pacman` directly
      - [ ] pass multiple packages to expac at once?
          - [ ] figure out how to parse what we recieve back, hopefully it is
                ordered the same as input so we can just break it up by space
                or IFS in the case of multiple packages returned per input
          - [ ] ...
    - [ ] (default?) package resolution rules:
        *** i have no idea what this table thingy is supposed to be based
            on, just coudln't stop aligning things once i started ***

            (1) pkgname  ...........  eq $pkgstr
             || pkgbase

            (2) provides  .....        eq $pkgstr
                                 if $pkgstr =~ /.+\.so$/
                                  || $opt{provides}  // 1

            (3) ownsfile  .....  =~ /^(.+\/)?$pkgstr$/
                                 if $pkgstr =~ /.+\.so$/
                                  || $opt{owns_file} // 1

            (4) satisfies .....      ->( $pkgstr )
                                 if $pkgstr =~ /.+\.so$/
                                  || $opt{satisfies} // 0

    - ~~don't use existing framework if its seriously a blocker~~ start
      working on foundation for functionality across core offering of apps
      (starting with read-only workflow agnostic utility scripts)

- [ ] Figure out how to support async+blocking with same API
    - something like
      [`wants?array` in perlfunc](https://perldoc.perl.org/perlfunc#wantarray)
      but for return values after blocking or a future/promize
      - a specialized role, possibly one that applies itself based on some
        critreia like the existence of an event loop in the caller, `%ENV`, or
        an instance field
    - Maybe just Syntax::Keyword::MultiSUb? Can they be  spread throuought
      different roles meant to be composed onto onto a class together?

- [ ] Build pkg dependency tree w/o `pactree`
    - ...

- [ ] ### libalpm
    - Get entire source loaded proberly, model after FFmpeg::Inline but be
      wraned it has to rebuild everytime its run in a new dirrectory for some
      still undetermined reason
