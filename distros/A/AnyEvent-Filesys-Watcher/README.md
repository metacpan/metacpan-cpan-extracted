# AnyEvent-Filesys-Watcher - Watch file system for changes

This is a drop-in replacement for
[AnyEvent-Filesys-Notify](https://github.com/mvgrimes/AnyEvent-Filesys-Notify)
but with fewer dependencies.

See the manual page [AnyEvent::Filesys::Watcher](https://github.com/gflohr/AnyEvent-Filesys-Watcher/blob/main/lib/AnyEvent/Filesys/Watcher.pod)
for details.

# INSTALLATION

Unless your operating system is missing in the list below, you have to install
a helper module that provides the binding for the kernel filesystem watch
functionality.

If the command `cpanm` is not available on your system, see
http://www.cpan.org/modules/INSTALL.html for instructions on how to install
Perl modules.

## Linux

Install `Linux::Inotify2`:

```sh
$ cpanm Linux::Inotify2
```

## Mac OS

Install a fork of `Mac::FSEvents`:

```sh
$ git clone https://github.com/skaji/Mac-FSEvents
$ cd Mac-FSEvents
$ perl Makefile.PL
$ make
$ make install
```

The current version 0.14 of `Mac::FSEvents` available on CPAN does not
build on recent Mac OS versions.  This will hopefully change soon.

## MS-DOS "Windows"

Install `Filesys::Notify::Win32::ReadDirectoryChanges`:

```sh
$ cpanm Filesys::Notify::Win32::ReadDirectoryChanges
```

## BSD

Install `IO::KQueue` and `BSD::Resource`

```sh
$ cpanm IO::KQueue BSD::Resource
```

This would also work for Mac OS but you have little reason to prefer
`IO::KQueue` over `Mac::FSEvents` unless you are a developer or just
curious.

# AUTHOR

`AnyEvent::Filesys::Watcher` was originally written as
`AnyEvent::Filesys::Notify` by Mark Grimes,
<mgrimes@cpan.org> and others, and later heavily modifyed 
by [Guido Flohr](http://www.guido-flohr.net/).
