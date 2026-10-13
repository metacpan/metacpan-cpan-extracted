# perl_DBD-DB2

[![CPAN Version](https://img.shields.io/cpan/v/DBD-DB2.svg?style=flat-square)](https://metacpan.org/pod/DBD::DB2)
[![Perl Version](https://img.shields.io/badge/perl-5.8%2B-blue.svg?style=flat-square)](https://www.perl.org/)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg?style=flat-square)](LICENSE)
[![GitHub](https://img.shields.io/badge/github-ibmdb%2Fperl_DBD--DB2-blue.svg?style=flat-square)](https://github.com/ibmdb/perl_DBD-DB2)
[![Build Status](https://img.shields.io/badge/status-maintained-brightgreen.svg?style=flat-square)](https://github.com/ibmdb/perl_DBD-DB2)

Perl database interface for **IBM DB2 for z/OS**, **DB2 for Linux/Unix/Windows (LUW)**, and **DB2 for i (AS/400)**.

DBD::DB2 enables Perl applications to connect to, query, and interact with IBM DB2 databases. This repository provides both source code and pre-compiled Windows binaries (DLLs for ActivePerl and Strawberry Perl) to simplify installation and avoid compilation issues with the DB2 CLI Driver.

## Quick Start

> **Windows Users (Easiest):** Use pre-compiled binaries from the `Windows_Binary` folder  
> **CPAN Users:** Run `cpanm install DBD::DB2`  
> **Developers:** Build from source (see [Installation](#installation) section)

## Prerequisite

> **Perl** version 5.8 or later (tested up to 5.40)
> Confirm by typing in command prompt:
```
perl -v
```

> **DBI Module** version 1.21 or later (Perl Database Interface)
> Install with:
```
cpanm install DBI
```

> **IBM DB2 Application Development Client** version 7.2 or later
> - Included with DB2 Personal Developer's Edition and DB2 Universal Developer's Edition
> - Download from [IBM DB2 Support](http://www.ibm.com/software/data/db2/udb/support/)

## Installation

### Windows - Using Pre-Compiled Binaries (Recommended for Beginners)

> Pre-compiled DBD::DB2 DLLs are provided in the `Windows_Binary` folder to avoid compilation issues with the CLI Driver.

#### Steps:

1. **Locate your Perl installation:**
   ```cmd
   perl -v
   ```

2. **Download the appropriate binary from `Windows_Binary` folder:**
   - Choose folder matching your Perl distribution (ActivePerl or Strawberry Perl)
   - Select version matching your Perl version

3. **Copy files to Perl library directory:**
   ```cmd
   copy DB2.dll "C:\Perl\site\lib\auto\DBD\DB2\"
   copy DB2.pm  "C:\Perl\site\lib\DBD\"
   ```
   *(Adjust path based on your Perl installation)*

4. **Verify installation:**
   ```perl
   perl -e "use DBD::DB2; print qq{Success\n};"
   ```

### Windows - Building from Source

> **Prerequisites:** MSVC or MinGW C++ Compiler must be installed

1. Navigate to the repository directory:
   ```cmd
   cd path\to\perl_DBD-DB2
   ```

2. Run build commands:
   ```cmd
   perl Makefile.PL
   nmake
   nmake test
   nmake install
   ```

### Linux/Unix

1. **Set environment variables:**
   ```bash
   export DB2_HOME=<path-to-DB2-CLI-driver>/clidriver
   export PERL5LIB=~/lib/perl5:$DB2_HOME/perl:$HOME/DBD-DB2-<version>/tests:$HOME/DBD-DB2-<version>/Constants
   ```

2. **Build and install:**
   ```bash
   perl Makefile.PL
   make
   make test
   make install
   ```

#### For Non-Root Installation (Recommended):

```bash
perl Makefile.PL PREFIX=~/lib/perl5
make
make test
make install
```

### AIX

> **Prerequisites:** Perl 5.8+, DB2 CLI v10.5+, xlccmp 13.1.3+

1. **Extract required files to `/tmp/perl`:**
   ```bash
   mkdir -p /tmp/perl
   cd /tmp/perl
   # Extract: v10.5fp11_aix64_odbc_cli_32.tar, DBI-1.643.tar, DBD-DB2-<version>.tar
   ```

2. **Install DBI module:**
   ```bash
   cd DBI-1.643
   perl Makefile.PL
   make
   make test
   make install
   ```

3. **Install DBD::DB2:**
   ```bash
   cd ../DBD-DB2-<version>
   export DB2_HOME=/tmp/perl/odbc_cli_32/clidriver
   export PERL5LIB=/usr/opt/perl5/lib/site_perl/5.28.1/aix-thread-multi:$DB2_HOME/perl:$(pwd)/tests:$(pwd)/Constants
   
   perl Makefile.PL
   make
   make test
   make install
   ```

## Testing Your Installation

> Set `DB2_USER` and `DB2_PASSWD` as environment variables. Configuration can also be provided in `tests/connection.pl`.

### With Connection Configuration:

1. **Edit `tests/connection.pl`:**
   ```perl
   $USERID="your_db2_username";
   $PASSWORD="your_db2_password";
   $PORT=50000;
   $HOSTNAME="your_db_server";
   $DATABASE="your_database_name";
   $PROTOCOL="TCPIP";
   ```

2. **Run test suite:**
   ```bash
   perl run-tests.pl
   ```

### Quick Manual Test:

Create `test_db2.pl`:
```perl
#!/usr/bin/perl
use strict;
use warnings;
use DBI;

my $dbh = DBI->connect('dbi:DB2:database=SAMPLE', 'userid', 'password')
    or die "Connection failed: $DBI::errstr";

print "Connected successfully!\n";

my $sth = $dbh->prepare("SELECT * FROM SYSCAT.TABLES FETCH FIRST 5 ROWS ONLY");
$sth->execute() or die "Query failed: $DBI::errstr";

while (my $row = $sth->fetchrow_hashref()) {
    print "Table: ", $row->{TABNAME}, "\n";
}

$sth->finish();
$dbh->disconnect();
```

Run with:
```bash
perl test_db2.pl
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Can't find module DBD::DB2" | Ensure DBI is installed first: `cpanm install DBI` |
| "DB2_HOME not set" | Set environment variable pointing to DB2 CLI driver installation |
| Compilation errors with sqlext.h | Use pre-compiled Windows binaries instead of building from source |
| Permission denied during install | Run with `sudo` or use `PREFIX=~/lib/perl5` for user-level installation |
| Test connection fails | Verify credentials in `tests/connection.pl` and ensure DB2 server is running |

#### For More Information:

- **CAVEATS** - Platform-specific solutions and workarounds
- **TESTING_GUIDE.md** - Comprehensive testing procedures
- **TEST_GAP_ANALYSIS.md** - Test coverage details

## Support & Resources

### IBM Support
- **Technical Support:** IBM DB2 service agreements
- **DB2 Documentation:** [IBM DB2 Info Center](http://publib.boulder.ibm.com/infocenter/db2help/index.jsp)
- **DB2 Perl Resources:** [IBM DB2 Perl Page](http://www.software.ibm.com/data/db2/perl)

### Community - DBI Mailing Lists

| List | Purpose |
|------|---------|
| dbi-announce@perl.org | Announcements |
| dbi-dev@perl.org | Developer discussions |
| dbi-users@perl.org | User help & questions |

**Subscribe:** Send email to `<listname>-subscribe@perl.org` or visit [lists.perl.org](http://lists.perl.org/)

### GitHub Repository
- **Project:** [GitHub: perl_DBD-DB2](https://github.com/ibmdb/perl_DBD-DB2)
- **Report Issues:** Use GitHub Issues feature

## Documentation

| File | Content |
|------|---------|
| CAVEATS | Important platform-specific information and workarounds |
| DB2.pod | Example Perl scripts for using DBD::DB2 |

## License

DBD::DB2 is licensed under the [Apache License 2.0](LICENSE). Third-party components
retain their respective licenses, and Db2 client libraries are subject to their
own license terms.

---

**Last Updated:** February 2026

For latest information, visit: [GitHub Repository](https://github.com/ibmdb/perl_DBD-DB2)