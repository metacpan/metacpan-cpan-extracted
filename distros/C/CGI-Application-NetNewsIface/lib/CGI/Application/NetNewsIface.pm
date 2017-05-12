package CGI::Application::NetNewsIface;

use strict;
use warnings;

use 5.008;

=head1 NAME

CGI::Application::NetNewsIface - a publicly-accessible read-only interface
for Usenet (NNTP) news.

=head1 SYNOPSIS

In a common module:

    use CGI::Application::NetNewsIface;

    sub get_app
    {
        return CGI::Application::NetNewsIface->new(
            PARAMS => {
                'nntp_server' => "nntp.perl.org",
                'articles_per_page' => 10,
                'dsn' => "dbi:SQLite:dbname=./data/mynntp.sqlite",
            }
        );
    }

To set up:

    get_app()->init_cache__sqlite();

To run

    get_app()->run();

=cut

use base 'CGI::Application';
use base 'Class::Accessor';

use CGI::Application::Plugin::TT;

use XML::RSS;

use Net::NNTP;

use CGI::Application::NetNewsIface::ConfigData;

use CGI::Application::NetNewsIface::Cache::DBI;

use vars qw($VERSION);

$VERSION = "0.0203";

use CGI;

my %modes =
(
    'main' =>
    {
        'url' => "/",
        'func' => "_main_page",
    },
    'groups_list' =>
    {
        'url' => "/group/",
        'func' => "_groups_list_page",
    },
    'group_display' =>
    {
        'url' => "/group/foo.bar/",
        'func' => "_group_display_page",
    },
    'article_display' =>
    {
        'url' => "/group/foo.bar/666",
        'func' => "_article_display_page",
    },
    'css' =>
    {
        'url' => "/style.css",
        'func' => "_css",
    },
    'about_app' =>
    {
        'url' => "/cgi-app-nni/",
        'func' => "_about_app_page",
    }
);

my %urls_to_modes = (map { $modes{$_}->{'url'} => $_ } keys(%modes));

__PACKAGE__->mk_accessors(qw(
    config
    record_tt
));

=head1 PARAMS

=head2 nntp_server

The Server to which to connect using NNTP.

=head2 articles_per_page

The number of articles to display per page of listing of a newsgroup.

=head2 dsn

The DBI 'dsn' for the cache.

=head1 FUNCTIONS

=head2 $cgiapp->setup()

The setup subroutine as required by CGI::Application.

=cut

sub setup
{
    my $self = shift;

    $self->_initialize($self->param('config'));

    $self->start_mode("main");
    $self->mode_param(\&_determine_mode);

    $self->run_modes(
        (map { $_ => $modes{$_}->{'func'}, } keys(%modes)),
        # Remmed out:
        # I think of deprecating it because there's not much difference
        # between it and add.
        # "add_form" => "add_form",
        'redirect_to_main' => "_redirect_to_main",
        'correct_path' => "_correct_path",
    );
}

sub cgiapp_prerun
{
    my $self = shift;

    $self->tt_params(
        'path_to_root' => $self->_get_path_to_root(),
        'show_all_records_url' => "search/?all=1",
    );

    # TODO : There may be a more efficient/faster way to do it, but I'm
    # anxious to get it to work. -- Shlomi Fish
    $self->tt_include_path(
        [ './templates',
          @{CGI::Application::NetNewsIface::ConfigData->config('templates_install_path')},
        ],
    );

    # This is so the CGI header won't print a character set.
    $self->query()->charset('');
}

=head2 cgiapp_prerun()

This is the cgiapp_prerun() subroutine.

=cut

sub _redirect_to_main
{
    my $self = shift;

    return "<html><body><h1>URL Not Found</h1></body></html>";
}

sub _correct_path
{
    my $self = shift;

    my $path = $self->_get_path();

    $path =~ m#([^/]+)/*$#;

    my $last_component = $1;

    # This is in case we were passed the script name without a trailing /
    # in which case the last component would be undefined. So consult
    # the request uri.
    if (!defined($last_component))
    {
        # Extract the Request URI
        my $request_uri = $ENV{REQUEST_URI} || "";
        $request_uri =~ m#([^/]+)/*$#;
        $last_component = $1;
        if (!defined($last_component))
        {
            $last_component = "";
        }
    }

    $self->header_type('redirect');
    $self->header_props(-url => "./$last_component/");
}

sub _get_path
{
    my $self = shift;

    my $q = $self->query();

    my $path = $q->path_info();

    return $path;
}

sub _determine_mode
{
    my $self = shift;

    my $path = $self->_get_path();

    if ($path =~ /\/\/$/)
    {
        return "correct_path";
    }

    if ($path eq "/")
    {
        return "main";
    }
    if ($path eq "/style.css")
    {
        return "css";
    }
    elsif ($path eq "/cgi-app-nni/")
    {
        return "about_app";
    }
    elsif ($path =~ s{^/group/}{})
    {
        if ($path eq "")
        {
            return "groups_list";
        }
        elsif ($path =~ s{^([[:lower:][:digit:]\.]+)/}{})
        {
            my $group = $1;
            $self->param('group' => $group);
            if ($path eq "")
            {
                return "group_display";
            }
            else
            {
                if ($path =~ s{^(\d+)$}{})
                {
                    $self->param('article' => $1);
                    return "article_display";
                }
                else
                {
                    return "correct_path";
                }
            }
        }
    }
    else
    {
        return "redirect_to_main";
    }
}

sub _initialize
{
	my $self = shift;

    my $config = shift;
	$self->config($config);

    my $tt = Template->new(
        {
            'BLOCKS' =>
                {
                    'main' => $config->{'record_template'},
                },
        },
    );

    $self->record_tt($tt);

	return 0;
}

sub _remove_leading_slash
{
    my ($self, $string) = @_;
    $string =~ s{^/}{};
    return $string;
}

sub _get_path_wo_leading_slash
{
    my $self = shift;
    return $self->_remove_leading_slash($self->_get_path());
}

sub _get_rel_url_to_root
{
    my ($self, $string) = @_;
    return join("", (map { "../" } split(/\//, $string)));
}

sub _get_path_to_root
{
    my $self = shift;

    return $self->_get_rel_url_to_root($self->_get_path_wo_leading_slash());
}

sub _main_page
{
    my $self = shift;

    return $self->tt_process(
        'main_page.tt',
        {
            'path_to_root' => $self->_get_path_to_root(),
            'title' => "Web Interface to the News Server",
            'nntp_server' => $self->param('nntp_server'),
        },
    );
}

sub _about_app_page
{
    my $self = shift;

    return $self->tt_process(
        'about_app_page.tt',
        {
            'title' => "About CGI-Application-NetNewsIface",
            'path_to_root' => $self->_get_path_to_root(),
        },
    );
}

sub _get_nntp
{
    my $self = shift;
    return Net::NNTP->new($self->param('nntp_server'));
}

sub _groups_list_page
{
    my $self = shift;

    my $nntp = $self->_get_nntp();

    my $groups = $nntp->list();

    $nntp->quit();

    return $self->tt_process(
        'groups_list_page.tt',
        {
            'groups' => [ sort { $a cmp $b } keys(%$groups) ],
            'title' => "Groups' List",
        }
    );
}

sub _get_group_display_article_data
{
    my ($self, $nntp, $index) = @_;

    my $head = $nntp->head($index);
    my $body = $nntp->body($index);
    my $subject;
    my $author;
    my $date;
    foreach my $line (@$head)
    {
        if ($line =~ m{^Subject: (.*)\n$})
        {
            $subject = $1;
        }
        elsif ($line =~ m{^From: (.*)\n$})
        {
            $author = $1;
        }
        elsif ($line =~ m{^Date: (.*)\n$})
        {
            $date = $1;
        }
    }
    return
    {
        'idx' => $index,
        'subject' => $subject,
        'author' => $author,
        'date' => $date,
        'lines' => scalar(@$body),
    };
}

sub _group_display_page
{
    my $self = shift;

    my $group = $self->param('group');

    my $nntp = $self->_get_nntp();

    my @info = $nntp->group($group);

    if (! @info)
    {
        $nntp->quit();
        return "<html><body><h1>Error! Unknown Group.</h1></body></html>";
    }

    my ($num_articles, $first_article, $last_article, $group_name) = @info;

    my $max_article = $self->query()->param('max') || $last_article;

    if ($max_article < $first_article)
    {
        $max_article = $first_article;
    }
    elsif ($max_article > $last_article)
    {
        $max_article = $last_article;
    }

    my $min_article = $max_article - $self->param('articles_per_page') + 1;

    if ($min_article < $first_article)
    {
        $min_article = $first_article;
    }

    # TODO
    # Is it possible that article numbers won't be consecutive? How should
    # we deal with it?
    my @articles =
        (map
            { $self->_get_group_display_article_data($nntp, $_) }
            ($min_article .. $max_article)
        );
    $nntp->quit();

    return $self->tt_process(
        'group_display_page.tt',
        {
            'group' => $group,
            'title' => "Articles for Group $group",
            'articles' => [reverse(@articles)],
            'nntp_server' => $self->param('nntp_server'),
            'max_art' => $max_article,
            'min_art' => $min_article,
            'num_arts' => $num_articles,
            'last_art' => $last_article,
            'arts_per_page' => $self->param('articles_per_page'),
        }
    );
}

sub _get_show_headers
{
    my $self = shift;
    return scalar($self->query()->param("show_headers"));
}

sub _get_headers
{
    my ($self, $head) = @_;
    if ($self->_get_show_headers())
    {
        return $head;
    }
    else
    {
        return
        [ grep /^(?:Newsgroups|Date|Subject|To|From|Message-ID): /, @$head]
        ;
    }
}

sub _article_display_page
{
    my $self = shift;

    my $group = $self->param('group');
    my $article = $self->param('article');

    my $nntp = $self->_get_nntp();

    my @info = $nntp->group($group);

    if (! @info)
    {
        $nntp->quit();
        return "<html><body><h1>Error! Unknown Group.</h1></body></html>";
    }

    my ($num_articles, $first_article, $last_article, $group_name) = @info;

    # TODO : Error handling.
    my $head = $nntp->head($article);
    my $body = $nntp->body($article);

    my $article_text =
        join("",
            map
            {
                my $s = $_;
                chomp($s);
                my $s_esc = CGI::escapeHTML($s);
                ($s =~ /^(Subject|From):/ ? "<b>$s_esc</b>" : $s_esc) . "\n";
            }
            @{$self->_get_headers($head)},
        ) .
        "<br />\n" .
        join("",
            map {
                my $s = $_;
                chomp($s);
                CGI::escapeHTML($s). "\n";
            }
            @$body
        );

    return
    $self->tt_process(
        'article_display_page.tt',
        {
            'group' => $group,
            'article' => $article,
            'title' => "$group ($article)",
            'text' => $article_text,
            'show_headers' => $self->_get_show_headers(),
            'first_art' => $first_article,
            'last_art' => $last_article,
            'thread' => $self->_get_thread($nntp),
        },
    );
}

sub _thread_render_node
{
    my ($self, $node, $current) = @_;
    my $subj = CGI::escapeHTML($node->{subject});
    my $node_text =
        ($node->{idx} == $current) ?
            "<b>$subj</b>" :
            qq|<a href="$node->{idx}">$subj</a>|
        ;

    return "<li>$node_text " .
        CGI::escapeHTML($node->{from}) .
        (exists($node->{subs}) ?
            ("<br /><ul>" .
            join("",
                map
                    {$self->_thread_render_node($_, $current) }
                @{$node->{subs}}
            ) .
            "</ul>") :
            ""
        ) .
        "</li>";
}

# TODO :
# 2. Make the current article non-linked and bold.
# 3. Add the date (?).
sub _get_thread
{
    my ($self, $nntp) = @_;
    my $article = $self->param('article');

    my $cache = CGI::Application::NetNewsIface::Cache::DBI->new(
        {
            'nntp' => $nntp,
            'dsn' => $self->param('dsn'),
        },
    );
    $cache->select($self->param('group'));

    my ($thread, $coords) = $cache->get_thread($article);

    return "<ul>" . $self->_thread_render_node($thread, $article) . "</ul>";
}

sub _css
{
    my $self = shift;
    $self->header_props(-type => 'text/css');
    return <<"EOF";
.articles th, .articles td
{
    vertical-align:top;
    text-align: left;
}
.articles
{
    border-collapse: collapse;
}
.articles td, .articles th
{
    border: 1.5pt black solid;
    padding: 2pt;
}
EOF
}

=head2 $cgiapp->update_group($group)

Updates the cache records for the NNTP group C<$group>. This method is used
for maintenance, to make sure a script loads promptly.

=cut

sub update_group
{
    my $self = shift;
    my $group = shift;

    my $cache = CGI::Application::NetNewsIface::Cache::DBI->new(
        {
            'nntp' => $self->_get_nntp(),
            'dsn' => $self->param('dsn'),
        },
    );
    $cache->select($group);
}

=head2 $cgiapp->init_cache__sqlite()

Initializes the SQLite cache that is pointed by the DBI DSN given as
a parameter to the CGI script. This should be called before any use of the
CGI Application itself, because otherwise there will be no tables to operate
on.

=cut

sub init_cache__sqlite
{
    my $self = shift;
    return $self->_init_cache({'auto_inc' => "PRIMARY KEY AUTOINCREMENT"});
}

=head2 $cgiapp->init_cache__mysql()

Initializes the MySQL cache that is pointed by the DBI DSN given as
a parameter to the CGI script. This should be called before any use of the
CGI Application itself, because otherwise there will be no tables to operate
on.

=cut

sub init_cache__mysql
{
    my $self = shift;
    return $self->_init_cache({'auto_inc' => "PRIMARY KEY NOT NULL AUTO_INCREMENT"});
}

sub _init_cache
{
    my $self = shift;
    my $args = shift;

    my $auto_inc = $args->{'auto_inc'};

    require DBI;

    my $dbh = DBI->connect($self->param('dsn'), "", "");
    $dbh->do("CREATE TABLE groups (name varchar(255), idx INTEGER $auto_inc, last_art INTEGER)");
    $dbh->do("CREATE TABLE articles (group_idx INTEGER, article_idx INTEGER, msg_id varchar(255), parent INTEGER, subject varchar(255), frm varchar(255), date varchar(255))");
    $dbh->do("CREATE UNIQUE INDEX idx_groups_name ON groups (name)");
    $dbh->do("CREATE UNIQUE INDEX idx_articles_primary ON articles (group_idx, article_idx)");
    $dbh->do("CREATE INDEX idx_articles_msg_id ON articles (group_idx, msg_id)");
    $dbh->do("CREATE INDEX idx_articles_parent ON articles (group_idx, parent)");
}

1;

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-netnewsiface@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-NetNewsIface>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head2 Known Bugs

None, but it doesn't mean there aren't any bugs.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1; # End of CGI::Application::NetNewsIface
