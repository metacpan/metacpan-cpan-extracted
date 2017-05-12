#!/usr/bin/perl
use warnings;
use strict;

=head1 NAME

upgrade.pl - upgrade the database for a S<Daizu 0.1> installation to work with S<Daizu 0.2>

=head1 DESCRIPTION

Run this once after you've installed the S<Daizu 0.2> code and made any
necessary changes to your content repository.

If this won't be able to find your Daizu configuration file automatically
you can provide it as an argument when you run this program.

Note that this needs to load all your articles, so it may take some time,
and may fail if any of your articles cause the article loader plugin to die.

All the database changes are made within a transaction, so any errors
should cause it all to be rolled back to how it started.

=cut

use Daizu;
use Daizu::Util qw( transactionally );

my $cms = Daizu->new(@ARGV);
my $db = $cms->db;

transactionally($db, sub {

print STDERR "Adding new tables and columns:\n";
print STDERR " * wc_file.no_index\n";
$db->do(q{
    alter table wc_file
    add column no_index boolean not null default false
});
print STDERR " * wc_file.short_title\n";
$db->do(q{
    alter table wc_file
    add column short_title text
});
print STDERR " * wc_file.root_file_id\n";
$db->do(q{
    alter table wc_file
    add column root_file_id int references wc_file on delete cascade
});
print STDERR " * wc_file.article_pages_url\n";
$db->do(q{
    alter table wc_file
    add column article_pages_url text
});
print STDERR " * wc_file.article_content\n";
$db->do(q{
    alter table wc_file
    add column article_content text
});
print STDERR " * wc_article_extra_url\n";
$db->do(q<
    create table wc_article_extra_url (
        file_id int not null references wc_file on delete cascade,
        url text not null,
        content_type text not null
            -- All ASCII characters allowed except 'tspecials' defined in RFC 2045.
            check (content_type similar to '[-!#$\\\\%&''*+.0-9A-Z^\\\\_`a-z{|}~]+/[-!#$\\\\%&''*+.0-9A-Z^\\\\_`a-z{|}~]+'),
        generator text not null
            check (generator similar to '[\\\\_a-zA-Z][-\\\\_:a-zA-Z0-9]*[\\\\_a-zA-Z0-9]'),
        method text not null
            check (method similar to '[\\\\_a-zA-Z0-9]+'),
        argument text not null default ''
    );
>);
print STDERR " * wc_article_extra_template\n";
$db->do(q{
    create table wc_article_extra_template (
        file_id int not null references wc_file on delete cascade,
        filename text not null
    );
});
print STDERR " * wc_article_included_files\n";
$db->do(q{
    create table wc_article_included_files (
        file_id int not null references wc_file on delete cascade,
        included_file_id int not null
            references wc_file deferrable initially deferred
    );
});

print STDERR "Rename wc_file.base_url to wc_file.custom_url.\n";
$db->do(q{
    alter table wc_file rename column base_url to custom_url
});


print STDERR "Adding missing 'generator' and 'root_file_id' values.\n";
{
    my $not_root_file;
    {
        my @root= $db->selectrow_array(q{
            select id
            from wc_file
            where generator is not null
        });
        $not_root_file = @root ? 'f.id not in (' . join(', ', @root) . ')'
                               : 'true';
    }

    # Top-level files and directories never have a root_file_id, because it
    # is necessarily the same file.  The get the default generator if one
    # hasn't been assigned already.
    my $update_sth = $db->prepare(q{
        update wc_file
        set generator = ?,
            root_file_id = ?
        where id = ?
    });

    my $sth = $db->prepare(qq{
        select id
        from wc_file
        where parent_id is null
          and generator is null 
        order by path
    });
    $sth->execute;

    while (my ($file_id) = $sth->fetchrow_array) {
        $update_sth->execute('Daizu::Gen', undef, $file_id);
    }

    my $file_id = undef;
    while (1) {
        my $where_parent_id = defined $file_id ? "parent_id = $file_id"
                                               : "parent_id is not null";
        my $sth = $db->prepare(qq{
            select f.id, parent.generator, parent.id, parent.root_file_id
            from wc_file f
            inner join wc_file parent on parent.id = f.parent_id
            where f.generator is null 
              and parent.generator is not null
              and $not_root_file
            order by f.path
        });
        $sth->execute;

        my $found;
        while (my ($file_id, $gen, $parent_id, $parent_root_id)
                = $sth->fetchrow_array)
        {
            die unless defined $parent_id;
            my $root_file_id = defined $parent_root_id ? $parent_root_id
                                                       : $parent_id;
            $update_sth->execute($gen, $root_file_id, $file_id);
            $found = 1;
        }

        last unless $found;
    }
}


print STDERR "Loading articles through plugins.  This may take some time.\n";
{
    my $sth = $db->prepare(q{
        select id
        from wc_file
        where article
        order by wc_id, path
    });
    $sth->execute;

    while (my ($file_id) = $sth->fetchrow_array) {
        my $file = Daizu::File->new($cms, $file_id);
        $file->update_loaded_article_in_db;
    }
}


print STDERR "Adding constraints:\n";
print STDERR " * wc_file.generator not null\n";
$db->do(q{
    alter table wc_file
    alter column generator set not null
});
print STDERR " * wc_file_article_loaded_chk\n";
$db->do(q{
    alter table wc_file
    add constraint wc_file_article_loaded_chk
        check ((article and article_content is not null and
                            article_pages_url is not null) or
               (not article and article_content is null and
                                article_pages_url is null))
});


print STDERR "Committing.\n";
});
print STDERR "Done.\n";

=head1 COPYRIGHT

This software is copyright 2006 Geoff Richards E<lt>geoff@laxan.comE<gt>.
For licensing information see this page:

L<http://www.daizucms.org/license/>

=cut

# vi:ts=4 sw=4 expandtab
