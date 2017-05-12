#!/bin/sh

url=https://raw.github.com/dex4er/perluse/master/script/perluse.sh

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

if [ -f "$HOME/.bash_profile" ]; then
    profile="$HOME/.bash_profile"
else
    profile="$HOME/.profile"
fi

echo "Installing perluse to $dir"
echo ""
echo "Please add"
echo ""
echo "PATH=\"$dir:\$PATH\""
echo ""
echo "to your $profile file"
echo ""

mkdir -p "$dir"
$get $url > "$dir/perluse"
chmod +x "$dir/perluse"

"$dir/perluse"
