# Make and upload a release tarball

These instructions are based on https://www.perl.com/article/how-to-upload-a-script-to-cpan/.

```
# update the readme
perldoc -u git-autofixup > README.pod
# generate the makefile
perl Makefile.PL
# make the manifest (Probably only needed if you don't already have a MANIFEST)
make manifest
# make the files to be distributed
make
# install it, if you want to test that installation works
make install
# make the dist tarball
make dist
# upload to cpan
cpan-upload -u TORBIAK "${tarball:?}"

# Rebuild old perl modules

Maybe it'd be better to figure out the curl args to upload to PAUSE instead, but if you get `loadable library and perl binaries are mismatched` errors you've most likely updated your perl since installing certain modules, and you'll need to rebuild them all. Delete all the modules that were installed via cpan instead of your distro's package manager, and then reinstall them. If you care to, use `cpan -l` to get a list of installed modules before removing them, so you can feed it to cpan after.
