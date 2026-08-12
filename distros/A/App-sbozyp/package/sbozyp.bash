declare -a _sbozyp_command_prefix_args

_sbozyp_command_prefix() {
    local config_file=
    local working_tree=
    local repo=
    local i=1

    while [[ $i -lt ${#COMP_WORDS[@]} ]]; do
        local word=${COMP_WORDS[i]}
        local next=${COMP_WORDS[i+1]}
        if [[ $word == -F && -z $config_file ]]; then
            config_file=$next
            ((i++))
        elif [[ $word == -R && -z $repo ]]; then
            repo=$next
            ((i++))
        elif [[ $word == -W ]]; then
            working_tree=1
        fi
        ((i++))
    done

    _sbozyp_command_prefix_args=(-T)
    [[ -n $repo ]] && _sbozyp_command_prefix_args+=(-R "$repo")
    [[ -n $working_tree ]] && _sbozyp_command_prefix_args+=(-W)
    [[ -n $config_file ]] && _sbozyp_command_prefix_args+=(-F "$config_file")
}

_sbozyp_config_file() {
    local config_file=/etc/sbozyp/sbozyp.conf
    local i=1
    while [[ $i -lt ${#COMP_WORDS[@]} ]]; do
        if [[ ${COMP_WORDS[i]} == -F ]]; then
            config_file=${COMP_WORDS[i+1]}
            break
        fi
        ((i++))
    done
    printf '%s' "$config_file"
}

_sbozyp_complete_packages() {
    if [[ $cur == .* || $cur == /* ]]; then
        _filedir -d
        return
    fi
    _sbozyp_command_prefix
    local repo_dir=$(sbozyp "${_sbozyp_command_prefix_args[@]}" query -c 2>/dev/null)
    [[ -d $repo_dir ]] || return

    cur=$repo_dir$cur
    _filedir -d
    cur=${cur#"$repo_dir"}
    COMPREPLY=( "${COMPREPLY[@]#"$repo_dir"}" )
    compopt +o filenames 2>/dev/null

    if [[ ${#COMPREPLY[@]} -eq 0 && $cur != */* ]]; then
        COMPREPLY=( "$repo_dir"*/"$cur"*/ )
        [[ -d ${COMPREPLY[0]} ]] || { COMPREPLY=(); return; }
        COMPREPLY=( "${COMPREPLY[@]%/}" )
        COMPREPLY=( "${COMPREPLY[@]##*/}" )
    elif [[ $cur != */* ]]; then
        COMPREPLY=( $(compgen -W "${COMPREPLY[*]}" -X '.*') )
        COMPREPLY=( "${COMPREPLY[@]/%//}" )
        compopt -o nospace 2>/dev/null
    fi
}

_sbozyp_determine_command() {
    local i=1
    local command=

    while [[ $i -lt ${#COMP_WORDS[@]} ]]; do
        local word=${COMP_WORDS[i]}
        local next=${COMP_WORDS[i+1]}
        case $word in
            -F|-R)
                ((i++))
                ;;
            install|in|build|bu|remove|rm|query|qr|search|se|null|nu)
                command=$word
                break
                ;;
        esac
        ((i++))
    done

    printf '%s' "$command"
}

_sbozyp_complete() {
    local cur prev words cword
    _init_completion || return

    local global_opts="--help --version -C -F -R -S -T -W"

    local commands="install build remove query search null"

    if [[ $prev == -F ]]; then
        _filedir
        return
    elif [[ $prev == -R ]]; then
        local repos=$(awk -F' *= *' '/REPO_[0-9]+_NAME/ {print $2}' "$(_sbozyp_config_file)" 2>/dev/null)
        COMPREPLY=( $(compgen -W "$repos" -- $cur) )
        return
    fi

    local command=$(_sbozyp_determine_command)

    case $command in
        install|in)
            local opts="--help -b -f -k -n -r -y -z"
            if [[ $cur == in ]]; then
                COMPREPLY=( "install" )
            elif [[ $cur == -* ]]; then
                COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
            elif [[ $prev == -b ]]; then
                _filedir
            else
                _sbozyp_complete_packages
            fi
            ;;
        build|bu)
            local opts="--help -f -n -y -z"
            if [[ $cur == bu ]]; then
                COMPREPLY=( "build" )
            elif [[ $cur == -* ]]; then
                COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
            else
                _sbozyp_complete_packages
            fi
            ;;
        null|nu)
            local opts="--help"
            if [[ $cur == nu ]]; then
                COMPREPLY=( "null" )
            else
                COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
            fi
            ;;
        query|qr)
            local opts="--help -a -b -c -d -i -m -n -o -p -q -r -s -u -v -x"
            if [[ $cur == qr ]]; then
                COMPREPLY=( "query" )
            elif [[ $cur == -* ]]; then
                COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
            else
                _sbozyp_complete_packages
            fi
            ;;
        remove|rm)
            local opts="--help -f -r -y"
            if [[ $cur == rm ]]; then
                COMPREPLY=( "remove" )
            elif [[ $cur == -* ]]; then
                COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
            elif [[ $cur == .* || $cur == /* ]]; then
                _filedir -d
            else
                _sbozyp_command_prefix
                local installed_packages=$(sbozyp "${_sbozyp_command_prefix_args[@]}" query -a 2>/dev/null)
                if [[ $cur != */* ]]; then
                    installed_packages=$(printf '%s\n' "$installed_packages" | cut -d'/' -f2 | sort)
                fi
                COMPREPLY=( $(compgen -W "$installed_packages" -- "$cur") )
            fi
            ;;
        search|se)
            local opts="--help -c -n -p -q"
            if [[ $cur == se ]]; then
                COMPREPLY=( "search" )
            else
                COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
            fi
            ;;
        *)
            if [[ $cur == -* ]]; then
                COMPREPLY=( $(compgen -W "$global_opts" -- "$cur") )
            else
                COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
            fi
            ;;
    esac

    return 0
}

complete -F _sbozyp_complete -o nosort sbozyp
