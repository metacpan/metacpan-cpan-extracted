_sbozyp_command_prefix() {
    local config_file_opt=
    local repo_opt=
    local i=1

    while [[ $i -lt ${#COMP_WORDS[@]} ]]; do
        local word=${COMP_WORDS[i]}
        local next=${COMP_WORDS[i+1]}
        if [[ $word == -F && -z $config_file_opt ]]; then
            config_file_opt="-F $next"
        elif [[ $word == -R && -z $repo_opt ]]; then
            repo_opt="-R $next"
        fi
        ((i++))
    done

    printf "%s %s %s" "-T" "$repo_opt" "$config_file_opt";
}

_sbozyp_config_file() {
    local config_file=/etc/sbozyp/sbozyp.conf
    if [[ $(_sbozyp_command_prefix) =~ -F[[:space:]](.+) ]]; then
        config_file=$(eval printf '%s' "${BASH_REMATCH[1]}")
    fi
    printf '%s' "$config_file"
}

_sbozyp_determine_command() {
    local i=1
    local command=
    local comp_words=("${COMP_WORDS[@]}")

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

    printf '%s' $command
}

_sbozyp_complete() {
    local cur prev words cword
    _init_completion || return

    local global_opts="--help --version -C -F -R -S -T"

    local commands="install build remove query search null"

    if [[ $prev == -F ]]; then
        _filedir
        return
    elif [[ $prev == -R ]]; then
        local repos=$(awk -F' *= *' '/REPO_[0-9]+_NAME/ {print $2}' "$(_sbozyp_config_file)")
        COMPREPLY=( $(compgen -W "$repos" -- $cur) )
        return
    fi

    local command=$(_sbozyp_determine_command)

    case $command in
        install|in)
            local opts="--help -f -k -r -y"
            if [[ $cur == in ]]; then
                COMPREPLY=( "install" )
            elif [[ $cur == -* ]]; then
                COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
            else
                local all_prgnams=$(sbozyp $(_sbozyp_command_prefix) search -p '' 2>/dev/null)
                COMPREPLY=( $(compgen -W "$all_prgnams" -- "$cur") )
            fi
            ;;
        build|bu)
            local opts="--help -f -y"
            if [[ $cur == bu ]]; then
                COMPREPLY=( "build" )
            elif [[ $cur == -* ]]; then
                COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
            else
                local all_prgnams=$(sbozyp $(_sbozyp_command_prefix) search -p '' 2>/dev/null)
                COMPREPLY=( $(compgen -W "$all_prgnams" -- "$cur") )
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
            local opts="--help -a -b -c -d -i -m -n -o -p -q -r -s -u -v"
            if [[ $cur == qr ]]; then
                COMPREPLY=( "query" )
            elif [[ $cur == -* ]]; then
                COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
            else
                local all_prgnams=$(sbozyp $(_sbozyp_command_prefix) search -p '' 2>/dev/null)
                COMPREPLY=( $(compgen -W "$all_prgnams" -- "$cur") )
            fi
            ;;
        remove|rm)
            local opts="--help -f -r -y"
            if [[ $cur == rm ]]; then
                COMPREPLY=( "remove" )
            elif [[ $cur == -* ]]; then
                COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
            else
                local installed_packages=$(sbozyp query -a 2>/dev/null | cut -d'/' -f2 | sort)
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
