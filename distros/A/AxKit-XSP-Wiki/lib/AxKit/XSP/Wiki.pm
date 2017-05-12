package AxKit::XSP::Wiki;

use strict;

#use Apache::AxKit::Language::XSP::TaglibHelper;
use AxKit::XSP::Wiki::Indexer;
use Net::SMTP;
use Text::Diff;
use POSIX qw(strftime);
use vars qw($VERSION $NS @ISA @EXPORT_TAGLIB $EmailAlerts $EmailHost);

$VERSION = '0.07';

# The namespace associated with this taglib.
$NS = 'http://axkit.org/NS/xsp/wiki/1';
# Using TaglibHelper:
@ISA = qw(Apache::AxKit::Language::XSP::TaglibHelper);

@EXPORT_TAGLIB = (
    'display_page($dbpath,$db,$page,$action;$id):as_xml=1',
    'preview_page($dbpath,$db,$page,$text,$texttype):as_xml=1',
    'search($dbpath,$db,$query):as_xml=1',
);

use DBI;
use XML::SAX::Writer;
use Pod::SAX;
use XML::LibXML::SAX::Parser;
use Text::WikiFormat::SAX;

sub _mkdb {
    my ($dbpath, $dbname) = @_;
    my $db = DBI->connect(
        'DBI:SQLite:dbname='. $dbpath . '/wiki-' . $dbname . '.db',
        '', '', { AutoCommit => 1, RaiseError => 1 }
    );
    
    eval {
        $db->do('select * from Page, Formatter, History where 1 = 2');
    };
    if ($@) {
        create_db($db);
    }
    
    return $db;
}

sub display_page ($$$$$) {
    my ($dbpath, $dbname, $page, $action, $id) = @_;
    
    my $db = _mkdb($dbpath, $dbname);
    
    if ($action eq 'edit') {
        return edit_page($db, $page);
    }
    elsif ($action eq 'history') {
        return show_history($db, $page);
    }
    elsif ($action eq 'historypage') {
        return show_history_page($db, $page, $id);
    }
    if ($action eq 'view') {
        return view_page($db, $page);
    }
    else {
        warn("Unrecognised action. Falling back to 'view'");
        return view_page($db, $page);
    }
}

sub preview_page ($$$$$) {
    my ($dbpath, $dbname, $page, $text, $texttype) = @_;
    my $db = _mkdb($dbpath, $dbname);
    my $sth = $db->prepare(<<'EOT');
  SELECT Formatter.module
  FROM Formatter
  WHERE Formatter.id = ?
EOT
    $sth->execute($texttype);
    
    my $output = '';
    my $handler = XML::SAX::Writer->new(Output => \$output);
    while ( my $row = $sth->fetch ) {
        # create the parser
        my $parser = $row->[0]->new(Handler => $handler);
        eval {
            $parser->parse_string($text);
        };
        if ($@) {
            $output = '<pod>
  <para>
    Error parsing the page: ' . xml_escape($@) . '
  </para>
</pod>
  ';
        }
        last;
    }
    if (!$output) {
        $output = <<'EOT';
<pod>
  <para>
Eek.
  </para>
</pod>
EOT
    }

    $output =~ s/^<\?xml\s.*?\?>//s;

    # Now add edit stuff
    $output .= '<edit><text>';
    $output .= xml_escape($text);
    $output .= '</text><texttypes>';
    
    $sth = $db->prepare(<<'EOT');
  SELECT Formatter.id, Formatter.name
  FROM Formatter
EOT
    $sth->execute();
    while (my $row = $sth->fetch) {
        $output .= '<texttype id="'. xml_escape($row->[0]) . 
          ($texttype == $row->[0] ? '" selected="selected">' : '">') . 
          xml_escape($row->[1]) . '</texttype>';
    }
    $sth->finish;
    
    $output .= '</texttypes></edit>';

    return $output;
} # preview

sub view_page {
    my ($db, $page) = @_;
    my $sth = $db->prepare(<<'EOT');
  SELECT Page.content, Formatter.module
  FROM Page, Formatter
  WHERE Page.formatterid = Formatter.id
  AND   Page.name = ?
EOT
    $sth->execute($page);
    
    my $output = '';
    my $handler = XML::SAX::Writer->new(Output => \$output);
    while ( my $row = $sth->fetch ) {
        # create the parser
        my $parser = $row->[1]->new(Handler => $handler);
        eval {
            $parser->parse_string($row->[0]);
        };
        if ($@) {
            $output = '<pod>
  <para>
    Error parsing the page: ' . xml_escape($@) . '
  </para>
</pod>
  ';
        }
        last;
    }
    if (!$output) {
        $output = <<'EOT';
<newpage/>
EOT
    }
    $output =~ s/^<\?xml\s.*?\?>//s;
    AxKit::Debug(10, "Wiki Got: $output") if $ENV{MOD_PERL};
    return $output;
}

sub xml_escape {
    my $text = shift;
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/]]>/]]&gt;/g;
    return $text;
}

sub get_default_formatter {
    my ($db) = @_;
    my $sth = $db->prepare("SELECT id FROM Formatter WHERE name LIKE ?");
    $sth->execute("pod%");
    while (my $row = $sth->fetch) {
        return $row->[0];
    }
    die "No rows from Formatter table!";
}

sub edit_page {
    my ($db, $page) = @_;
    my $sth = $db->prepare(<<'EOT');
  SELECT Page.content, Page.formatterid
  FROM Page
  WHERE Page.name = ?
EOT
    $sth->execute($page);
    
    my $output = '<edit><text>';
    my $formatter = get_default_formatter($db);
    while ( my $row = $sth->fetch ) {
        # create the parser
        $output .= xml_escape($row->[0]);
        $formatter = $row->[1];
        last;
    }
    $sth->finish;
    
    $output .= '</text><texttypes>';
    
    $sth = $db->prepare(<<'EOT');
  SELECT Formatter.id, Formatter.name
  FROM Formatter
EOT
    $sth->execute();
    while (my $row = $sth->fetch) {
        $output .= '<texttype id="'. xml_escape($row->[0]) . 
          ($formatter == $row->[0] ? '" selected="selected">' : '">') . 
          xml_escape($row->[1]) . '</texttype>';
    }
    $sth->finish;
    
    $output .= '</texttypes></edit>';
    return $output;
}

sub search {
    my ($dbpath, $dbname, $query) = @_;
    my $db = _mkdb($dbpath, $dbname);
    my %search = parse_search($query);
    use Data::Dumper; warn(Dumper(\%search));
    my $results = search_message_index( db => $db,
                                        required => $search{required},
                                        normal => $search{normal},
                                        phrase => $search{phrase},
                                        excluded => $search{excluded},
                                      );
    my $output = '<search-results>';
    if (!@{$results}) {
        $output .= '<no-results/>';
    }
    foreach my $row (sort { $b->[1] <=> $a->[1] } @{$results}) {
        $output .= "<result><page>" . xml_escape($row->[0]) . "</page>";
        $output .= "<rank>" . xml_escape($row->[1]) . "</rank></result>";
    }
    $output .= "</search-results>";
    warn("Search results: $output\n");
    return $output;
}

sub search_message_index {
    my %p = @_;
    
    my $db = $p{db};
    
    # Excluded words are excluded from all pages
    my $exclude = '';
    if ( @{$p{excluded}} ) {
        $exclude .= "  AND Page.name NOT IN (
            SELECT DISTINCT Page.name
            FROM Page, ContentIndex, Word
            WHERE ContentIndex.page_id = Page.id
              AND ContentIndex.word_id = Word.id
              AND Word.word IN (" .
                    join(',', map { $db->quote($_) } @{$p{excluded}}) .
                    ")
                )\n";
    }

    my $sql = "
SELECT Page.name, SUM(ContentIndex.value) AS value
FROM ContentIndex, Page, Word
WHERE ContentIndex.page_id = Page.id
  AND ContentIndex.word_id = Word.id
  AND (" . 
        join(" OR ", (
            (map { "Word.word = " . $db->quote($_) } @{$p{required}}),
            (map { "Page.content LIKE " . $db->quote("\%$_\%") } @{$p{phrase}}),
        )) .
        ")
$exclude
GROUP BY ContentIndex.page_id
";
    warn("Getting required with:\n$sql\n");
    return $db->selectall_arrayref($sql);
}



sub parse_search {
    my $query = shift;
    my %search;
    while (defined $query && $query =~ /\G(\S*)(\s*)/gc) {
        my $term = $1;
        my $space = $2;
        next unless length($term);

        $term = lc($term);
        
        if ($term =~ s/^\+//) {
            $search{required}{$term}++;
            warn "Search required: $term\n";
        }
        elsif ($term =~ s/^\-//) {
            $search{excluded}{$term}++;
            warn "Search excluded: $term\n";
        }
        elsif ($term =~ /^(["'])/) {
            my $quote = $1;
            $term =~ s/^$quote//;
            $term .= $space;

            if ($query =~ /\G(.*?)\.?$quote\s*/gc) {
                $term .= $1;
                $search{phrase}{$term}++;
                warn "Search phrase: $term\n";
            }
        }
        else {
            $search{required}{$term}++;
            warn "Search normal: $term\n";
        }
    }

    # turn into arrayrefs
    foreach ( qw( normal required excluded phrase ) )
    {
        if ( $search{$_} )
        {
            $search{$_} = [ keys %{ $search{$_} } ]
        }
        else
        {
            $search{$_} = [];
        }
    }

    return %search;
}

sub save_page {
    my ($dbpath, $dbname, $page, $contents, $texttype, $ip, $user) = @_;
    my $db = _mkdb($dbpath, $dbname);
    _save_page($db, $page, $contents, $texttype, $ip, $user);
}

sub _save_page {
    my ($db, $page, $contents, $texttype, $ip, $user) = @_;
    # NB fix hard coded formatterid
    my $last_modified = time;
    my @history = $db->selectrow_array('SELECT content FROM History WHERE name = ? ORDER BY modified DESC', {}, $page);
    local $db->{AutoCommit} = 0;
    $db->do(<<'EOT', {}, $page, $texttype, $contents, $last_modified, $ip, $user);
  INSERT OR REPLACE INTO Page ( name, formatterid, content, last_modified, ip_address, username )
  VALUES ( ?, ?, ?, ?, ?, ? )
EOT
    $db->do(<<'EOT', {}, $page, $texttype, $contents, $last_modified, $ip, $user);
  INSERT INTO History ( name, formatterid, content, modified, ip_address, username )
  VALUES ( ?, ?, ?, ?, ?, ? )
EOT
    $db->commit;
    _index_page($db, $page);
    if ($EmailAlerts) {
        # create diff using Text::Diff
        my $prev = @history ? $history[0] : '';
        my $diff = diff(\$prev, \$contents, { STYLE => 'Unified' });
        
        my $host = $EmailHost || 'localhost';
        my $smtp = Net::SMTP->new($host, Timeout => 10);
        $smtp->mail('axkitwiki') || die "Wiki email alerts: MAIL FROM:<axkitwiki> failed";
        $smtp->to($EmailAlerts) || die "Wiki email alerts: RCPT TO:<$EmailAlerts> failed";
        $smtp->data() || die "Wiki email alerts: DATA failed";
        my $date = strftime('%a, %d %b %Y %H:%M:%S %Z', localtime);
        
        my $changed_by = $user ? "$user @ $ip" : "someone at IP $ip";
        $smtp->datasend(<<"EOT");
To: $EmailAlerts
From: "AxKit Wiki" <axkitwiki>
Subject: New Wiki Content at $page
Date: $date

Wiki content at $page Changed by $changed_by :

$diff

EOT
        $smtp->dataend();
        $smtp->quit();
    }
}

sub _index_page {
    my ($db, $page) = @_;
    my $sth = $db->prepare(<<'EOT');
  SELECT Page.id, Page.content, Formatter.module
  FROM Page, Formatter
  WHERE Page.formatterid = Formatter.id
  AND   Page.name = ?
EOT
    $sth->execute($page);
    
    my $output = '';
    while ( my $row = $sth->fetch ) {
        my $handler = AxKit::XSP::Wiki::Indexer->new(DB => $db, PageId => $row->[0]);
        # create the parser
        my $parser = $row->[2]->new(Handler => $handler);
        eval {
            $parser->parse_string($row->[1]);
        };
        if ($@) {
            warn("Indexing failed");
        }
        last;
    }
}

sub show_history {
    my ($db, $page) = @_;
    my $sth = $page ? $db->prepare('SELECT * FROM History WHERE name = ? ORDER BY modified DESC LIMIT 50') :
                      $db->prepare('SELECT * FROM History ORDER BY modified DESC LIMIT 50');
    $sth->execute($page);
    my $hist = '<history>';
    my %h;
    my $cols = $sth->{NAME_lc};
    while (my $row = $sth->fetch) {
        @h{@$cols} = @$row;
        $hist .= '<entry>';
        $hist .= '<page>' . xml_escape($h{name}) . '</page>';
        $hist .= '<id>' . xml_escape($h{id}) . '</id>';
        $hist .= '<modified>' . xml_escape(scalar gmtime($h{modified})) . '</modified>';
        $hist .= '<ip-address>' . xml_escape($h{ip_address}) . '</ip-address>';
        $hist .= '<username>' . xml_escape($h{username}) . '</username>';
        $hist .= '<bytes>' . xml_escape(length($h{content})) . '</bytes>';
        $hist .= '</entry>';
    }
    $hist .= '</history>';
    return $hist;
}

sub show_history_page {
    my ($db, $page, $id) = @_;
    my $sth = $db->prepare(<<'EOT');
  SELECT History.content, Formatter.module,
         History.ip_address, History.modified
  FROM History, Formatter
  WHERE History.formatterid = Formatter.id
  AND   History.name = ?
  AND   History.id = ?
EOT
    $sth->execute($page, $id);
    
    my $output = '';
    my $handler = XML::SAX::Writer->new(Output => \$output);
    my ($ip, $modified);
    while ( my $row = $sth->fetch ) {
        ($ip, $modified) = ($row->[2], scalar(gmtime($row->[3])));
        # create the parser
        my $parser = $row->[1]->new(Handler => $handler);
        eval {
            $parser->parse_string($row->[0]);
        };
        if ($@) {
            $output = '<pod>
  <para>
    Error parsing the page: ' . xml_escape($@) . '
  </para>
</pod>
  ';
        }
        last;
    }
    if (!$output) {
        $output = <<'EOT';
<pod>
  <para>
Unable to find that history page, or unable to find formatter module
  </para>
</pod>
EOT
    }
    $output =~ s/^<\?xml\s.*?\?>\s*//s;
    $output = "<?ip-address " . xml_escape($ip) . "?>\n" .
              "<?modified " . xml_escape($modified) . "?>\n" .
              $output;
    return $output;
}

sub restore_page {
    my ($dbpath, $dbname, $page, $ip, $id, $user) = @_;
    
    my $db = _mkdb($dbpath, $dbname);
    my $sth = $db->prepare('SELECT * FROM History WHERE name = ? and id = ?');
    $sth->execute($page, $id);
    my $row = $sth->fetch;
    die "No such row" unless $row;
    $sth->finish;
    my ($texttype, $contents) = ($row->[2], $row->[3]);
    _save_page($db, $page, $contents, $texttype, $ip, $user);
}

sub create_db {
    my ($db) = @_;
    
    $db->do(q{
        create table Page ( 
                           id INTEGER PRIMARY KEY,
                           name NOT NULL,
                           formatterid NOT NULL,
                           content,
                           last_modified,
                           ip_address,
                           username
                           )
    });
    $db->do(q{
        create unique index Page_name on Page ( name )
             });
    $db->do(q{
        create table History (
                              id INTEGER PRIMARY KEY, 
                              name NOT NULL, 
                              formatterid NOT NULL,
                              content,
                              modified,
                              ip_address,
                              username
                             )
    });
    $db->do(q{
        CREATE TABLE IgnoreWord 
        (
         id INTEGER PRIMARY KEY,
         word NOT NULL
        )
    });
    $db->do(q{CREATE UNIQUE INDEX IgnoreWord_word on IgnoreWord (word)});
    $db->do(q{
        CREATE TABLE Word 
        (
         id INTEGER PRIMARY KEY,
         word NOT NULL
        )
    });
    $db->do(q{CREATE UNIQUE INDEX Word_word on Word (word)});
    $db->do(q{
        CREATE TABLE ContentIndex
        (
         page_id     INTEGER             NOT NULL,
         word_id     INTEGER             NOT NULL,
         value       INTEGER             NOT NULL
        )
    });
    $db->do(q{
        create unique index ContentIndex_idx on ContentIndex (page_id, word_id)
    });
    $db->do(q{
        create table Formatter ( id INTEGER PRIMARY KEY, module NOT NULL, name NOT NULL)
             });
    $db->do(q{
        insert into Formatter (module, name) values ('Pod::SAX', 'pod - plain old documentation')
             });
    $db->do(q{
        insert into Formatter (module, name) values ('Text::WikiFormat::SAX', 'wiki text')
             });
    $db->do(q{
        insert into Formatter (module, name) values ('XML::LibXML::SAX::Parser', 'xml (freeform)')
             });
    $db->commit;
}

sub extract_page_info {
    my ($path_info) = @_;
    $path_info =~ s/^\///;
    my ($db, $page) = split("/", $path_info, 2);
    $page ||= ''; # can't have page named 0. Ah well.

    if (!$db) {
      return ('', '');
    }
    elsif ($db !~ /^[A-Z][A-Za-z0-9:_-]+$/) {
      die "Invalid db name: $db";
    }
    elsif (length($page) && $page !~ /^[A-Z][A-Za-z0-9:_-]+$/) {
      die "Invalid page name: $page";
    }
    return ($db, $page);
}

1;

__END__

=head1 NAME

AxKit::XSP::Wiki - An AxKit XSP based Wiki clone

=head1 SYNOPSIS

Follow the instructions in README for installation

=head1 DESCRIPTION

There's not much to say about Wiki's. They're kind cool, writable web sites.

This module implements a wiki that uses (at the moment) POD for it's
editing language.

At the moment there's no version control, user management, search, recent
edits, or pretty much any of the normally expected Wiki-type stuff. But it
will come, eventually.

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

=head1 LICENSE

This is free software. You may use it and redistribute it under the same
terms as perl itself.

=cut
