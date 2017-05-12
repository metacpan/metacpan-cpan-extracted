For show this example, must do this:

1) Create dancer directory with name 'example_FakeCGI'. For example in /tmp directory :

dancer -a example_FakeCGI -p /tmp

2) Copy everything from this directory to dancer directory and overwrite files:

/bin/cp -b -f -r * /tmp/example_FakeCGI/

3) Run dancer in example directory:

cd /tmp/example_FakeCGI/
./bin/app.pl

