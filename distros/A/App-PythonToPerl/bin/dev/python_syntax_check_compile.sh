#!/bin/bash
# COPYRIGHT

# https://stackoverflow.com/questions/4284313/how-can-i-check-the-syntax-of-python-script-without-executing-it

echo '[ PYTHON2 ]'
echo

python2 -m py_compile $1

echo
echo '[ PYTHON3 ]'
echo

python3 -m py_compile $1

