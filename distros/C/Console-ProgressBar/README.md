# NAME

Console::ProgressBar - A simple progress bar for Perl console applications

# SYNOPSIS

    use Console::ProgressBar;

# DESCRIPTION

Console::ProgressBar is a simple progress bar for Perl console applications.

    use Console::ProgressBar;

    # create a progress bar for a task with 20 steps
    my $p = Console::ProgressBar->new('Writing files',20);

    # for each step done, the progress bar index is incremented
    # and the progress bar is displayed at the current cursor position
    for(my $i=1; $i <= 20; $i++) {
        $p->next()->render();
    }

The progress bar displays a title that describe the task and the percentage of completion.

    Writing Files       [##########          ] 50%

## How to install ?

If you want install `Console::ProgressBar` directly from the git repository, please use the following command :

    cpanm https://codeberg.org/auverlot/Console-ProgressBar.git

## How to control the progress bar state ?

### next()

The next() method indicates that a step is done.

### back()

The back() method indicates that the last step must be canceled. The internal index of the progress bar is decremented.

### reset()

The reset() method sets the internal index to 0. For the progress bar, none step has be done. The percentage of completion is 0%.

### setIndex($aValue)

The setIndex() method set the internal index to the specified value (between 0 and the number of steps).

## How to customize the progress bar ?

### setTitle($aTitle)

The setTitle() method changes the title of the progress bar. You can easily displaying a contextual information about the step in progress.

### Change the appearance

The builder has an optional parameter. It's a hash to change the default values of :

- the string that contains the title (`titleMaxSize`), 
- the number of characters used to represent the progression (`length`)
- the caracter used to fill the progress bar (`segment`). 

        titleMaxSize            length
    <------------------> <------------------>
    Writing Files       [##########          ] 50%
                            ^
                          segment

The following example creates a custom progress bar :

    use Console::ProgressBar;

    my $p = Console::ProgressBar->new('Writing files',20, {
        titleMaxSize => 40,
        length => 40,
        segment => '='
    });

# LICENSE

Copyright (C) Auverlot Olivier.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Auverlot Olivier <oauverlot@cpan.org>
