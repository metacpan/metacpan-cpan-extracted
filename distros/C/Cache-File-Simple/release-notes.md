# How to do a new release of a module

### Start clean
`make clean`

### Generate the Makefile again
`perl Makefile.PL`

### Run the tests 
`make test`

### Run the tests faster
`prove -lv t/0*`

### Regenerate the `README.md` from the POD documentation
`pod2markdown lib/Cache/File/Simple.pm > README.md`

### Make the .tar.gz
`make tardist`

### Upload .tar.gz to PAUSE
https://pause.cpan.org/pause/authenquery
