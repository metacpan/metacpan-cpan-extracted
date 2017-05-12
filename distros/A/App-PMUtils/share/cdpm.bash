# function definition
cdpm ()
{
    if [[ "$1" = "" ]]; then echo "Please specify a Perl module/prefix name"; return; fi
    local dir=`pmdir "$1"`
    if [[ "$dir" = "" ]]; then echo "Failed"; else cd "$dir"; fi
}

# tab completion
_cdpm ()
{
    local cur=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=( `COMP_LINE="pmdir $cur" COMP_POINT=$[6+${#cur}] pmdir` )
}

# activate tab completion
complete -F _cdpm cdpm
