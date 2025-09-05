# Non-containerized installation

### Method 1: From CPAN (Recommended)

First install system level dependencies:

```bash
sudo apt-get install gcc make cpanminus libperl-dev qrencode zbar-tools
```
We use `cpanm` to install the CPAN modules. We'll install the dependencies at `~/perl5`:

```bash
cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
cpanm --notest ClarID::Tools
clarid-tools --help
```

To ensure Perl recognizes your local modules every time you start a new terminal, you should type:

```bash
echo 'eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)' >> ~/.bashrc
```

To **update** to the newest version:

```bash
cpanm ClarID::Tools
```

### Method 2: Download from GitHub

First, we need to install a few system components:

```bash
sudo apt install gcc make git cpanminus libperl-dev qrencode zbar-tools
```

Use `git clone` to get the latest (stable) version:

```bash
git clone https://github.com/CNAG-Biomedical-Informatics/clarid-tools.git
cd clarid-tools
```

If you only new to update to the lastest version do:

```bash
git pull
```

We use `cpanm` to install the CPAN modules. We'll install the dependencies at `~/perl5`:

```bash
cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
cpanm --notest --installdeps .
bin/clarid-tools
```
Testing the deployment:

```bash
prove
```

To ensure Perl recognizes your local modules every time you start a new terminal, run:

```bash
echo 'eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)' >> ~/.bashrc
```

## System requirements

- OS/ARCH supported: **linux/amd64** and **linux/arm64**.
- Ideally a Debian-based distribution (Ubuntu or Mint), but any other (e.g., CentOS, OpenSUSE) should do as well (untested).
- Perl 5 (>= 5.36 core; installed by default in many Linux distributions). Check the version with `perl -v`
- 1GB of RAM
- \>= 1 core (ideally i7 or Xeon).
- At least 5GB HDD.

## Platform Compatibility
This distribution is written in pure Perl and is intended to run on any platform supported by Perl 5. It has been tested on Debian Linux and macOS. It is expected to work on Windows; please report any issues.

## Common errors: Symptoms and treatment

* Perl errors:
    - Foo

      Solution: 

      `Bar`
