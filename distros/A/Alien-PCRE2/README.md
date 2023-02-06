# alien-pcre2
Alien::PCRE2, Use Perl To Build The New Perl Compatible Regular Expression Engine On Any Platform

## Developers Only
```
# make CPAN release
$ vi lib/Alien/PCRE2.pm  # update version
$ vi Changes  # update changes
$ make realclean
$ perl Makefile.PL
$ make manifest
$ less MANIFEST
$ make dist
$ less MYMETA.json
$ less MYMETA.yml
$ mv Alien-PCRE2*.tar.gz backup/

# download previous version's tarball from metacpan.org & compare using tardiff
$ wget https://cpan.metacpan.org/authors/id/W/WB/WBRASWELL/Alien-PCRE2-0.XXXXXX.tar.gz -P /tmp
$ tardiff -m -s /tmp/Alien-PCRE2-0.XXXXXX.tar.gz ./backup/Alien-PCRE2-0.YYYYYY.tar.gz
# ensure file differences & line counts seem correct

# compare using adiff
$ sudo apt-get install atool colordiff
$ adiff -m -s /tmp/Alien-PCRE2-0.XXXXXX.tar.gz ./backup/Alien-PCRE2-0.YYYYYY.tar.gz | colordiff | less -R

# upload to CPAN
$ cpan-upload -v -u WBRASWELL --dry-run backup/Alien-PCRE2-VERSION.tar.gz
        # ARE YOU SURE YOU WISH TO PROCEED?!?
$ cpan-upload -v -u WBRASWELL backup/Alien-PCRE2-VERSION.tar.gz
```

