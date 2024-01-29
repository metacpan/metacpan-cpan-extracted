# CGI::Upload Perl module


## Setup dev environment

```
git clone git@github.com:szabgab/CGI-Upload.git
cd CGI-Upload

cpanm --installdeps .
```

## Release process

* Update VERSION in module
* Update the Changes file

```
perl Build.PL
perl Build
perl Build test
perl Build manifest
perl Build dist
```
