# cpan-smoker-utils
![Unit tests](https://github.com/glasswalk3r/cpan-smoker-utils/actions/workflows/unit.yaml/badge.svg?branch=main)

Set of CLI's to manage a Perl CPAN smoker machine.

## Description

This is a Perl distribution used to manage a smoker testing
machine based on
[CPAN::Reporter::Smoker](https://metacpan.org/pod/CPAN::Reporter::Smoker).

It provides CLI programs in order to do that:

* `dblock`: blocks a distribution to be tested in the smoker.

* `mirror_cleanup`: further removes spurious files from a local CPAN
mirror.

* `send_reports`: send local stored tests results to a running
[metabase-relayd](https://metacpan.org/pod/metabase-relayd) instance.

You can check each program online documentation by using `perldoc
dblock`, `perldoc mirror_cleanup` and `perldoc send_reports` after
installing this distribution.

## Setup

Setup is very easy and can be done straight from the CPAN shell:

```
$ cpan CPAN::Smoker::Utils
```
