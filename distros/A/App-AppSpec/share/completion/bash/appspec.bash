#!bash

# http://stackoverflow.com/questions/7267185/bash-autocompletion-add-description-for-possible-completions

_appspec() {

    COMPREPLY=()
    local program=appspec
    local cur=${COMP_WORDS[$COMP_CWORD]}
#    echo "COMP_CWORD:$COMP_CWORD cur:$cur" >>/tmp/comp
    declare -a FLAGS
    declare -a OPTIONS
    declare -a MYWORDS

    local INDEX=`expr $COMP_CWORD - 1`
    MYWORDS=("${COMP_WORDS[@]:1:$COMP_CWORD}")

    FLAGS=('--help' 'Show command help' '-h' 'Show command help')
    OPTIONS=()
    __appspec_handle_options_flags

    case $INDEX in

    0)
        __comp_current_options || return
        __appspec_dynamic_comp 'commands' 'completion'$'\t''Generate completion for a specified spec file'$'\n''help'$'\t''Show command help'$'\n''new'$'\t''Create new app'$'\n''pod'$'\t''Generate pod'$'\n''validate'$'\t''Validate spec file'

    ;;
    *)
    # subcmds
    case ${MYWORDS[0]} in
      _complete)
        FLAGS+=('--zsh' 'for zsh' '--bash' 'for bash')
        OPTIONS+=('--name' 'name of the program')
        __appspec_handle_options_flags
          case $INDEX in
          *)
            __comp_current_options true || return # after parameters
            case ${MYWORDS[$INDEX-1]} in
              --name)
              ;;

            esac
            ;;
        esac
      ;;
      _pod)
        FLAGS+=()
        OPTIONS+=()
        __appspec_handle_options_flags
        __comp_current_options true || return # no subcmds, no params/opts
      ;;
      completion)
        FLAGS+=('--zsh' 'for zsh' '--bash' 'for bash')
        OPTIONS+=('--name' 'name of the program')
        __appspec_handle_options_flags
          case $INDEX in
          1)
              __comp_current_options || return
          ;;
          *)
            __comp_current_options true || return # after parameters
            case ${MYWORDS[$INDEX-1]} in
              --name)
              ;;

            esac
            ;;
        esac
      ;;
      help)
        FLAGS+=('--all' '')
        OPTIONS+=()
        __appspec_handle_options_flags
        case $INDEX in

        1)
            __comp_current_options || return
            __appspec_dynamic_comp 'commands' 'completion'$'\n''new'$'\n''pod'$'\n''validate'

        ;;
        *)
        # subcmds
        case ${MYWORDS[1]} in
          _complete)
            FLAGS+=()
            OPTIONS+=()
            __appspec_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          _pod)
            FLAGS+=()
            OPTIONS+=()
            __appspec_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          completion)
            FLAGS+=()
            OPTIONS+=()
            __appspec_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          new)
            FLAGS+=()
            OPTIONS+=()
            __appspec_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          pod)
            FLAGS+=()
            OPTIONS+=()
            __appspec_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          validate)
            FLAGS+=()
            OPTIONS+=()
            __appspec_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
        esac

        ;;
        esac
      ;;
      new)
        FLAGS+=('--overwrite' 'Overwrite existing dist directory' '-o' 'Overwrite existing dist directory' '--with-subcommands' 'Create an app with subcommands' '-s' 'Create an app with subcommands')
        OPTIONS+=('--name' 'The (file) name of the app' '-n' 'The (file) name of the app' '--class' 'The main class name for your app implementation' '-c' 'The main class name for your app implementation')
        __appspec_handle_options_flags
          case $INDEX in
          1)
              __comp_current_options || return
          ;;
          *)
            __comp_current_options true || return # after parameters
            case ${MYWORDS[$INDEX-1]} in
              --name|-n)
              ;;
              --class|-c)
              ;;

            esac
            ;;
        esac
      ;;
      pod)
        FLAGS+=()
        OPTIONS+=()
        __appspec_handle_options_flags
          case $INDEX in
          1)
              __comp_current_options || return
          ;;
          *)
            __comp_current_options true || return # after parameters
            case ${MYWORDS[$INDEX-1]} in

            esac
            ;;
        esac
      ;;
      validate)
        FLAGS+=('--color' 'output colorized' '-C' 'output colorized')
        OPTIONS+=()
        __appspec_handle_options_flags
          case $INDEX in
          1)
              __comp_current_options || return
          ;;
          *)
            __comp_current_options true || return # after parameters
            case ${MYWORDS[$INDEX-1]} in

            esac
            ;;
        esac
      ;;
    esac

    ;;
    esac

}

_appspec_compreply() {
    IFS=$'\n' COMPREPLY=($(compgen -W "$1" -- ${COMP_WORDS[COMP_CWORD]}))
    if [[ ${#COMPREPLY[*]} -eq 1 ]]; then # Only one completion
        COMPREPLY=( ${COMPREPLY[0]%% -- *} ) # Remove ' -- ' and everything after
        COMPREPLY="$(echo -e "$COMPREPLY" | sed -e 's/[[:space:]]*$//')"
    fi
}


__appspec_dynamic_comp() {
    local argname="$1"
    local arg="$2"
    local comp name desc cols desclength formatted
    local max=0

    while read -r line; do
        name="$line"
        desc="$line"
        name="${name%$'\t'*}"
        if [[ "${#name}" -gt "$max" ]]; then
            max="${#name}"
        fi
    done <<< "$arg"

    while read -r line; do
        name="$line"
        desc="$line"
        name="${name%$'\t'*}"
        desc="${desc/*$'\t'}"
        if [[ -n "$desc" && "$desc" != "$name" ]]; then
            # TODO portable?
            cols=`tput cols`
            [[ -z $cols ]] && cols=80
            desclength=`expr $cols - 4 - $max`
            formatted=`printf "'%-*s -- %-*s'" "$max" "$name" "$desclength" "$desc"`
            comp="$comp$formatted"$'\n'
        else
            comp="$comp'$name'"$'\n'
        fi
    done <<< "$arg"
    _appspec_compreply "$comp"
}

function __appspec_handle_options() {
    local i j
    declare -a copy
    local last="${MYWORDS[$INDEX]}"
    local max=`expr ${#MYWORDS[@]} - 1`
    for ((i=0; i<$max; i++))
    do
        local word="${MYWORDS[$i]}"
        local found=
        for ((j=0; j<${#OPTIONS[@]}; j+=2))
        do
            local option="${OPTIONS[$j]}"
            if [[ "$word" == "$option" ]]; then
                found=1
                i=`expr $i + 1`
                break
            fi
        done
        if [[ -n $found && $i -lt $max ]]; then
            INDEX=`expr $INDEX - 2`
        else
            copy+=("$word")
        fi
    done
    MYWORDS=("${copy[@]}" "$last")
}

function __appspec_handle_flags() {
    local i j
    declare -a copy
    local last="${MYWORDS[$INDEX]}"
    local max=`expr ${#MYWORDS[@]} - 1`
    for ((i=0; i<$max; i++))
    do
        local word="${MYWORDS[$i]}"
        local found=
        for ((j=0; j<${#FLAGS[@]}; j+=2))
        do
            local flag="${FLAGS[$j]}"
            if [[ "$word" == "$flag" ]]; then
                found=1
                break
            fi
        done
        if [[ -n $found ]]; then
            INDEX=`expr $INDEX - 1`
        else
            copy+=("$word")
        fi
    done
    MYWORDS=("${copy[@]}" "$last")
}

__appspec_handle_options_flags() {
    __appspec_handle_options
    __appspec_handle_flags
}

__comp_current_options() {
    local always="$1"
    if [[ -n $always || ${MYWORDS[$INDEX]} =~ ^- ]]; then

      local options_spec=''
      local j=

      for ((j=0; j<${#FLAGS[@]}; j+=2))
      do
          local name="${FLAGS[$j]}"
          local desc="${FLAGS[$j+1]}"
          options_spec+="$name"$'\t'"$desc"$'\n'
      done

      for ((j=0; j<${#OPTIONS[@]}; j+=2))
      do
          local name="${OPTIONS[$j]}"
          local desc="${OPTIONS[$j+1]}"
          options_spec+="$name"$'\t'"$desc"$'\n'
      done
      __appspec_dynamic_comp 'options' "$options_spec"

      return 1
    else
      return 0
    fi
}


complete -o default -F _appspec appspec

