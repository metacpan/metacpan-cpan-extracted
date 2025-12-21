#!/usr/bin/env bash
# vim: filetype=bash :  -*- mode: sh; sh-shell: bash; -*-
###############################################################################
# GetOptLong: Getopt Library for Bash Script
# Copyright 2025 Office TECOLI, LLC <https://github.com/tecolicom/getoptlong>
# MIT License: See <https://opensource.org/licenses/MIT>
: ${GOL_VERSION:=0.4.0}
###############################################################################
# Check for nameref support (bash 4.3+)
declare -n > /dev/null 2>&1 || { echo "Does not support ${BASH_VERSION}" >&2 ; exit 1 ; }
_gol_warn() { echo "$@" >&2 ; }
_gol_die()  { _gol_warn "$@" ; exit 1 ; }
_gol_opts() {
    local _key="$1"
    [[ $_key =~ ^[$_MARKS]$ ]] && _key+="$2" && shift
    (($# == 2)) && _opts["$_key"]="$2" && return 0
    [[ -v _opts[$_key] ]] && echo "${_opts[$_key]}" || return 1
}
_gol_alias() { _gol_opts "$_MK_ALIAS" "$@" ; }
_gol_saila() { _gol_opts "$_MK_SAILA" "$@" ; }
_gol_trig()  { _gol_opts "$_MK_TRIG"  "$@" ; }
_gol_hook()  { _gol_opts "$_MK_HOOK"  "$@" ; }
_gol_rule()  { _gol_opts "$_MK_RULE"  "$@" ; }
_gol_help()  { _gol_opts "$_MK_HELP"  "$@" ; }
_gol_ival()  { _gol_opts "$_MK_INIT"  "$@" ; }
_gol_dest()  {
    [[ $1 =~ ^[[:alpha:]] ]] || _gol_die "$1: variable name must start with alphabet"
    _gol_opts "$_MK_DEST"  "$@"
}
_gol_type()  { [[ ${_opts["$1"]} =~ ^([^[:alnum:]]+) ]] && echo "${_MATCH[1]}" || _gol_die "$1: unexpected" ; }
_gol_debug() { [[ ${_opts["&DEBUG"]:-} ]] && _gol_warn DEBUG: "${@}" || : ; }
_gol_plusone() { [[ $1 =~ ^[0-9]+$ ]] && echo $(( $1 + 1 )) || echo 1 ; }
_gol_vstr() { printf "%03d." ${1//./ } ; }
# Main redirection function - sets up environment and delegates to implementation
_gol_redirect() { local _name ;
    declare -n _opts=$GOL_OPTHASH
    declare -n _MATCH=BASH_REMATCH
    _gol_debug "${FUNCNAME[1]}(${@@Q})"
    local _MARKS='><()&=#^.' _MK_ALIAS='>' _MK_SAILA='<' _MK_TRIG='(' _MK_HOOK=')' _MK_CONF='&' _MK_RULE='=' _MK_HELP='#' _MK_INIT='^' _MK_DEST='.' \
	  _IS_ANY='+:?@%' _IS_MOD='!>' _IS_REQ=':@%' _IS_FLAG='+' _IS_NEED=':' _IS_MAYB='?' _IS_LIST='@' _IS_HASH='%' _IS_HOOK='!' _IS_PASS='>' \
	  _CONFIG=(EXIT_ON_ERROR SILENT PERMUTE REQUIRE DEBUG PREFIX DELIM USAGE HELP)
    for _name in "${_CONFIG[@]}" ; do declare _$_name="${_opts[&$_name]=}" ; done
    "${FUNCNAME[1]}_" "$@"
}
gol_dump () { _gol_redirect "$@" ; }
gol_dump_() { local _key ;
    if [[ ${1-} =~ ^(-a|--all)$ ]] ; then
	for _key in "${!_opts[@]}" ; do
	    printf '[%s]=%s\n' "${_key}" "${_opts["$_key"]@Q}"
	done | sort
    fi
    gol_vdump_
}
gol_vdump () { _gol_redirect "$@" ; }
gol_vdump_() { local _declare ; declare -A _seen ;
    for _key in "${!_opts[@]}" ; do
	[[ $_key =~ ^[$_MK_DEST](.*) ]] && [[ -z ${_seen[${_opts[$_key]}]-} ]] || continue
	_declare=$(declare -p "${_opts[$_key]}" 2> /dev/null) && echo "$_declare"
	_seen[${_opts[$_key]}]=1
    done | sort
}
gol_init() { local _key ;
    (( $# == 0 )) && { echo '(( ${#FUNCNAME[@]} > 0 )) && local GOL_OPTHASH OPTIND=1 || OPTIND=1' ; return ; }
    declare -n _opts=$1
    declare -A GOL_CONFIG=([PERMUTE]=GOL_ARGV [EXIT_ON_ERROR]=1 [DELIM]=$' \t,' [HELP]='help|h!#show HELP')
    for _key in "${!GOL_CONFIG[@]}" ; do : ${_opts["&$_key"]="${GOL_CONFIG[$_key]}"} ; done
    GOL_OPTHASH=$1
    (( $# > 1 )) && gol_configure "${@:2}"
    _gol_redirect
}
################################################################################
gol_init_() { local _key _aliases _alias _help ;
    [[ $_REQUIRE && $(_gol_vstr $GOL_VERSION) < $(_gol_vstr $_REQUIRE) ]] && _gol_die "getoptlong version $GOL_VERSION < $_REQUIRE"
    for _key in "${!_opts[@]}" ; do
	[[ $_key =~ ^[$_MARKS] ]] && continue
	_gol_init_entry "$_key"
    done
    if [[ $_HELP =~ ^( *)([[:alpha:]]+) ]] && _help=${_MATCH[2]} && [[ ! -v _opts[$_help] ]] ; then
	_gol_init_entry "$_HELP"
	declare -F $_help > /dev/null || eval "$_help() { getoptlong help ; exit ; }"
    fi
    return 0
}
_gol_init_entry() { local _entry="$1" _pass= _name _vname _dtype ;
    [[ $_entry =~ ^([-_ \|[:alnum:]]+)([$_IS_ANY]*[$_IS_MOD]*[_[:alnum:]]*)( *)(=([if]|\(.*\)))?( *)(# *(.*[^[:space:]]))? ]] \
	|| _gol_die "[$_entry] -- invalid"
    local _names=${_MATCH[1]} _vtype=${_MATCH[2]} _type=${_MATCH[5]} _comment=${_MATCH[8]}
    local _initial="${_opts[$_entry]-}"
    IFS=$' \t|' read -a _aliases <<< ${_names}
    _name=${_aliases[0]}
    _gol_ival $_name "$_initial"
    unset _opts["$_entry"]
    [[ $_vtype =~ ([$_IS_ANY]*[$_IS_MOD]*)([_[:alnum:]]+)$ ]] && { _vtype=${_MATCH[1]} ; _vname=${_MATCH[2]} ; }
    [[ $_vtype =~ $_IS_PASS ]] && { _vtype=${_vtype//$_IS_PASS/} ; _pass="$_IS_PASS" ; }
    [[ $_vtype =~ $_IS_HOOK ]] && { _vtype=${_vtype//$_IS_HOOK/} ; _gol_hook $_name ${_vname-$_name} ; }
    _gol_dest $_name ${_vname="${_PREFIX}${_name//-/_}"}
    : ${_vtype:=$_IS_FLAG} ${_dtype:=${_pass:+$_IS_LIST}}
    case ${_dtype:-$_vtype} in
	"$_IS_MAYB")
	    [[ $_initial ]] && _gol_die "$_initial: optional parameter can't be initialized" ;;
	"$_IS_LIST"|"$_IS_HASH")
	    [[ $_vtype == $_IS_LIST && ! -v $_vname ]] && declare -ga $_vname
	    [[ $_vtype == $_IS_HASH && ! -v $_vname ]] && declare -gA $_vname
	    if [[ $_initial =~ ^\(.*\)$ ]] ; then
		eval "$_vname=$_initial"
	    else
		[[ $_vtype == $_IS_LIST ]] && _gol_set_array $_vname ${_initial:+"$_initial"}
		[[ $_vtype == $_IS_HASH ]] && [[ $_initial ]] && _gol_die "$_initial: invalid hash data"
	    fi
	    ;;
	"$_IS_NEED"|"$_IS_FLAG") _gol_value $_vname "$_initial" ;;
	*) _gol_die "$_vtype: unknown option type" ;;
    esac
    _opts[$_name]="${_vtype}${_pass}${_vname}"
    [[ $_type ]] && _gol_rule $_name "$_type"
    for _alias in "${_aliases[@]:1}" ; do
	_opts[$_alias]="${_opts[$_name]}"
	_gol_alias $_alias $_name
    done
    _gol_saila $_name "${_aliases[*]:1}"
    [[ $_comment ]] && _gol_help "$_name" "$_comment"
    return 0
}
gol_configure () { _gol_redirect "$@" ; }
gol_configure_() { local _param _key _val ;
    for _param in "$@" ; do
	[[ $_param =~ ^[[:alnum:]] ]] || _gol_die "$_param -- invalid config parameter"
	_key="${_MK_CONF}${_param%%=*}"
	[[ $_param =~ =(.*) ]] && _val="${_MATCH[1]}" || _val=1
	[[ -v _opts[$_key] ]] || _gol_die "$_param -- invalid config parameter"
	_opts[$_key]="$_val"
    done
    return 0
}
gol_optstring_() { local _key _string ;
    for _key in "${!_opts[@]}" ; do
	[[ $_key =~ ^[[:alnum:]]$ ]] && _string+=$_key || continue
	[[ ${_opts[$_key]} =~ [${_IS_REQ}] ]] && _string+=:
    done
    echo "${_SILENT:+:}${_string:- }-:"
}
gol_getopts () { _gol_redirect "$@" ; }
gol_getopts_() { local _optname _val _vtype _vname _name _callback _trigger _pass= ;
    local _opt="$1"; shift;
    case $_opt in
	[:?]) _callback=$(_gol_hook "$_opt") && [[ $_callback ]] && $_callback "$OPTARG"
	      [[ $_EXIT_ON_ERROR ]] && exit 1 || return 1 ;;
	-) _gol_getopts_long "$@" || return $? ;;
	*) _gol_getopts_short || return $? ;;
    esac
    [[ -v _val || $_pass ]] || _val="$(_gol_plusone "$(_gol_value $_vname)")"
    _name=$(_gol_alias ${_optname:-$_opt}) || _name=${_optname:=$_opt}
    _trigger="$(_gol_trig $_name)" && _gol_call_hook "$_trigger" "$_name"
    [[ $_pass ]] && _gol_getopts_passthru || _gol_getopts_store
    _callback="$(_gol_hook $_name)" && _gol_call_hook "$_callback" "$_name" "$_val"
    return 0
}
_gol_call_hook() {
    local _call=($1)
    local exec=("${_call[0]}" "$2" "${_call[@]:1}" "${@:3}")
    declare -F "${_call[0]}" > /dev/null \
	&& "${exec[@]}" || _gol_die "callback function ${_call[0]}() is not defined"
}
_gol_getopts_long() { local _non _param ;
    [[ $OPTARG =~ ^(no-)?([-_[:alnum:]]+)(=(.*))? ]] || _gol_die "$OPTARG: unrecognized option"
    _non="${_MATCH[1]}" _optname="${_MATCH[2]}" _param="${_MATCH[3]}"
    [[ $_param ]] && _val="${_MATCH[4]}"
    [[ $(_gol_opts $_optname) =~ ^([$_IS_ANY]+)([$_IS_MOD]?)([_[:alnum:]]+) ]] || {
	[[ $_EXIT_ON_ERROR ]] && _gol_die "no such option -- --$_optname" || return 2
    }
    _vtype=${_MATCH[1]} _pass="${_MATCH[2]}" _vname=${_MATCH[3]}
    if [[ $_param ]] ; then
	[[ $_vtype =~ [${_IS_REQ}${_IS_MAYB}] ]] || _gol_die "does not take an argument -- $_optname"
    else
	case $_vtype in
	    [$_IS_MAYB]) _val= ;;
	    [$_IS_REQ])
		if [[ $_non ]] ; then _val= ; else
		    (( OPTIND > $# )) && _gol_die "option requires an argument -- $_optname"
		    _val="${@:$((OPTIND++)):1}"
		fi ;;
	    *) [[ $_non ]] && _val= ;;
	esac
    fi
    return 0
}
_gol_getopts_short() {
    [[ ${_opts[$_opt]-} =~ ^([$_IS_ANY])([$_IS_MOD]?)([_[:alnum:]]+) ]] || {
	[[ $_EXIT_ON_ERROR ]] && _gol_die "no such option -- -$_opt" || return 3
    }
    _vtype=${_MATCH[1]} _pass="${_MATCH[2]}" _vname=${_MATCH[3]}
    [[ $_vtype =~ [${_IS_MAYB}${_IS_REQ}] ]] && _val="${OPTARG:-}"
    return 0
}
_gol_getopts_store() { local _vals _v ;
    local _check=$(_gol_rule $_name)
    case $_vtype in
	[$_IS_LIST]|[$_IS_HASH])
	    [[ $_val =~ $'\n' ]] && readarray -t _vals <<< ${_val%$'\n'} \
				 || IFS="${_DELIM}" read -a _vals <<< ${_val}
	    for _v in "${_vals[@]}" ; do
		[[ $_check ]] && _gol_validate "$_check" "$_v"
		case $_vtype in
		[$_IS_LIST]) _gol_set_array $_vname "$_v" ;;
		[$_IS_HASH])
		    [[ $_v =~ = ]] && _gol_set_hash $_vname "${_v%%=*}" "${_v#*=}" \
				   || _gol_set_hash $_vname "$_v" 1 ;;
		esac
	    done
	    ;;
	*) [[ $_check ]] && _gol_validate "$_check" "$_val"
	   _gol_value $_vname "$_val" ;;
    esac
}
_gol_getopts_passthru() { local _options=() ;
    local _option=${_optname-$_opt}
    (( ${#_option} > 1 )) && _options=(--$_option) || _options=(-$_option)
    [[ $_vtype =~ [$_IS_REQ] ]] && _options+=($_val)
    _gol_set_array $_vname "${_options[@]}"
}
_gol_value() {
    declare -n __target__="$1"
    (( $# > 1 )) && __target__="$2" || echo "$__target__"
}
_gol_set_array() { declare -n __target__="$1" ; __target__+=("${@:2}") ; }
_gol_set_hash()  { declare -n __target__="$1" ; __target__["$2"]="$3" ; }
_gol_validate() {
    case $1 in
	i)   [[ "$2" =~ ^[-+]?[0-9]+$ ]]            || _gol_die "$2: not an integer" ;;
	f)   [[ "$2" =~ ^[-+]?[0-9]*(\.[0-9]+)?$ ]] || _gol_die "$2: not a number" ;;
	\(*) declare -a error=([1]="$2: invalid argument" [2]="$1: something wrong")
	     eval "[[ \"$2\" =~ $1 ]]" || _gol_die "${error[$?]}" ;;
	*)   _gol_die "$1: unknown validation pattern" ;;
    esac
}
gol_callback () { _gol_redirect "$@" ; }
gol_callback_() {
    local _setter=_gol_hook
    case ${1-} in -b|--before) _setter=_gol_trig ; shift ;; esac
    while (($# > 0)) ; do
	local _name=$1 _callback=${2:-$1}
	[[ $_callback =~ ^[_[:alnum:]] ]] || _callback=$_name
	local args=($_callback)
	$_setter "$_name" "${args[0]//-/_} ${args[@]:1}"
	shift $(( $# >= 2 ? 2 : 1 ))
    done
    return 0
}
gol_help () { _gol_redirect "$@" ; }
gol_help_() {
    (( $# < 2 )) && { _gol_show_help "$@" ; return 0 ; }
    while (($# > 1)) ; do _gol_help "$1" "$2" ; shift 2 ; done
}
_gol_show_help() { local _key _aliases _init= _default= _column _flag _msg ;
    echo "${1:-${_USAGE:-$(basename $0) [ options ] args}}"
    _column=($(command -v column)) && _column+=(-s $'\t' -t) || _column=(cat)
    for _key in "${!_opts[@]}" ; do
	_aliases="$(_gol_saila "$_key")" || continue
	_msg="$(_gol_help $_key)" || {
	    _init="$(_gol_ival $_key)" && _default="${_init:+ (default:$_init)}"
	    [[ $_init =~ ^[0-9]+$ ]] && _flag=bump || _flag=enable
	    [[ "${_opts[$_key]}" =~ ([^[:alnum:]]+)(.*) ]] || _gol_die "${_opts[$_key]}: invalid entry"
	    case "${_MATCH[1]}" in
		*[$_IS_PASS]) _msg="passthrough to ${_MATCH[2]^^}" ;;
		*[$_IS_FLAG]) _msg="$_flag ${_key^^}$_default" ;;
		*[$_IS_NEED]) _msg="set ${_key^^}$_default" ;;
		*[$_IS_LIST]) _msg="add item(s) to ${_key^^}" ;;
		*[$_IS_HASH]) _msg="set KEY=VALUE(s) in ${_key^^}" ;;
		*[$_IS_MAYB]) _msg="enable/set ${_key^^}" ;;
	    esac
	}
	printf '    %s\t%1s\t%s\n' "$(_gol_optize $_key)" "$(_gol_optize $_aliases)" "$_msg"
    done | sort | "${_column[@]}"
}
_gol_optize() { local _name _opt _optlist _eq ;
    for _name in "$@"; do
	(( ${#_name} > 1 )) && _opt=--$_name _eq='=' || _opt=-$_name _eq=
	case "$(_gol_type $_name)" in
	    [$_IS_NEED]) _opt+="$_eq#" ;;
	    [$_IS_LIST]) _opt+="$_eq#[,#]" ;;
	    [$_IS_HASH]) _opt+="$_eq#=#" ;;
	    [$_IS_MAYB]) (( ${#_name} > 1 )) && _opt+="[=#]" ;;
	esac
	_optlist+=("$_opt")
    done
    printf '%s\n' "${_optlist[*]}"
}
gol_parse () { _gol_redirect "$@" ; }
gol_parse_() { local gol_OPT SAVEARG=() SAVEIND= ;
    local optstring="$(gol_optstring_)" ; _gol_debug "OPTSTRING=$optstring" ;
    for (( OPTIND=1 ; OPTIND <= $# ; OPTIND++ )) ; do
	while getopts "$optstring" gol_OPT ; do
	    gol_getopts_ "$gol_OPT" "$@" || {
		_gol_debug "SAVE ERROR: ${@:$((OPTIND-1)):1}"
		SAVEARG+=("${@:$((OPTIND-1)):1}")
	    }
	done
	: ${SAVEIND:=$OPTIND}
	[[ ! $_PERMUTE || $OPTIND > $# || ${@:$(($OPTIND-1)):1} == -- ]] && break
	_gol_debug "SAVE PARAM: ${!OPTIND}"
	SAVEARG+=("${!OPTIND}")
    done
    set -- "${SAVEARG[@]}" "${@:$OPTIND}"
    OPTIND=${SAVEIND:-$OPTIND}
    _gol_debug "ARGV=(${@@Q})"
    [[ $_PERMUTE ]] && { declare -n _gol_argv=$_PERMUTE ; _gol_argv=("$@") ; }
    return 0
}
gol_set () { _gol_redirect "$@" ; }
gol_set_() {
    [[ $_PERMUTE ]] && printf 'set -- "${%s[@]}"\n' "$_PERMUTE" \
		    || echo 'set -- "${@:$OPTIND}"'
}
# Main entry point - dispatch to appropriate subcommand
getoptlong () {
    case $1 in
	init|parse|set|configure|getopts|callback|dump|help) gol_$1 "${@:2}" ;;
	version) echo ${GOL_VERSION} ;;
	*) _gol_die "unknown subcommand -- $1" ;;
    esac
}
# Auto-initialization if first argument is an associative array
if [[ $(declare -p "${1-}" 2> /dev/null) =~ ^declare\ -A ]] ; then
    gol_init "$1" && shift && gol_parse "$@" && eval "$(gol_set)"
fi
