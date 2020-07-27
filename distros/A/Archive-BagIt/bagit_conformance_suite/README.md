# BagIt Conformance Suite

This is a simple collection of BagIt format test cases for different implementations.

## Structure

* The top level of the repository contains directories for each version of the BagIt RFC, prefixed with "v"
* Each version directory should contain a directory named “valid” containing bag directories which must pass validation
  and "invalid" containing bag directories which must fail validation.
* It may also have the following optional directories:
  * a "warning" directory containing bags which are still valid but should produce a warning
  * a "linux-only" directory that has specific invalid tests that would only occur on a POSIX operating systems (tested on Linux)
  * a "windows-only" directory that has specific invalid tests that would only occur on Windows operating systems
* Each of the lower level directories should contain a human-meaningful name indicating the aspect being
  tested

## Running tests

If you have a bag validator which follows standard Unix convention, you can run all of the tests quickly using the provided test harness:

    python test-harness -v -- ~/Projects/bagit-python/bagit.py --validate --quiet

## Notes

* Git's `core.autocrlf` setting can cause bag validation failures by converting CRLF files automatically
  depending on your operating system and configuration. It is recommended that you disable it in your local
  checkout of this repository:

  `git config core.autocrlf false`

## License

This repository is released as a [public domain work of the U.S. Government](LICENSE.md).

Contributions are gladly accepted but must be released into the public domain.
