# function definition
cds ()
{
    if [[ "$1" = "" ]]; then echo "Please specify a short name"; return; fi
    local dir=`short get "$1"`
    if [[ "$dir" = "" ]]; then echo "Failed"; else cd "$dir"; fi
}

# tab completion
_cds ()
{
    local cur=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=( `COMP_LINE="short get $cur" COMP_POINT=$[10+${#cur}] short` )
}

# activate tab completion
complete -F _cds cds
