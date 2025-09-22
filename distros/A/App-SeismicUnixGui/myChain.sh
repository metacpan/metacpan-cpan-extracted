sudo  perl ./dist/manifest.pl
# make sure to force /script/L_SU_project_selector.pl into MANIFEST
sudo perl Makefile.PL
sudo make all
sudo make test
sudo perl clean_unwanted_subdirectory.pl
sudo make install
sudo make dist

