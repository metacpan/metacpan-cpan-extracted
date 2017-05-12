mydbmunger - a MySQL/MariaDB Database Design Tool
=================================================

    Usage: mydbmunger [OPTIONS] COMMAND SCHEMA
    
    Available COMMANDs are "pull", "push", and "make-archive"
    
      pull
             Connect to database and pull down current table definitions and
             trigger definitions.
      push
             Connect to database and deploy current table definitions by creating
             or modifying tables.
    
      make-archive
             Write trigger and archive table definitions.
    
    GENERAL OPTIONS:
      -d, --dryrun        Don't commit any changes, just print SQL that would be
                          executed.
      -D, --dir=PATH      Directory in which to read and write database information.
                          Default is current directory.
      -h, --host=name     Connect to host.
          --no-tables     Don't do anything with triggers.
          --no-triggers   Don't do anything with triggers.
      -p, --password[=PASSWORD] 
                          Password to use when connecting to server. If password is
                          not provided on the command line it will asked from the
                          tty.
      -P, --port=#        Port number to use for connection or 0 for default to, in
                          order of preference, my.cnf, \$MYSQL_TCP_PORT,
                          /etc/services, built-in default (3306).
      -t, --table=TABLE[,TABLE]...
                          Specify for which tables to perform the given COMMAND. If
                          not provided, then we will attempt to detect suitable
                          tables automatically.
      -u, --user=NAME     User for login if not current user.
      -v, --verbose       Show verbose messages.
    
    OPTIONS FOR COMMAND pull:
          --init-trigger-name=NAME
                          Name to use for any unlabeled trigger fragments. Without
                          this option, unlabeled fragments are treated as an
                          error.
                          
    
    OPTIONS FOR COMMAND make-archive:
          --actioncol=COLUMN
                          Column name used in archive table to store the SQL
                          type of SQL action caused the archive to be created.
                          Default: "action"
          --ctime[=COLUMN]
                          Column name used in the source data and archive tables
                          used to track record creation time. This must be a
                          TIMESTAMP or DATETIME data type. If option this option
                          is given without a vaulue then the column name "ctime"
                          will be used. Default is no creation time handling.
          --dbusercol=COLUMN
                          Column name to be used in archive table to store the
                          database connection login information. Default: "user"
          --archive-name-pattern=s
                          How to name archive tables. Specified as a pattern with
                          a placeholder "%" for the original table name. Default:
                          "%Archive", so by a table named "Post" would have a
                          archive table named "PostArchive".
          --mtime[=COLUMN]
                          Column name used in the source data and archive tables
                          used to track last-modification time. This must be a
                          TIMESTAMP or DATETIME data type. If option this option
                          is given without a vaulue then the column name "mtime"
                          will be used. Default is no modification time handling.
          --revision=COLUMN
                          Column name used in the source data and archive tables
                          to track revision count. Default: "revision"
          --stmtcol=COLUMN
                          Column name used in the archive table to record the SQL
                          query that initiated the table change.
          --updidcol=COLUMN
                          Column name used in archive table to store the
                          application user retrieved from the value of the
                          variable named by option --updidvar. Default: "\@updid"
          --updidvar=VARNAME
                          Variable name used to store an application user and to
                          store in the column designated by --updidcol.

