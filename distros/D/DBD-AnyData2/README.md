# NAME

DBD::AnyData2 - a DBI driver for AnyData2

# SYNOPSIS

    use DBI;
    $dbh = DBI->connect('dbi:AnyData2:');
    $dbh = DBI->connect('DBI:AnyData2(RaiseError=1):');

    # or
    $dbh = DBI->connect('dbi:AnyData2:', undef, undef);
    $dbh = DBI->connect('dbi:AnyData2:', undef, undef, {
      ...
    });

and other variations on connect() as shown in the [DBI](https://metacpan.org/pod/DBI) docs,
[DBI::DBD::SqlEngine metadata](https://metacpan.org/pod/DBI::DBD::SqlEngine#Metadata) and ["Metadata"](#metadata)
shown below.

Use standard DBI prepare, execute, fetch, placeholders, etc.,
see ["QUICK START"](#quick-start) for an example.

# DESCRIPTION

DBD::AnyData2 is a database management system that works right out of the
box.  If you have a standard installation of Perl and DBI you can begin
creating, accessing, and modifying simple database tables without any
further modules.

# QUICK START

...

# BUGS AND LIMITATIONS



# GETTING HELP, MAKING SUGGESTIONS, AND REPORTING BUGS

If you need help installing or using DBD::AnyData2, please write to the DBI
users mailing list at dbi-users@perl.org or to the
comp.lang.perl.modules newsgroup on usenet.  I cannot always answer
every question quickly but there are many on the mailing list or in
the newsgroup who can.

DBD developers for DBD's which rely on DBI::DBD::SqlEngine or DBD::AnyData2 or use
one of them as an example are suggested to join the DBI developers
mailing list at dbi-dev@perl.org and strongly encouraged to join our
IRC channel at [irc://irc.perl.org/dbi](irc://irc.perl.org/dbi).

If you have suggestions, ideas for improvements, or bugs to report, please
report a bug as described in DBI. Do not mail any of the authors directly,
you might not get an answer.

When reporting bugs, please send the output of $dbh->dbm\_versions($table)
for a table that exhibits the bug and as small a sample as you can make of
the code that produces the bug.  And of course, patches are welcome, too
:-).

If you need enhancements quickly, you can get commercial support as
described at [http://dbi.perl.org/support/](http://dbi.perl.org/support/) or you can contact Jens Rehsack
at rehsack@cpan.org for commercial support in Germany.

Please don't bother Jochen Wiedmann or Jeff Zucker for support - they
handed over further maintenance to H.Merijn Brand and Jens Rehsack.

# ACKNOWLEDGEMENTS

# AUTHOR AND COPYRIGHT

This module is written by Jens Rehsack < rehsack AT cpan.org >.

    Copyright (c) 2015 by Jens Rehsack, all rights reserved.

You may freely distribute and/or modify this module under the terms of
either the GNU General Public License (GPL) or the Artistic License, as
specified in the Perl README file.

# SEE ALSO

[DBI](https://metacpan.org/pod/DBI),
[SQL::Statement](https://metacpan.org/pod/SQL::Statement), [DBI::SQL::Nano](https://metacpan.org/pod/DBI::SQL::Nano)
