perl-DBR CHANGE LOG
===

1.5 - Released 06/16/2011
---

  - Added perldoc to a few places. Documentation is still dismal, but improving.
  - Bugfix in dbr-config
  - Corrected inaccuracies in APP_SETUP.md

1.4 - Released 06/15/2011
---

  - Improved documentation ( still has a long way to go, admittedly )
  - added `dbr-config` script
    A utility to assist in configuring the DBR environment.
    Currently supports listing and updating schemas and instances
  - Fixed SQLite schema error

1.3 - Released 05/23/2011
---
  - consolidated test case and example schemas
  - created DBR::Sandbox to manage them
  - dramatically cleaned up / trimmed example scripts
  - hopefully fixed a minor issue causing cpantesters to fail

1.2 - Released 05/20/2011
---
  - merged commonref_rowcache
    Allows for read-ahead for record objects that are already retrieved.
    In past versions, read-ahead was only enabled if inside the while( $r = $rs->next ) loop
  - merged cross_schema_relationships
    Allows for relationships to be defined and used across schemas.
  - merged datetime_field
    For those who use the datetime data type, there is salvation
  - merged export_connect
    adds the use_exceptions flag on DBR->new
    also adds a new syntax for using DBR in your libraries:
    In your base class:

        use DBR (conf => '/path/to/conf_file.conf', app => 'myapp', logpath => '/path/to/logfile.log');

    Then elsewhere:

        use DBR ( app => 'myapp', use_exceptions => 1 ); 
        my $db = dbr_connect('schema-name');
        ...

1.1
---
  - resultset->count can now be trusted 
    It should always work now regardless of whether you have fetched any records or not.

  - Resultsets may now be refined
    The following syntax is now possible:

        my $items = $order->items->where( status => 'active' );

    This is infinately chainable, because you may now call ->where on any resultset to get a sub-resultset. In fact, the above example only initiates one query of the items table per chunk of 1,000 order records. This resulted from a major remodel of the relationship code to implement lazy execution at the time of the first ->next, rather than ->where.

  - Table inserts now enforce the non-null status on fields.
    Any inserts into a table with one or more non-null fields will require that you provide a values for them. The only downside is that it does not respect database enforced default values. Some discussion of this one may be required prior to the final release of 1.1 as this may actually break some production code.

  - New! Batshit crazy AND / OR logic
    DBR::Util::Operator now exports AND and OR subroutines, with evil syntactic sugaryness. There is zero documentation on this right now, but the following sort of logic is now possible:

        my $resultset = $dbrh->tablename->where(
                                        ( status => 'active' )
                                        OR
                                        (
                                          status  => 'retired',
                                          thingus => GT 1,
                                        )
                                       );

  - $dbrh->tablename->parse( somefield => 'somevalue' ) now works for all fields, regardless of whether they are translated fields or not.
  - Added many new test cases
  - Totally re-arranged most of the modules. The file tree is starting to make a little more sense now.
  - Reverted dependency on File::Path to 1.08, because centos5 is stupid and cannot upgrade File::Path without totally repackaging perl itself.
  - Regex enforcement is now available on all fields through the dbr metadata. ( admin tool does not yet support this )


HERE BE DRAGONS
