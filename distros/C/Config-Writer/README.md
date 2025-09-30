# NAME

**Config::Writer** - a module to write configuration files
in an easy and safe way.

# DESCRIPTION

This module is intended to perform the next operations:

- safe temporary configuration file creation, ownership and
access mode setting;
- creation of backup file(-s) of the target configuration file;
- automatic cleanup of outdated or surplus backup files.

Now you are able to restore configuration file even if you
forgot to create a backup file before editing it!

# CAVEATS

- This module is written using \`signatures\` feature. As for me,
it makes code clearer. However, it requires perl 5.10+. All
more or less modern OSes has much more newer perl included, so
don't think it will be a problem.

# **SYNOPSIS**

    my $fh = Config::Writer->new('file.conf', {
        'workdir'     => '/usr/local/etc',
        'owner'       => 'nobody',
        'permissions' => 0640,
        'retain'      => 4
    });
    die "can not open file for writing" if $fh->error;
    $fh->sayf('# Configuration file created with %s', $0);
    $fh->close;

# **METHODS**

- **new(FILENAME, { OPTIONS })**

    Create new **Config::Writer** object as follows:

        my $fh = Config::Writer->new('file.conf', {
            'workdir'       => '/path/to/workdir',
            'retain'        => 3,
            'overwrite'     => 1,
            'extension'     => '-%+4Y-%m-%d',
            'owner'         => 'bird',
            'group'         => 'bird',
            'permissions'   => 0640
        });

    Configuration file to be created or replaced name can contain either absolute or
    relative path part. Path part handling is described in **workdir** option description
    below.

    New temporary file will be created on success and all write operations will be
    performed on this temporary file. On \`close\` method invocation existing configuration
    file can be moved to a backup file (see descrition of **overwrite** option below) and
    temporary file is renamed in place of the original configuration file.

    - **FILENAME**

        Configuration file to be created or replaced name. Can contain either absolute or
        relative path part. Path part handling is described in **workdir** option description below.

        New temporary file will be created on success and all write operations will be performed
        on this temporary file. On **close()** method invocation existing configuration file can
        be moved to a backup file (see descrition of **overwrite** option below) and temporary file
        is renamed in place of the original configuration file.

    - **format** = STRING

        Configuration file format. Currently unused.

    - **workdir** = STRING

        If filename contains absolute path, work directory is set to a **dirname(1)**
        implicitly regardless of whether **workdir** option is set or not.

        If **workdir** is not set, work directory defaults to **getcwd(3)**.

        If filename contains relative path, it is appended to a work directory name,
        provided either in **workdir** option or returned by **getcwd(3)**.

        Work directory existence check is performed. If work directory does not exist, \`undef\`
        is returned and error flag is set!

    - **retain** = INTEGER

        Quantity of configuration file backups to retain. Default is 0 - do not retain any.

    - **overwrite** = BOOLEAN

        Existing backup file will be either overwritten if the flag is set to true
        (overwrite = 1) or stayed untouched (overwrite = 0). E. g. if you choose to
        store single backup per day, you'll get either the latest configuration version
        before it being updated, or the configuration you've got at the beginning of the
        day.

        Default is 0.

    - **extension** = STRING

        Configuration file backup extension format as described in POSIX strftime function
        documentation. The new extension will replace original one, so the backup files
        should not be loaded even in case wildcards (e. g. '**\*.conf**') are used to include
        configuration from a several files. Existing backup files will either stay untouched
        or overwritten depending on **overwrite** flag value.

        Default is '-%Y-%m-%d'.

    - **owner** = STRING

        Configuration file owner name. If file owner can not be changed, error flag is set.

        Defaults to process EUID.

    - **group** = STRING

        Configuration file group name. If not provided, process EGID is used.

    - **permissions** = OCTAL

        Configuration file permissions in numeric format. Read **chmod(1)** manual for
        details.

        Default is 0600.

- **error()**

    Takes no arguments. Returns \`false\` if **Config::Writer** object is
    defined and \`error\` flag is not set and \`true\` otherwise.

- **say(STRING)**

    Is equivalent to **print()** method except that $/ is added to the end of the line.

- **sayf(STRING, ARRAY)**

    Is equivalent to **printf()** method except that $/ is added to the end of the format line.

- **print(STRING)**

    Prints STRING to temporary file as is.

- **printf(STRING, ARRAY)**

    Prints formatted string to the temporary file. See **printf(3)** for
    more details.

- **close()**

    When called:

    - closes temporary configuration file;
    - tries to rename target configuration file to a backup file (if \`retain\`
    option is non-zero);
    - tries to remove surplus (oldest) backup files (if \`retain\` option is non-zero); 
    - tries to rename temporary configuration file to a target name.

    If any errors occurs, \`error\` flag is set.

# **AUTHORS**

- Volodymyr Pidgornyi, vp&lt;at>dtel-ix.net;

# **CHANGELOG**

- **v0.0.4**

    \- Minor CPAN compatibility fixes;

    \- README.md is generated from Netbox/Config.pm now.

- **v0.0.3**

    PAUSE compatibility issues fixed.

- **v0.0.2**

    **sayf()** metrod added.

- **v0.0.1**

    Initial release, since basic features seems to work as intended.

# **TODO**

- Implement helpers for a different configuration files formats.
