
cdd ()
{
    if [[ ${@} =~ ^-{1,2}.* ]]; then
        jump ${@};
        return;
    fi;
    new_path="$(jump -search ${@})";
    if [ -d "${new_path}" ]; then
	jump -add "${new_path}" 1
        mycd "${new_path}";
    else
        echo -e "\\033[31mNo match.\\033[0m";
        false;
    fi
}

_jump_bash_completion_cdd()
{
local old_ifs="${IFS}"
local IFS=$'\n';
COMPREPLY=( $(jump_bash_completion.pl ${COMP_CWORD} ${COMP_WORDS[@]} --search --no_direct_path --no_sub_cwd --no_sub_db) );
IFS="${old_ifs}"

return 1;
}

complete -o dirnames  -F _jump_bash_completion_cdd cdd


_jump_bash_completion()
{
local old_ifs="${IFS}"
local IFS=$'\n';
COMPREPLY=( $(jump_bash_completion.pl ${COMP_CWORD} ${COMP_WORDS[@]}) );
IFS="${old_ifs}"

return 1;
}

complete -o dirnames -F _jump_bash_completion jump


