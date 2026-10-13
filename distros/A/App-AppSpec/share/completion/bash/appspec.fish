# fish completion for appspec
# Generated with perl module App::Spec v0.000
# Requires fish >= 4.0 (uses `commandline -x`)

if string match -qr '^[0-3]\.' -- $version
    echo "appspec completion requires fish >= 4.0 (running $version)" >&2
    return 1
end

# __appspec_optspecs PATH...: argparse optspecs of the options declared by PATH
function __appspec_optspecs
    switch "$argv"
        case ''
            string join \n -- h help
        case '_meta completion generate'
            string join \n -- bash fish name= zsh
        case completion
            string join \n -- bash fish name= zsh
        case help
            string join \n -- all
        case new
            string join \n -- c= class= n= name= o overwrite s with-subcommands
        case validate
            string join \n -- C color
    end
end

# positional words after the program name, options and their values removed
# like App::Spec::Run: remove the options of the current subcommand level,
# then the next word is the subcommand of the next level
function __appspec_words
    set -l rest (commandline -xpc)
    set -e rest[1]
    set -l words
    # -S (fish >= 4.1): no abbreviated long options, otherwise an unknown -e
    # is taken for e.g. --exists-action; fish 4.0 has no way to turn this off
    set -l strict -S
    string match -q '4.0.*' -- $version; and set strict
    while true
        set -l specs (__appspec_optspecs $words)
        # a trailing option still waiting for its value makes argparse fail
        argparse $strict -i $specs -- $rest 2>/dev/null
        or argparse $strict -i $specs -- $rest[1..-2] 2>/dev/null
        or return
        set -l positional (string match -v -- '-*' $argv)
        if not contains -- "$words" '' _meta '_meta completion' '_meta pod' help 'help _meta' 'help _meta completion' 'help _meta pod'; or not set -q positional[1]
            set -a words $positional
            break
        end
        set -a words $positional[1]
        set -e argv[(contains -i -- $positional[1] $argv)]
        set rest $argv
    end
    string join \n -- $words
end

# __appspec_using PATH... N|N+
# true if the words are PATH followed by exactly N (N+: at least N) words
function __appspec_using
    set -l n $argv[-1]
    set -l path $argv[1..-2]
    set -l words (__appspec_words)
    set -l np (count $path)
    if test $np -gt 0
        test "$words[1..$np]" = "$path"; or return 1
    end
    set -l rest (math (count $words) - $np)
    if string match -q '*+' -- $n
        test $rest -ge (string trim -r -c + -- $n)
    else
        test $rest -eq $n
    end
end

# __appspec_prefix PATH...: true if the words start with PATH
function __appspec_prefix
    __appspec_using $argv 0+
end

complete -c appspec -f
complete -c appspec -n '__appspec_using 0' -f -a completion -d 'Generate completion for a specified spec file'
complete -c appspec -n '__appspec_using 0' -f -a help -d 'Show command help'
complete -c appspec -n '__appspec_using 0' -f -a new -d 'Create new app'
complete -c appspec -n '__appspec_using 0' -f -a pod -d 'Generate pod'
complete -c appspec -n '__appspec_using 0' -f -a validate -d 'Validate spec file'
complete -c appspec -n __appspec_prefix -l help -s h -d 'Show command help'
complete -c appspec -n '__appspec_using _meta 0' -f -a completion -d 'Shell completion functions'
complete -c appspec -n '__appspec_using _meta 0' -f -a pod -d 'Pod documentation'
complete -c appspec -n '__appspec_using _meta completion 0' -f -a generate -d 'Generate self completion'
complete -c appspec -n '__appspec_prefix _meta completion generate' -l name -d 'name of the program (optional, override name in spec)' -x
complete -c appspec -n '__appspec_prefix _meta completion generate' -l zsh -d 'for zsh'
complete -c appspec -n '__appspec_prefix _meta completion generate' -l bash -d 'for bash'
complete -c appspec -n '__appspec_prefix _meta completion generate' -l fish -d 'for fish (>= 4.0)'
complete -c appspec -n '__appspec_using _meta pod 0' -f -a generate -d 'Generate self pod'
complete -c appspec -n '__appspec_using completion 0' -F -d 'Path to the spec file (use \'-\' for standard input)'
complete -c appspec -n '__appspec_prefix completion' -l name -d 'name of the program (optional, override the value from the spec)' -x
complete -c appspec -n '__appspec_prefix completion' -l zsh -d 'for zsh'
complete -c appspec -n '__appspec_prefix completion' -l bash -d 'for bash'
complete -c appspec -n '__appspec_prefix completion' -l fish -d 'for fish (>= 4.0)'
complete -c appspec -n '__appspec_using help 0' -f -a completion
complete -c appspec -n '__appspec_using help 0' -f -a new
complete -c appspec -n '__appspec_using help 0' -f -a pod
complete -c appspec -n '__appspec_using help 0' -f -a validate
complete -c appspec -n '__appspec_prefix help' -l all
complete -c appspec -n '__appspec_using help _meta 0' -f -a completion
complete -c appspec -n '__appspec_using help _meta 0' -f -a pod
complete -c appspec -n '__appspec_using help _meta completion 0' -f -a generate
complete -c appspec -n '__appspec_using help _meta pod 0' -f -a generate
complete -c appspec -n '__appspec_using new 0' -f -a '(__fish_complete_directories (commandline -ct))' -d 'Path to the distribution directory (default is \'Dist-Name\' in current directory)'
complete -c appspec -n '__appspec_prefix new' -l name -s n -d 'The (file) name of the app' -x
complete -c appspec -n '__appspec_prefix new' -l class -s c -d 'The main class name for your app implementation' -x
complete -c appspec -n '__appspec_prefix new' -l overwrite -s o -d 'Overwrite existing dist directory'
complete -c appspec -n '__appspec_prefix new' -l with-subcommands -s s -d 'Create an app with subcommands'
complete -c appspec -n '__appspec_using pod 0' -F -d 'Path to the spec file (use \'-\' for standard input)'
complete -c appspec -n '__appspec_using validate 0' -F -d 'Path to the spec file (use \'-\' for standard input)'
complete -c appspec -n '__appspec_prefix validate' -l color -s C -d 'output colorized'

