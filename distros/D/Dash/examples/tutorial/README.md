# Tutorial

The examples in this folder follow the Dash Tutorial: https://dash.plot.ly/

In order to be able to run all the examples you have to install all the
modules used by the examples. You can do this executing this line from
the main folder of the distribution:

```bash
cpanm Perl::PrereqScanner | scan-perl-prereqs examples/tutorial/ | grep -v utf8 | grep -v strict | grep -v warnings | grep -v Dash | cpanm
```
