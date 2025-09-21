sudo  perl ./dist/manifest.pl
sudo perl Makefile.PL
sudo make all
sudo make test
sudo perl clean_unwanted_subdirectory.pl
sudo make install
sudo make dist

