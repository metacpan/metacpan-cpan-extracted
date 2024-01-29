#!/bin/sh

url='https://raw.githubusercontent.com/dex4er/PureProxy/master/fatpack/pureproxy'
script='pureproxy'

if command -v curl >/dev/null; then
    get='curl -qsSL'
elif command -v wget >/dev/null; then
    get='wget -O- --quiet'
elif command -v lwp-request >/dev/null; then
    get='lwp-request -m get'
fi

if [ -d /usr/local/bin ] && [ -w /usr/local/bin ]; then
    dir=/usr/local/bin
elif [ -d "${HOME}/.local/bin" ] && [ -w "${HOME}/.local/bin" ]; then
    dir="${HOME}/.local/bin"
else
    dir="${HOME}/bin"
fi

echo "Installing ${script} to ${dir}"
echo ""

if ! echo ":${PATH}:" | grep ":${dir}:" >/dev/null; then
    echo "Please add"
    echo ""
    echo "PATH=\"${dir}:\$PATH\""
    echo ""
    echo "to your ~/.zshrc or ~/.bash_profile or ~/.profile file"
    echo ""
fi

mkdir -p "${dir}"
${get} "${url}" >"${dir}/${script}"
chmod +x "${dir}/${script}"

"${dir}/${script}" -v
