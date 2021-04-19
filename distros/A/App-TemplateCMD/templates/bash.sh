#!/bin/bash
# @(#) $Id:$
# $Log:$
#
typeset THIS="${0##*/}"
typeset THISDIR="$( dirname "${0}" )"

NOW="${NOW:-date +%Y:%m:%d:%T}"

PATH="/bin:/usr/bin:/sbin:/usr/local/bin:/usr/local/sbin:${PATH}"

TMPDIR="${TMPDIR:=/tmp}"

typeset -i DEBUG=0
typeset -i usage=0

function dousage {
    echo "Usage: ${THIS}"  >&2
    exit 22
}

function main {  # MAIN with args passed
    while getopts "dvh" name 2> /dev/null; do
        case "${name}" in
            d|v)
                DEBUG+=1
                [ ${DEBUG} -gt 2 ] && set -xv
            ;;
            h|\?)
                usage+=1
            ;;
            *)
                errmsg "$0:Unsupported or unknown argument -${name}"
                usage+=1
            ;;
        esac
    done
    shift $(($OPTIND - 1))

    if [ ${usage} -gt 0 ]; then
        dousage
        exit 22
    fi

    #  a little reminder on how to open/close files in shell and get the fileid dynamically assigned
    #
    # # read FILE on id infd
    # exec {infd}<"${FILE}"
    # IFS='|' read -u${infd}  VAL
    # while   [ "${VAL}" != "" ]
    # do
    #   IFS='|' read -u${infd} VAL
    # done
    #
    # # close(infd)
    # exec ${infd}<&-

    return $?
}

##########################################
## This scripts global data  #############
##########################################

#declare -A arr=( [key1]=val1 [key2]=val2 ... )

##########################################
## This scripts functions  ###############
##########################################

##########################################
#### template functions    ###############
##########################################

function sysinfo {
    typeset os_kern_rel="$( uname -r )"  # 4.14.88-72.73.amzn1.x86_64
    typeset os_version="$( uname -v )"   # #1 SMP Fri Dec 14 20:12:13 UTC 2018

    logmsg "os_kern_rel                        ) ${os_kern_rel}"
    logmsg "os_version                         ) ${os_version}"

    ulimit -a | tee -a "${LOGF}"
}

function msg { # <msg...>
    echo  "${*}"
}

function errmsg { # <msg...>
    typeset -i sts=$?
    # note: this is just to stderr which may include msg's that are not errors
    #
    echo  "${*}" >&2
    return ${sts}
}

function msgsts { # <std> <msg...>
    typeset -i sts=$1
    shift 1
    typeset msg="${*}"
    if [ $sts -ne 0 ]; then
        errmsg "${msg}"
    fi
    return $sts
}

function errexit { # <std> <msg...>
    typeset -i sts=$1
    shift 1
    typeset msg="${*}"
    if [ $sts -ne 0 ]; then
        errmsg "${msg}"
        exit $sts
    fi
}

function check_available { # <prog>
    typeset pnam="${1}"

    pnam_path="$( which "${pnam}" )"
    if [ "${pnam_path}" = "" ]; then
        errexit 1 "missing \"${pnam}\" please install or fix the issue"
    else
        if [ ! -x "${pnam_path}" ]; then
            errexit 1 "Cannot execute \"${pnam_path}\""
        else
            echo "${pnam_path}"
            return 0
        fi
    fi
    echo ""
}

function dbglvl { # lvl <message>
    typeset -i dl_lvl=${1}
    shift 1
    dl_msg="${*}"

    if [ ${DEBUG} -ge ${dl_lvl} ]; then
        errmsg "#${dl_lvl}: ${dl_msg}"
    fi
}

function dbg { # <message>

    dbglvl 1 "${*}"
}

function display_var { # <dv_var> [ <comment description> ]
    typeset dv_var="${1}"
    shift 1
    #
    typeset dv_comment
    if [ $# -gt 0 ]; then
        dv_comment=" - ${*}"
    else
        dv_comment=""
    fi

eval	dv_value="\$${dv_var}"

    printf "# %-10s : %s%s\n" "${dv_var}" "${dv_value}" "${dv_comment}"
}

function dbg_val { # <var>
    typeset var="${1}"
    shift 1

    if [ ${DEBUG} -gt 0 ]; then
       display_var "${var}" $*
    fi
}

function deletefile { # <filename>
    typeset fnm="${1}"

    if [ -e "${fnm}" ]; then
        dbg "# deletefile:  file exists: \"${fnm}\""
        rm -f "${fnm}" > /dev/null 2> /dev/null
        # set status in case file didn't go away
        [ ! -e "${fnm}" ]
        return $?
    fi
    return 2
}

function create_dir { # <dirname>
    typeset dirname="${1}"

    [ ! -d "${dirname}" ] &&  mkdir -p "${dirname}"
    [ -d "${dirname}" ]
    return $?
}

function input_withprompt { # <promptstr>
    typeset promptstr="${1}"
    typeset var=""

    if [ "${BASH_VERSION}" != "" ]; then
        read -p "${promptstr}" var
    else
        read "var?${promptstr}"
    fi
    msg "${var}"
}

function tmpnam { # <prefix
    typeset prefix="${1}"

    # Generate a uniq name in ${TMPDIR} checking for pre-existing files
    typeset tn_name="${TMPDIR:-/tmp}/${prefix}_${USER}"
    typeset tn_postfix="$$"

    while [ -e "${tn_name}.${tn_postfix}" ]; do
        tn_postfix="$( printf "%d_%d" $$ ${RANDOM} )"
    done

    # its still possible to get a name conflict, but very unlikely
    printf "${tn_name}.${tn_postfix}"
}

function lockfile_get {  # <lckfile> [ <lck_wait> [ lck_tries ]]
    # return 0 if we got the lock
    # return 1 if we failed
    # shell 0 is true !=0 is false
    typeset lckfile="${1}"

    typeset -i lck_wait=${2:-5}
    typeset -i lck_tries=${3:-2}
    typeset -i sts=42

    typeset hname="$( uname -n )"

    if lockfile -${lck_wait} -r ${lck_tries} "${lckfile}"; then
        echo "$(date +"%Y:%m:%d:%T:$hname}:$$")" >> "${lckfile}"
        sts=$?
        if [ ${sts} -ne 0 ]; then
            echo "# Failed to create/update lockfile \"${lckfile}\":${sts}"
            rm -f "${lckfile}"
            exit ${sts}
            # unreachable but stickly would return 0 false
            sts=1
        else
            # Got the lock and updated return true aka 0
            sts=0
        fi
    else
        sts=1
        echo "Job already processing !! Please wait till the job completes"
    fi

    return ${sts}
}

function lockfile_release { # <lckfile>
    # we trusting you that you own this lockfile, you better not be lying!!!
    typeset lckfile="${1}"

    typeset -i sts=0
    if [ -f "${lckfile}" ]; then
        rm -f "${lckfile}"
    [ ! -e "${lckfile}" ] # set status on ! exists
        sts=$?
    fi

    return ${sts}
}

function logmsg { # <msg>...
    # variation of logit below always output msg to stdout as well as logfile
    typeset logit_msg="${1}"

    logit_stsmsg="$($NOW):${THIS}:${logit_msg}"
    if [ "${LOGF}" != "" ]; then
        echo "${logit_stsmsg}" >> "${LOGF}"
    fi
    msg "${logit_msg}"
}

function logit {
    typeset logit_msg="${1}"

    logit_stsmsg="$($NOW):${THIS}:${logit_msg}"
    if [ "${LOGF}" != "" ]; then
        echo "${logit_stsmsg}" >> "${LOGF}"
        if [ ${DEBUG} -gt 0 ]; then
            errmsg "${logit_msg}"
        fi
    else
        msg "${logit_msg}"
    fi
}

function ansible_errmsg { # <sts> <msg...
    typeset -i sts=$1
    shift 1
    msg="${*}"
    typeset ansible_errmsg=""

    case ${sts} in
    0)   ansible_errmsg="OK or no hosts matched";;
    1)   ansible_errmsg="Error";;
    2)   ansible_errmsg="One or more hosts failed";;
    3)   ansible_errmsg="One or more hosts were unreachable";;
    4)   ansible_errmsg="Parser error";;
    5)   ansible_errmsg="Bad or incomplete options";;
    99)  ansible_errmsg="User interrupted execution";;
    250) ansible_errmsg="Unexpected error";;
    *)
        ansible_errmsg="unknown error: ${sts}"
    ;;
    esac

   if [ ${sts} -ne 0 ]; then
        errmsg "${msg}:${sts}:${ansible_errmsg}"
   fi
   return ${sts}
}

function ansible_do_cf {  # <stack> <action> <group> <env>
    typeset stack="${1}"
    typeset action="${2}"
    typeset group="${3}"
    typeset env="${4}"

    BOOTSTRAP="${BOOTSTRAP:-"./bootstrap.ini"}"
    CFYAML="${CFYAML:-"./cloudformation.yaml"}"

    ansible-playbook ${VERBOSE:+-${VERBOSE}}  -i "${BOOTSTRAP}" "${CFYAML}"            \
        --extra-vars="stack="${stack}" stack_action=${action} EnvironmentGroup=${group} Environment=${env}"
    ansible_errmsg $? "action:${action} stack:${stack} group:${group} env:${env}"
    return $?
}

function ltrimc { # <string> <trimchar>
    [ ${DEBUG} -gt 2 ] && set -xv
    typeset str="${1}"
    typeset trimc="${2:0:1}"

    str="${str/%+(${trimc})/}"
    str="${str/#+(${trimc})/}"

    echo "${str}"
}

function trim { # <string:byref>
    typeset -n trim_str_byref="${1}"
    # as of bash version 4.4.19(1)-release although it now knows about passing my named reference
    # its got a way to go with understanding scope
    # ie $1 can not reference a var named the same ie trim "trim_str_byref" will fail here
    # typeset: warning: trim_str_byref: circular name reference
    # no surprises ksh93 gets this right - why people love bash and hate ksh I will never know

    trim_str_byref="${trim_str_byref/%+([[:space:]])/}"
    trim_str_byref="${trim_str_byref/#+([[:space:]])/}"

}

function countchar { # <string> <char>
    [ ${DEBUG} -gt 9 ] && set -xv
    typeset  str="${1}"
    typeset  cc_char="${2:0:1}"

    typeset -i cc_count=0

    edstr="${str//${cc_char}/}"

    cc_count=${#str}-${#edstr}

    echo ${cc_count}
    # return has a limited range 0..255 is safe
    return ${cc_count}
}

function dump_array { # ref:array
    typeset -n dump_arr_byref="${1}"

    typeset -i idx
    for ((idx=0;idx<${#dump_arr_byref[*]};idx++)); do
        [ "${dump_arr_byref[idx]}" != "" ] && \
        printf "#[%3d]: \"%s\"\n" ${idx} "${dump_arr_byref[idx]}"  >&2
    done
}

####################################################
# call main now that functions have been defined
# if only shell allowed pre-declartion of functions
typeset -i sts=0

if [ "${SHELL/bash/}" != "${SHELL}" ]; then
    ## BASH ##
    if [ ${BASH_VERSION:0:1} -lt 4 ]; then
        echo "Expected bash major version to be >= 4 got ${BASH_VERSINFO[0]}"
        echo " update your bash shell immediatly!!!"
        exit 1
    fi
elif [ "${SHELL/ksh/}" != "${SHELL}" ]; then
    # for bash compatibility
    alias declare="typeset"
    sts=0
    ## KSH ##
else
    echo " expecting bash or ksh to be running, hope it works for you"
fi

main "$@"
sts=$?

exit ${sts}
