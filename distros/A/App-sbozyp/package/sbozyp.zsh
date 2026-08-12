#compdef sbozyp

typeset -ga _sbozyp_command_prefix_args

_sbozyp_command_prefix() {
    local config_file=
    local working_tree=
    local repo=
    local i=2

    while [[ $i -lt ${#words[@]} ]]; do
        local word=${words[i]}
        local next=${words[i+1]}
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
    local i=2
    while [[ $i -lt ${#words[@]} ]]; do
        if [[ $words[i] == -F ]]; then
            config_file=$words[i+1]
            break
        fi
        ((i++))
    done
    printf '%s' "$config_file"
}

_sbozyp_complete_packages() {
    if [[ $cur == .* || $cur == /* ]]; then
        _files -/
        return
    fi
    _sbozyp_command_prefix
    local repo_dir=$(sbozyp "${_sbozyp_command_prefix_args[@]}" query -c 2>/dev/null)
    local -a packages
    [[ -d $repo_dir ]] || return

    if [[ $cur == */* ]]; then
        _files -S '' -W "$repo_dir" -/
    elif ! _files -W "$repo_dir" -/; then
        packages=( "$repo_dir"*/"$cur"*(N/) )
        compadd -X "packages" -- "${(@)packages:t}"
    fi
}

_sbozyp_determine_command() {
    local i=2
    local command=

    while [[ $i -lt ${#words[@]} ]]; do
        local word=${words[i]}
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
    local cur=$words[$CURRENT]
    local prev=$words[$CURRENT-1]

    local global_opts="--help --version -C -F -R -S -T -W"

    local commands="install build remove query search null"

    if [[ $prev == -F ]]; then
        _files
        return
    elif [[ $prev == -R ]]; then
        local repos=$(awk -F' *= *' '/REPO_[0-9]+_NAME/ {print $2}' "$(_sbozyp_config_file)" 2>/dev/null)
        compadd -X "repositories" -- ${(f)repos}
        return
    fi

    local command=$(_sbozyp_determine_command)

    case $command in
        install|in)
            local opts="--help -b -f -k -n -r -y -z"
            if [[ $cur == in ]]; then
                compadd -U -- "install"
            elif [[ $cur == -* ]]; then
                compadd -X "options" -- ${=opts}
            elif [[ $prev == -b ]]; then
                _files
            else
                _sbozyp_complete_packages
            fi
            ;;
        build|bu)
            local opts="--help -f -n -y -z"
            if [[ $cur == bu ]]; then
                compadd -U -- "build"
            elif [[ $cur == -* ]]; then
                compadd -X "options" -- ${=opts}
            else
                _sbozyp_complete_packages
            fi
            ;;
        null|nu)
            local opts="--help"
            if [[ $cur == nu ]]; then
                compadd -U -- "null"
            else
                compadd -X "options" -- ${=opts}
            fi
            ;;
        query|qr)
            local opts="--help -a -b -c -d -i -m -n -o -p -q -r -s -u -v -x"
            if [[ $cur == qr ]]; then
                compadd -U -- "query"
            elif [[ $cur == -* ]]; then
                compadd -X "options" -- ${=opts}
            else
                _sbozyp_complete_packages
            fi
            ;;
        remove|rm)
            local opts="--help -f -r -y"
            if [[ $cur == rm ]]; then
                compadd -U -- "remove"
            elif [[ $cur == -* ]]; then
                compadd -X "options" -- ${=opts}
            elif [[ $cur == .* || $cur == /* ]]; then
                _files -/
            else
                _sbozyp_command_prefix
                local installed_packages=$(sbozyp "${_sbozyp_command_prefix_args[@]}" query -a 2>/dev/null)
                if [[ $cur != */* ]]; then
                    installed_packages=$(printf '%s\n' "$installed_packages" | cut -d'/' -f2 | sort)
                fi
                compadd -X "installed packages" -- ${(f)installed_packages}
            fi
            ;;
        search|se)
            local opts="--help -c -n -p -q"
            if [[ $cur == se ]]; then
                compadd -U -- "search"
            else
                compadd -X "options" -- ${=opts}
            fi
            ;;
        *)
            if [[ $cur == -* ]]; then
                compadd -X "global options" -- ${=global_opts}
            else
                compadd -X "commands" -- ${=commands}
            fi
            ;;
    esac

    return 0
}

compdef _sbozyp_complete sbozyp
