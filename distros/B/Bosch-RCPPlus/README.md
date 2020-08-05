# Bosch RCP +

Perl 5 implementation of the Bosch RCP+ remote procedure call.

See:
 - [Oficial documentation](https://www.boschsecurity.com/us/en/partners/integration-tools/)
 - [RCP+ over CGI](https://media.boschsecurity.com/fs/media/pb/media/partners_1/integration_tools_1/developer/rcpplus-over-cgi.pdf)


See [`lib/Commands.pm`](lib/Commands.pm) for full command list.

Commands were taken from debugging an _AUTODOME IP starlight 7000i_ web UI.

See [`bin/`](lib/) for examples.

## Generating RPM

From local source:

```
$ perl Makefile.PL
Checking if your kit is complete...
Looks good
Writing Makefile for Bosch::RCPPlus
$ make dist
rm -rf perl-Bosch-RCPPlus-1.0
/usr/bin/perl "-MExtUtils::Manifest=manicopy,maniread" \
  -e "manicopy(maniread(),'perl-Bosch-RCPPlus-1.0', 'best');"
mkdir perl-Bosch-RCPPlus-1.0
mkdir perl-Bosch-RCPPlus-1.0/lib
mkdir perl-Bosch-RCPPlus-1.0/lib/Bosch
mkdir perl-Bosch-RCPPlus-1.0/lib/Bosch/RCPPlus
tar cvf perl-Bosch-RCPPlus-1.0.tar perl-Bosch-RCPPlus-1.0
perl-Bosch-RCPPlus-1.0/
perl-Bosch-RCPPlus-1.0/LICENSE.md
perl-Bosch-RCPPlus-1.0/README.md
perl-Bosch-RCPPlus-1.0/lib/
perl-Bosch-RCPPlus-1.0/lib/Bosch/
perl-Bosch-RCPPlus-1.0/lib/Bosch/RCPPlus.pm
perl-Bosch-RCPPlus-1.0/lib/Bosch/RCPPlus/
perl-Bosch-RCPPlus-1.0/lib/Bosch/RCPPlus/AuthError.pm
perl-Bosch-RCPPlus-1.0/lib/Bosch/RCPPlus/Response.pm
perl-Bosch-RCPPlus-1.0/lib/Bosch/RCPPlus/Commands.pm
perl-Bosch-RCPPlus-1.0/MANIFEST
perl-Bosch-RCPPlus-1.0/Makefile.PL
rm -rf perl-Bosch-RCPPlus-1.0
gzip --best perl-Bosch-RCPPlus-1.0.tar
$ cp Bosch-RCPPlus-*.*.tar.gz ~/rpmbuild/SOURCES
$ rpmbuild -ba perl-Bosch-RCPPlus.spec
```
