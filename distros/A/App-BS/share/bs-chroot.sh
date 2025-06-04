# TODO: Figure out where to track latest/system ver and which we should track
#       by default
LATEST_PERL=${LATEST_PERL:-5.40.2}

setup() {
    install_plenv
    install_userperl
}

install_plenv() {

}

install_pyenv() {

}

install_userpython() {

}

install_userperl() {
    ver="$1"
    [[ -n "$2" ]] && installenv="$2"

    plenv install "perl-${1:-$LATEST_PERL}"
    plenv install-cpanm

    cpanm --notest Net::SSLeay

    cpanm Minilla Dist::Milla App::cpm Image::ExifTool Carmel Carton \
     Perl::Critic Perl::Tidy
}

restart_shell() {
    exec $SHELL -l
}
