NAME
    DBD::Multi - Manage Multiple Data Sources with Failover and Load
    Balancing

SYNOPSIS
      use DBI;

      my $dbh = DBI->connect( 'dbi:Multi:', undef, undef, {
          dsns => [ # in priority order
              10 => [ 'dbi:SQLite:read_one.db', '', '' ],
              10 => [ 'dbi:SQLite:read_two.db', '', '' ],
              20 => [ 'dbi:SQLite:master.db',   '', '' ],
          ],
          # optional
          failed_max    => 1,     # short credibility
          failed_expire => 60*60, # long memory
      });

DESCRIPTION
    This software manages multiple database connections for the purposes of
    load balancing and simple failover procedures. It acts as a proxy
    between your code and your available databases.

    Although there is some code intended for read/write operations, this
    should be considered EXPIREMENTAL. This module is primary intended for
    read-only operations (where some other application is being used to
    handle replication).

    The interface is nearly the same as other DBI drivers with one notable
    exception.

  Configuring DSNs
    Specify an attribute to the "connect()" constructor, "dsns". This is a
    list of DSNs to configure. The configuration is given in pairs. First
    comes the priority of the DSN, lowest is tried first. Second is the DSN.

    The second parameter can either be a DBI object or a list of parameters
    to pass to the DBI "connect()" instructor.

  Configuring Failures
    By default a data source will not be tried again after it has failed
    three times. After five minutes that failure status will be removed and
    the data source may be tried again for future requests.

    To change the maximum number of failures allowed before a data source is
    deemed failed, set the "failed_max" parameter. To change the amount of
    time we remember a data source as being failed, set the "failed_expire"
    parameter in seconds.

SEE ALSO
    DBD::Multiplex, DBI, perl.

AUTHOR
    Initially written by Casey West and Dan Wright for pair Networks, Inc. (www.pair.com)

    Maintained by Dan Wright for pair Networks, Inc. <DWRIGHT@CPAN.ORG>.

