# LOGO

    ~                      __ ~
    ~     ____  ____  ____/ / ~
    ~    / __ \/ __ \/ __  /  ~
    ~   / /_/ / /_/ / /_/ /   ~
    ~  / .___/\____/\__,_/    ~
    ~ /_/                     ~

# NAME

App::Pod - Quickly show available class methods and documentation.

# SYNOPSIS

View summary of Mojo::UserAgent:

    % pod Mojo::UserAgent

View summary of a specific method.

    % pod Mojo::UserAgent get

Edit the module

    % pod Mojo::UserAgent -e

Edit the module and jump to the specific method definition right away.
(Press "n" to next match if neeeded).

    % pod Mojo::UserAgent get -e

Run perldoc on the module (for convenience).

    % pod Mojo::UserAgent -d

List all available methods.
If no methods are found normally, then this will automatically be enabled.
(pod was made to work with Mojo pod styling).

    % pod Mojo::UserAgent -a

List all Module::Build actions.

    % pod Module::Build --query head1=ACTIONS/item-text

Can do the same stuff with a file

    % pod my.pod --query head1

Show help.

    % pod
    % pod -h

# DESCRIPTION

Basically, this is a tool that can quickly summarize the contents of a perl module.

# SUBROUTINES/METHODS

## \_has

Generates class accessor methods (like Mojo::Base::attr)

## run

Run the main program.

    use App::Pod;
    App::Pod->run;

Or just use the included script:

    % pod

## list\_tool\_options

Returns a list of the possible command line options
to this tool.

## list\_class\_options

Shows a list of all the available class options
which may be methods, events, etc.

(This is handy for making tab completion based on
a class.)

## edit\_class

Edit a class using vim.
Can optionally just to a specific keyword.

## doc\_class

Show the documentation for a module using perldoc.

## query\_class

Run a pod query using Pod::Query.

Use --dump option to show the data structure.
(For debugging use).

## show\_header

Prints a generic header for a module.

## show\_inheritance

Show the Inheritance chain of a class/module.

## show\_events

Show any declared class events.

## show\_methods

Show all class methods.

## show\_method\_doc

Show documentation for a specific module method.

## define\_last\_run\_cache\_file

Defined where to save the results from the last run.
This is done for performance reasons.

## store\_cache

Saves the last class name and its methods/options.

## retrieve\_cache

Returns the last stored class cache and its options.

## trim

Trim a line to fit the terminal width.
Handles also escape codes within the line.

# ENVIRONMENT

Install bash completion support.

    % apt install bash-completion

Install tab completion.

    % source bash_completion_pod

# SEE ALSO

[Pod::Query](https://metacpan.org/pod/Pod%3A%3AQuery)

[Pod::LOL](https://metacpan.org/pod/Pod%3A%3ALOL)

[Module::Functions](https://metacpan.org/pod/Module%3A%3AFunctions)

# AUTHOR

Tim Potapov, `<tim.potapov[AT]gmail.com>`

# BUGS

Please report any bugs or feature requests to [https://github.com/poti1/app-pod/issues](https://github.com/poti1/app-pod/issues).

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Pod

You can also look for information at:

[https://metacpan.org/pod/App::Pod](https://metacpan.org/pod/App::Pod)
[https://github.com/poti1/app-pod](https://github.com/poti1/app-pod)

# ACKNOWLEDGEMENTS

TBD

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Tim Potapov.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
