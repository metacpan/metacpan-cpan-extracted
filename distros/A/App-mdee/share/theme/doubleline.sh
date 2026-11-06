# Doubleline theme - give h4 a double underline where it is known to work
# ESC[4:2m shows as a background color, loses the whole sequence or turns
# into another attribute in many terminals, so this is a list of good ones.
# Inside tmux and screen the variables tell about the outer terminal only.
case ${TERM:-} in
screen*|tmux*) ;;
*)
    case ${TERM_PROGRAM:-} in
    iTerm.app|ghostty|vscode|WezTerm) _double=1 ;;
    esac
    [[ ${KITTY_WINDOW_ID:-}${ALACRITTY_WINDOW_ID:-}${KONSOLE_VERSION:-}${WT_SESSION:-} ]] && _double=1
    (( ${VTE_VERSION:-0} >= 5200 )) && _double=1
    [[ ${_double:-} ]] && md_config+=(h4='${base}U:2;D')
    unset _double
    ;;
esac
