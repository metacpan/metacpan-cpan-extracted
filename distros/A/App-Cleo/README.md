# NAME

cleo - Play back shell commands for live demonstrations

# SYNOPSIS

    cleo COMMAND_FILE

# DESCRIPTION

`cleo` is a utility for playing back pre-recorded shell commands in a live
demonstration.  `cleo` displays the commands as if you had actually typed
them and then executes them interactively.

There is probably an easy way to do this with `expect` or a similar tool.
But I couldn't figure it out, so I built this.  Your mileage may vary.

# PLAYBACK

`cleo` always pauses and waits for a keypress before displaying a command and
before executing it.  Pressing any key besides those listed below will advance
the playback:

    Key                       Action
    ------------------------------------------------------------------
    s                         skip the current command
    r                         redo the current command
    p                         redo the previous command
    q                         quit playback

# COMMANDS

`cleo` reads commands from a file.  Each line is treated as one command.
Blank lines and those starting with `#` will be ignored.  The commands
themselves can be anything that you would type into an interactive shell.
You can also add a few special tokens that `cleo` recognizes:

- `!!!`

    Commands starting with `!!!` (three exclamation points) are not displayed and
    will be executed immediately. This is useful for running setup commands at the
    beginning of your demonstration.

- `%%%`

    Within a command, `%%%` (three percent signs) will cause `cleo` to pause and
    wait for a keypress before displaying the rest of the command.  This is useful
    if you want to stop in the middle of a command to give some explanation.

Otherwise, `cleo` displays and executes the commands verbatim.  Note that
some interactive commands like `vim` are picky about STDOUT and STDIN.  To
make them work properly with `cleo`, you may need to force them to attach
to the terminal like this:

    (exec < /dev/tty vim)

# EXAMPLE

I use this for giving demonstrations of [pinto](https://metacpan.org/pod/pinto), such as the one seen at
[https://www.youtube.com/watch?v=H-JkFXm8Xgk](https://www.youtube.com/watch?v=H-JkFXm8Xgk) (the live demonstration part
starts around 10:47).

The command file that I use for that presentation is included inside this
distribution at `examples/pinto.demo`.  This file is for illustration only,
so don't expect it to actually work for you.

# LIMITATIONS

`cleo` only works on Unix-like platforms.  It may work on Windows if you use
Cygwin.  Personally, I have only used `cleo` on Mac OS X.

# TODO

- Jump to arbitrary command number
- Support backspacing in recorded command
- Support multi-line recorded commands
- Write unit tests

# AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

# COPYRIGHT

Copyright (c) 2014, Imaginative Software Systems
