#!/bin/sh

url='https://raw.githubusercontent.com/dex4er/PureProxy/master/examples/pureproxy'
script='pureproxy'

if command -v curl >/dev/null; then
    get='curl -skL'
elif command -v wget >/dev/null; then
    get='wget --no-check-certificate -O- --quiet'
elif command -v lwp-request >/dev/null; then
    PERL_LWP_SSL_VERIFY_HOSTNAME=0
    export PERL_LWP_SSL_VERIFY_HOSTNAME
    get='lwp-request'
fi

if [ -w /usr/local/bin ]; then
    dir=/usr/local/bin
else
    dir="$HOME/bin"
fi


echo "Installing $script to $dir"
echo ""

if ! echo ":$PATH:" | grep ":$dir:" >/dev/null; then
    if [ -f "$HOME/.bash_profile" ]; then
        profile="$HOME/.bash_profile"
    else
        profile="$HOME/.profile"
    fi
    echo "Please add"
    echo ""
    echo "PATH=\"$dir:\$PATH\""
    echo ""
    echo "to your $profile file"
    echo ""
fi

mkdir -p "$dir"
$get $url > "$dir/$script"
chmod +x "$dir/$script"

"$dir/$script" -v
