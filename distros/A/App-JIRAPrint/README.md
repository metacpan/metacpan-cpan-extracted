# NAME

jiraprint - Generate printable XeTeX code to print JIRA tickets on Postits

# INSTALLATION

This is a standard Perl package. Install on system perl:

    sudo cpan -i App::JIRAPrint

Or in your cpanminus favorite destination:

    cpanm App::JIRAPrint

# DEPENDENCY

To process the generated LaTeX code into a usable PDF, you'll have
to have a full TeXLive (or MacTeX) distribution on your machine.

See [https://www.tug.org/texlive/](https://www.tug.org/texlive/) Or  [https://tug.org/mactex/](https://tug.org/mactex/)

# SYNOPSIS

    jiraprint --project PROJ --sprint 52 --output proj-52.tex

Then:

    xelatex proj-52.tex

You can also pipe directly from this to xelatex if you're lazy:

    jiraprint --project PROJ --sprint 52 | xelatex

This will create a pdf named 'texput.pdf'

Note that the 'project' option is optional and can live in the configuration file.

# CONFIGURATION

This script relies on configuration files and on command line options for its configuration.

This will attempt to load three configuration files: `$PWD/.jiraprint.conf` , `$HOME/.jiraprint.conf` and `/etc/jiraprint.conf`.

Each configuration files in in Perl format and can contain the following keys:

    {
      url => 'https://yourjira.domain.net/',
      username => 'jirausername',
      password => 'jirapassword',
      project => 'PROJ',
    }

url, username and password have to be defined in config files.

project can be specified in a config file, but overriden by the command line switch `--project`

Note that each level (going from /etc/, to $HOME, to $PWD) will override the precedent level.

This allows you to define properties (like project) at project, user or global level. A typical setup is to define your project specific stuff
in your project directory, your personnal login details in your `$HOME/.jiraprint.conf` and the organisation wide URL at machine level (in /etc/jiraprint.conf).

# OPTIONS

- --project (-p) PROJ

    The name of the jira project. Typically a 4 letter uppercase identifier. Like `PROJ` for instance.

    Mandatory in the config file(s) or in the command line.

- --sprint (-s) 52

    The number of the sprint to print tickets from. Mandatory in the command line.

- --url

    The root URL  of your jira project. For instance: `https://company.atlassian.net/`. Mandatory in the config file(s) or on the command line.

- --username

    The username to connect as to pull the tickets. Mandatory in the config file(s) or on the command line.

# ABOUT

Copyright Jerome Eteve 2015- jerome dot eteve at a well known email provider with a name that starts with 'g'.
