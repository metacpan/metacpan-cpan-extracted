# function definition
renwd-cd ()
{
    local dir=`renwd --print -- "$1" 2>/dev/null`
    if [[ "$dir" = "" ]]; then echo "Failed"; else cd "../$dir"; fi
}

# activate tab completion
complete -C renwd renwd-cd
