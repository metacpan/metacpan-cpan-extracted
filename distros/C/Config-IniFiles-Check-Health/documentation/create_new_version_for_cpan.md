# Create new version for CPAN

## New version numbers in File lib/Config/IniFiles/Check/Health.pm

```
our $VERSION = '0.04';

=head1 VERSION

Version 0.04

=cut
```

##

```

rm -rf _build/
```

## Check Build.PL

```
perl Build.PL
```

## Create newest manifest files

```
perl Build manifest
```

## tar.gz zum Hochladen für CPAN erzeugen

```
perl Build.PL
perl Build
perl Build dist
```

## Hochladen durch Einloggen nach pause.cpan.org

- Upload a file to CPAN
- Config-IniFiles-Check-Health-0.04.tar.gz
