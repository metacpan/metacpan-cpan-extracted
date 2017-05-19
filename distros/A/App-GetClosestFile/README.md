# get closest file

> Get the closest file by filename recursively.

![Example](tty.gif)

### Installation

```
$ cpanm App::GetClosestFile
```

### Usage

__Options:__

`--all` - show all matches, by default it will show the single _closest file_ if any match

`--depth N` - set recusion depth

`--break` - separate multiple matches with a line break to make it easier to read, by default the separator will be a space, which means you can do something like this...

```
$ vim $(getclosest --all java)
```

...to open all files that match.

__OS Support:__

Currently does not work on Windows and has only been tested on Linux, YMMV.

### License

MIT

