package CGI::Wiki::Kwiki;

=head1 NAME

CGI::Wiki::Kwiki - An instant wiki built on CGI::Wiki.

=head1 DESCRIPTION

A simple-to-use front-end to L<CGI::Wiki>.  It can be used for several
purposes: to migrate from a L<CGI::Kwiki> wiki (its original purpose),
to provide a quickly set up wiki that can later be extended to use
more of CGI::Wiki's capabilities, and so on.  It uses the L<Template>
Toolkit to allow quick and easy customisation of your wiki's look
without you needing to dive into the code.

=head1 INSTALLATION

The distribution ships with and installs a script called
L<cgi-wiki-kwiki-install>. Create an empty directory somewhere that your
web server can see, and run the script. It will set up a SQLite
database, install the default templates into the current directory,
and create a cgi script to run the wiki. You now have a wiki - edit
wiki.cgi to change any of the default options, and you're done.

=head1 MORE DETAILS

wiki.cgi will look something like this:

  #!/usr/bin/perl -w
  use strict;
  use warnings;
  use CGI;
  use CGI::Wiki::Kwiki;

  my %config = (
    db_type => 'SQLite',
    db_name => '/home/wiki/data/node.db',
    formatters => {
                    default => 'CGI::Wiki::Formatter::Default',
                  },
  );

  my %vars = CGI::Vars();
  eval {
      CGI::Wiki::Kwiki->new(%config)->run(%vars);
  };

  if ($@) {
      print "Content-type: text/plain\n\n";
      print "There was a problem with CGI::Wiki::Kwiki:\n\n--\n";
      print "$@";
      print "\n--\n";
      print STDERR $@;
  }

In the following directions, we use "webserver" to mean the user that
your webserver executes CGI scripts as.  Often this is actually you
yourself; sometimes it is "www-data" or "apache".  If you don't know,
ask your ISP.

In the script above and in the following, replace
C</home/wiki/data/node.db> with a filename in a directory that you
will be able to make readable and writeable by the webserver.  SQLite
requires access to both the file (for writing data) and the directory
it resides in (for creating a lockfile).

The above is a complete and absolutely minimal wiki CGI script.  To
make it work as-is:

=over

=item B<Set up the backend database>

This example uses L<DBD::SQLite>, so make sure you have that installed.
Then run the following command (which should have come with your
L<CGI::Wiki> install) to initialise an SQLite database:

  cgi-wiki-setupdb --type sqlite --name /home/wiki/data/node.db

You should see notification of tables being created.

Make sure that the webserver will be able to write to the database
file and to the directory it lives in.

=item B<Install the script and its templates>

Put the script somewhere suitable so that your webserver will execute it.

Make a subdirectory of the directory the script is in, called
C<templates>.  Copy the templates from the L<CGI::Wiki::Kwiki> tarball
into this directory.  The webserver will need to read from here but it
doesn't need to be able to write.

=item B<Set up a place for the searcher to index your wiki into>

Make a subdirectory of the directory the script is in, called
C<search_map>.  Make this writeable by the webserver.

=back

You can have all kinds of other fun with it though; see EXAMPLES
below.  In particular, a nicer formatter to use is
L<CGI::Wiki::Formatter::UseMod>.

=head1 METHODS

=over 4

=item B<new>

Creates a new CGI::Wiki::Kwiki object. Expects some options, most have
defaults, a few are required. Here's how you'd call the constructor -
all values here (apart from C<formatters>) are defaults; the values
you must provide are marked.

    my $wiki = CGI::Wiki::Kwiki->new(
        db_type => 'MySQL',
        db_user => '',
        db_pass => '',
        db_name => undef,                     # required
        db_host => '',
        formatters => {
            documentation => 'CGI::Wiki::Formatter::Pod',
            tests         => 'My::Own::PlainText::Formatter',
            discussion    => [
                               'CGI::Wiki::Formatter::UseMod',
                               allowed_tags   => [ qw( p b i pre ) ],
                               extended_links => 1,
                               implicit_links => 0,
                             ],
            _DEFAULT      => [ # if upgrading from pre-0.4
                               'CGI::Wiki::Formatter::UseMod;
                             ],
                      },                  # example only, not default
        site_name => 'CGI::Wiki::Kwiki site',
        admin_email => 'email@invalid',
        template_path => './templates',
        stylesheet_url => "",
        home_node => 'HomePage',
        cgi_path => CGI::url(),
        search_map => './search_map',
        prefs_expire => '+1M',    # passed to CGI::Cookie; see its docs
        charset => 'iso-8859-1', # characterset for the wiki
    );

The C<db_type> parameter refers to a CGI::Wiki::Store::[type] class.
Valid values are 'MySQL', SQLite', etc: see the L<CGI::Wiki> man page
and any other CGI::Wiki::Store classes you have on your
system. C<db_user> and C<db_pass> will be used to access this
database.

C<formatters> should be a reference to a hash listing all the
formatters that you wish to support.  Different wiki pages can be
formatted with different formatters; this allows you to do things like
have documentation pages written in POD, test suite pages written in
plain text, and discussion pages written in your favourite Wiki
syntax.  If this hash has more than one entry, its keys will be
supplied in a drop-down list on every edit screen, and the selected
one will be used when displaying that page.

(If you I<do> wish to supply more than one entry to the hash, you will
need L<CGI::Wiki::Formatter::Multiple> installed on your system.)

Each value of the C<formatters> hash can be either a simple scalar
giving the class of the required formatter, or an anonymous array
whose first entry is the class name and whose other entries will be
passed through to the formatter instantiation, parsed as a hash.  (See
the C<discussion> formatter entry in the example code above if this
sounds confusing.)

B<Note:> Even if your C<formatters> hash has only one entry, you
should make its key be meaningful, since it will be stored in the
node's metadata and will appear in dropdowns if you ever decide to
support another kind of formatter.

B<Backwards Compatibility Note:> If you are upgrading from a version
of L<CGI::Wiki::Kwiki> earlier than 0.4, and you have an existing wiki
running on it, you should supply a C<_DEFAULT> entry in the
C<formatters> hash so it knows what to do with nodes that have no
formatter metadata stored.

This method tries to create the store, formatter and wiki objects, and will
die() if it has a problem. It is the calling script's responsibility to
catch any exceptions and tell the user.

=item B<run>

Runs the wiki object, and outputs to STDOUT the result, including the CGI
header. Takes no options.

    $wiki->run();

=back

=head1 EXAMPLES

Just for fun, here is the configuration part of the wiki script Kake
uses at work, full of horrid little hacks.  Kake is thoroughly ashamed
of herself but feels this is worth showing around in case anyone
accidentally gets a useful idea from it.

  #!/usr/bin/perl -w
  use strict;
  use warnings;
  use CGI;
  use CGI::Wiki::Formatter::UseMod;
  use CGI::Wiki::Kwiki;
  use CGI::Wiki::Store::SQLite;
  use LWP::Simple;

  # Set up an array of allowed tags so we can make a macro to show them.
  my @allowed_tags = qw( a b p i em tt pre img div code br );

  # Set up the formatter conf here since we will be setting up an extra
  # formatter in order to make links with some of the macros.
  my %formatter_conf = (
                         extended_links => 1,
                         implicit_links => 0,
                         allowed_tags => \@allowed_tags,
                         node_prefix => "index.cgi?node=",
                         edit_prefix => "index.cgi?action=edit;node=",
                         # branding is important
                         munge_node_name => sub {
                             my $node_name = shift;
                             $node_name =~ s/State51/state51/g;
                             $node_name = "alex" if $node_name eq "Alex";
                             return $node_name;
                         },
                       );
  my $formatter = CGI::Wiki::Formatter::UseMod->new( %formatter_conf );
  # Create an extra wiki object too for passing to ->format when we call
  # it in the macros - so the formatter can find out which nodes already
  # exist.
  my $wiki = CGI::Wiki->new(
      store => CGI::Wiki::Store::SQLite->new(
                                          dbname => "./data/node.db"
                                            )
                           );

  my %macros = (
      # Perl Advent Calendar feed
      '@PERL_ADVENT_TODAY' => sub {
          my $xml = get( "http://perladvent.org/perladventone.rdf" )
            or return "[Can't get RSS for the Perl Advent Calendar!]";
          # Yes I know parsing XML with regexes is yuck, but this
          # is just a quick hack for December.
          if ( $xml =~ m|<item>\s*<title>([^<]+)</title>\s*<link>([^<]+)</link>| ) {
              return qq(<div align="center" style="border:dashed 1px; padding-top:5px; padding-bottom:5px;">Today's Perl Advent Calendar goodie is: [<a href="$2">$1</a>]</div>);
          } else {
              return "Can't parse Perl Advent Calendar RSS!";
          }
      },

      # Match state51::* modules and link to wiki page.
      qr/\b(state51::\w+(::\w+)*)\b/ => sub {
          my $module_name = shift;
          my $link = $formatter->format( "[[$module_name]]", $wiki );
          $link =~ s|<p>||;
          $link =~ s|</p>||;
          chomp $link; # or headings won't work
          return "<tt>$link</tt>";
      },

      # Match non-state51::* modules and link to search.cpan.org.
      # Don't match anything already inside an <a href ...
      # or preceded by a :, since that will be part of state51::*
      qr/(?<![>:])\b([A-Za-rt-z]\w*::\w+(::w+)*)\b/ => sub {
          my $module_name = shift;
          my $dist = $module_name;
          $dist =~ s/::/-/g;
          return qq(<a href="http://search.cpan.org/dist/$dist"><tt><small>(CPAN)</small> $module_name</tt></a>);
      },

      # Print method names in <tt>
      qr/(->\w+)/ => sub { return "<tt>$_[0]</tt>" },

      # Macro to list available HTML tags.
      '@ALLOWED_HTML_TAGS' => join( ", ", @allowed_tags ),
  );

  my %config = (
      db_type => 'SQLite',
      db_name => './data/node.db',
      db_user => 'not_used',
      home_node => "Home",
      site_name => "state51 wiki",
      formatters => {
                      default => [
                                   'CGI::Wiki::Formatter::UseMod',
                                    %formatter_conf,
                                    macros => \%macros,
                                 ]
                    },
      template_path => "templates/",
      search_map => "./data/search_map/",
  );

The above is not intended to exemplify good programming practice.

=head1 TODO

Things I still need to do

=over 4

=item Polish templates

=item Import script should catch case-sensitive dupes better

=item CGI::Wiki::Kwiki does not currently work under mod_perl. This is a serious problem.
=back

=head1 SEE ALSO

=over

=item *

L<CGI::Wiki>

=item *

L<http://london-crafts.org> - a wiki for a local crafts group, running on CGI::Wiki::Kwiki

=back

=head1 AUTHORS

Tom Insam (tom@jerakeen.org)
Kake Pugh (kake@earth.li)

=head1 CREDITS

Thanks to Kake for writing CGI::Wiki, and providing the initial
patches to specify store and formatter types in the config. And for
complaining at me till I released things.  Thanks to Ivor Williams for
diff support.

=head1 COPYRIGHT

     Copyright (C) 2003-2004 Tom Insam.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

use strict;
use warnings;
use CGI;
use CGI::Cookie;
use CGI::Wiki;
use CGI::Wiki::Search::DB;
use CGI::Wiki::Plugin::Diff;
use Template;
use Algorithm::Merge qw(merge);

our $VERSION = '0.59';

my $default_options = {
    db_type => 'MySQL',
    db_user => '',
    db_pass => '',
    db_name => undef,
    db_host => '',
    formatters => {
                    default => [
                                 'CGI::Wiki::Formatter::Default',
                                 allowed_tags => [ qw( p b i pre ) ],
                               ],
                  },
    site_name => 'CGI::Wiki::Kwiki site',
    admin_email => 'email@invalid',
    template_path => './templates',
    stylesheet_url => "",
    home_node => 'HomePage',
    cgi_path => CGI::url(),
    search_map => "./search_map",
    prefs_expire => '+1M',
    charset => 'iso-8859-1',
};

our $diff_plugin = CGI::Wiki::Plugin::Diff->new;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    my %args = @_;

    for (keys(%args)) {
        if (exists($default_options->{$_})) {
            $self->{$_} = $args{$_};
        } else {
            die "Unknown option $_";
        }
    }

    for (keys(%$default_options)) {
        $self->{$_} = $default_options->{$_}
            unless defined($self->{$_});
        die "Option '$_' is required" unless defined($self->{$_});
    }

    my $store_class = "CGI::Wiki::Store::$self->{db_type}";
    eval "require $store_class";
    if ( $@ ) {
        die "Couldn't 'use' $store_class: $@";
    }

    $self->{store} = $store_class->new(
        dbname => $self->{db_name},
        dbuser => $self->{db_user},
        dbpass => $self->{db_pass},
        dbhost => $self->{db_host},
        charset => $self->{charset},
    ) or die "Couldn't create store of class $store_class";

    my %formatter_objects;
    while ( my ($label, $formatter) = each %{ $self->{formatters} } ) {
        my $formatter_class = ref $formatter ? shift @$formatter : $formatter;
        eval "require $formatter_class";
        if ( $@ ) {
            die "Couldn't 'use' $formatter_class: $@\n";
        }
        my %formatter_args = ref $formatter ? @$formatter : ( );
        $formatter_args{node_prefix} ||= $self->{cgi_path} . "?node=";
        $formatter_args{edit_prefix} ||= $self->{cgi_path}."?action=edit;node=";

        my $formatter_obj = $formatter_class->new( %formatter_args )
          or die "Can't create formatter object of class $formatter_class";

        $formatter_objects{$label} = $formatter_obj;
    }
    if ( scalar keys %formatter_objects > 1 ) {
        require CGI::Wiki::Formatter::Multiple;
        $self->{formatter} =
                     CGI::Wiki::Formatter::Multiple->new(%formatter_objects );
    } else {
        my ($label, $formatter_object) = each %formatter_objects;
        $self->{formatter} = $formatter_object;
        $self->{formatter_label} = $label;
    }

    $self->{search} = CGI::Wiki::Search::DB->new( store => $self->{store} );

    $self->{wiki} = CGI::Wiki->new(
        store     => $self->{store},
        formatter => $self->{formatter},
        search    => $self->{search},
    ) or die "Can't create CGI::Wiki object";

    $self->{wiki}->register_plugin( plugin => $diff_plugin );

    return $self;
}

sub run {
    my ($self, %args) = @_;
    # arguments coming in from the CGI script won't be encoded correctly,
    # but we know what character set we _told_ the browser to use..
    if ($CGI::Wiki::CAN_USE_ENCODE) {
        for (keys(%args)) {
          $args{$_} = Encode::decode($self->{charset}, $args{$_});
        }
    }

    $self->{return_tt_vars} = delete $args{return_tt_vars} || 0;
    $self->{return_output}  = delete $args{return_output}  || 0;

    # certain actions are the result of button presses.
    $args{action} = 'commit'  if $args{commit};
    $args{action} = 'preview' if $args{preview};
    $args{action} = 'search'  if $args{search};

    # It's possible to pass the node name in more than one way.
    $args{node} ||= CGI::param('keywords');

    my ($node, $action) = @args{'node', 'action'};
    my $metadata = { username  => $args{username},
                     comment   => $args{comment},
                     edit_type => $args{edit_type},
                     formatter => $args{formatter},
                   };

    if (defined $action) {

        if ($action eq 'commit') {
            $self->commit_node($node, $args{content}, $args{checksum},
                               $args{version}, $metadata);

        } elsif ($action eq 'preview') {
            $self->preview_node($node, $args{content}, $args{checksum},
                                $metadata);

        } elsif ($action eq 'edit') {
            $self->edit_node($node, $args{version});

        } elsif ($action eq 'revert') {
            $self->revert_node($node, $args{version});

        } elsif ($action eq 'create') {
            $self->create_node( name => $node );

        } elsif ($action eq 'index') {
            my @nodes = sort $self->{wiki}->list_all_nodes();
            $self->process_template(
                template => "site_index.tt",
                node     => "index",
                vars     => { nodes => \@nodes, not_editable => 1 },
            );

        } elsif ($action eq 'show_backlinks') {
            $self->show_backlinks($node);

        } elsif ($action eq 'random') {
            my @nodes = $self->{wiki}->list_all_nodes();
            $node = $nodes[int(rand(scalar(@nodes) + 1)) + 1];
            $self->redirect_to_node($node);

        } elsif ($action eq 'list_all_versions') {
            $self->list_all_versions($node);

        } elsif ($action eq 'search') {
            $self->search($args{search});

        } elsif ($action eq 'search_index') {
            $|++;
            print "Content-type: text/plain\n\n";
            for ($self->{wiki}->list_all_nodes()) {
                print "Indexing $_\n";
                my $node = $self->{wiki}->retrieve_node($_);
                $self->{wiki}->search_obj()->index_node($_, $node);
            }
            print "\n\nindexed all nodes\n";
            exit 0;

        } elsif ($action eq 'userstats') {
            $self->do_userstats( %args );
        } elsif ( $action eq 'preferences' ) {
            if ( $args{set} ) {
                $self->set_preferences( %args );
	    } else {
                $self->show_preferences_form;
            }
        } elsif ( $action eq 'show_all_nodes' ) {
            $self->show_all_nodes;
        } else {
            die "Bad action\n";
        }

    } elsif ( defined($node) and $node eq "RecentChanges" ) {
        $self->display_recent_changes;
    } else {

       if ($args{diffversion}) {
            my %diff = $diff_plugin->differences(
                        node  => $node,
                left_version  => $args{version},
                right_version => $args{diffversion} );
            $diff{ver1} = $args{version};
            $diff{ver2} = $args{diffversion};
            $self->process_template(
                template => "differences.tt",
                node     => $node,
                vars     => \%diff,
            );

        } else {
            $self->display_node($node, $args{version});
        }

    }
}

sub show_all_nodes {
    my $self = shift;
    my $wiki = $self->{wiki};
    my @all = sort( $wiki->list_all_nodes );
    my @nodes;
    foreach my $name ( @all ) {
        my %data = $wiki->retrieve_node( $name );
        my $formatted_content = $wiki->format($data{content}, $data{metadata});
        my $param = $wiki->formatter->node_name_to_node_param( $name );
        my $url = $self->{cgi_url} . "?" . $param;
        push @nodes, {
                       name              => $name,
                       formatted_content => $formatted_content,
                       url               => $url,
                     };
    }

    my %tt_vars = (
                    nodes => \@nodes,
                  );

    $self->process_template(
                             template => "show_all_nodes.tt",
                             vars     => \%tt_vars,
                           );
}

sub display_node {
    my ($self, $node, $version) = @_;
    $node ||= $self->{home_node};

    unless ( $self->{wiki}->node_exists($node) || $node eq "WantedPages" ) {
        $node = $self->{home_node};
    }

    my %data = $self->{wiki}->retrieve_node($node);

    my $current_version = $data{version};
    undef $version if ($version && $version == $current_version);

    my %criteria = ( name => $node );
    $criteria{version} = $version if $version;

    my %node_data = $self->{wiki}->retrieve_node( %criteria );
    my $raw = $node_data{content};
    my $content = $self->{wiki}->format($raw, $node_data{metadata});

    my %tt_vars = (
        content    => $content,
        node_name  => CGI::escapeHTML($node),
        node_param => CGI::escape($node),
        version    => $version,
        metadata   => $node_data{metadata},
    );

    if ( $node eq "WantedPages" ) {
        my @dangling = $self->{wiki}->list_dangling_links;
        @dangling = map {
            {
            name => CGI::escapeHTML($_),
            edit_link     => "$self->{cgi_path}?node=".CGI::escape($_).";action=edit",
            backlink_link => "$self->{cgi_path}?node=".CGI::escape($_).";action=show_backlinks"
            }
        } sort @dangling;

        $tt_vars{wanted} = \@dangling;
        $tt_vars{not_editable} = 1;
        $self->process_template(
            template => "wanted_pages.tt",
            node     => $node,
            vars     => \%tt_vars,
        );

    } else {
        $self->process_template(
            template => "node.tt",
            node     => $node,
            vars     => \%tt_vars,
        );
    }
}

sub display_recent_changes {
    my $self = shift;
    my %recent_changes;
    for my $days ( [0, 1], [1, 7], [7, 14], [14, 30] ) {
        my @rc = $self->{wiki}->list_recent_changes( between_days => $days );
        @rc = map {
            {
              name      => CGI::escapeHTML( $_->{name} ),
              last_modified => CGI::escapeHTML( $_->{last_modified} ),
              username  => CGI::escapeHTML( $_->{metadata}{username}[0] || ""),
              comment   => CGI::escapeHTML( $_->{metadata}{comment}[0] || "" ),
              edit_type => CGI::escapeHTML($_->{metadata}{edit_type}[0] || ""),
              url       => "$self->{cgi_path}?node=".CGI::escape( $_->{name} )
            }
        } @rc;
        if ( scalar @rc ) {
            $recent_changes{$days->[1]} = \@rc;
	  }
    }

    my %tt_vars = (
                    recent_changes => \%recent_changes,
                    not_editable   => 1,
                  );
    $self->process_template(
                             template => "recent_changes.tt",
                             vars     => \%tt_vars,
                           );
}

sub preview_node {
    my ($self, $node, $content, $checksum, $metadata) = @_;

    if ( $self->{wiki}->verify_checksum( $node, $checksum ) ) {
        my @formatter_labels = sort keys %{ $self->{formatters} };
        my %tt_vars = (
            content      => CGI::escapeHTML($content),
            preview_html => $self->{wiki}->format($content, $metadata),
            checksum     => CGI::escapeHTML($checksum),
            formatter_labels => \@formatter_labels,
            map { $_ => CGI::escapeHTML($metadata->{$_}||"") } keys %$metadata,
        );

        $self->process_template(
            template => "edit_form.tt",
            node     => $node,
            vars     => \%tt_vars,
        );

    } else {
        my %node_data = $self->{wiki}->retrieve_node($node);
        my ( $stored, $checksum ) = @node_data{qw( content checksum )};
        my @formatter_labels = sort keys %{ $self->{formatters} };

        my %tt_vars = (
            checksum    => CGI::escapeHTML($checksum),
            new_content => CGI::escapeHTML($content),
            stored      => CGI::escapeHTML($stored),
            formatter_labels => \@formatter_labels,
            map { $_ => CGI::escapeHTML($metadata->{$_}||"") } keys %$metadata,
        );
        $self->process_template(
           template => "edit_conflict.tt",
           node     => $node,
           vars     => \%tt_vars,
        );
    }
}

sub edit_node {
    my ($self, $node, $version) = @_;

    my %data = $self->{wiki}->retrieve_node($node);
    $version ||= $data{version};

    my %criteria = ( name => $node, version => $version );
    my %node_data = $self->{wiki}->retrieve_node( %criteria );
    my ( $content, $checksum ) = @node_data{qw( content checksum )};

    my @formatter_labels = sort keys %{ $self->{formatters} };

    my %prefs_data = $self->get_prefs_from_cookie;
    my $username = $prefs_data{username};

    my %tt_vars = (
        content          => CGI::escapeHTML($content),
        checksum         => CGI::escapeHTML($checksum),
        version          => $version,
        formatter_labels => \@formatter_labels,
        formatter        => CGI::escapeHTML($data{metadata}{formatter}[0]||""),
        username         => $username,
    );

    $self->process_template(
        template => "edit_form.tt",
        node     => $node,
        vars     => \%tt_vars,
    );
}

sub process_template {
    my ($self, %args) = @_;
    my $template = $args{template};
    my $node = $args{node};

    my $vars = $args{vars} || {};
    my $conf = $args{conf} || {};

    my %tt_vars = (
        %$vars,
        site_name      => $self->{site_name},
        cgi_url        => $self->{cgi_path},
        contact_email  => $self->{admin_email},
        description    => "",
        keywords       => "",
        home_link      => $self->{cgi_path},
        home_name      => "Home",
        stylesheet_url => $self->{stylesheet_url},
        dist_version   => "$VERSION",
        charset        => $self->{charset},
    );

    if ($node) {
        $tt_vars{node_name}  = CGI::escapeHTML($node);
        $tt_vars{node_param} = CGI::escape($node);
    }

    if ( $self->{return_tt_vars} ) {
        return %tt_vars;
    }

    my %tt_conf = ( %$conf, INCLUDE_PATH => $self->{template_path} );

    # Create Template object, print CGI header, process template.
    my $tt = Template->new( \%tt_conf );
    my $output = CGI::header( -cookie => $args{cookies}, -charset => $self->{charset} );

    if ($CGI::Wiki::CAN_USE_ENCODE) {
        binmode STDOUT, ":encoding($self->{charset})";
    }

    die $tt->error
        unless ( $tt->process( $template, \%tt_vars, \$output ) );
    return $output if $self->{return_output};
    print $output;
}

sub commit_node {
    my ($self, $node, $content, $checksum, $ancestor, $metadata) = @_;

    my @formatters = keys %{ $self->{formatters} };
    if ( scalar @formatters == 1 ) {
        $metadata->{formatter} = $formatters[0];
    }

    my $written = $self->{wiki}->write_node( $node, $content, $checksum,
                                             $metadata );

    if ($written) {
        $self->redirect_to_node($node) unless $self->{return_output};
    } else {
        # We assume this means that we have an edit
        # conflict. If we can merge the changes, do so.

        # Get the version of the node that the changes were based on
        my %criteria = ( name => $node, version => $ancestor );
        my %node_data = $self->{wiki}->retrieve_node(%criteria);
        my $original = $node_data{content};

        # Get the current version of the node
        %node_data = $self->{wiki}->retrieve_node($node);
        my ( $stored, $checksum ) = @node_data{qw( content checksum )};

        my $conflicts;
        my $resolved = merge(
          [ split(/\n/, $original) ],
          [ split(/\n/, $stored) ],
          [ split(/\n/, $content) ],
          { CONFLICT => sub {
            my ($left, $right) = @_;
            $conflicts++;
            return  q{<!-- --- Page currently contains -->},
                    (@$left),
                    q{<!-- --- Your version -->},
                    (@$right),
                    q{<!-- --- -->};
          } }
        );
        $resolved = join("\n", @$resolved);
        print STDERR "Conflicts found!\n$resolved\n" if $conflicts;;

        my %tt_vars = (
            checksum    => CGI::escapeHTML($checksum),
            new_content => CGI::escapeHTML($resolved),
            stored      => CGI::escapeHTML($stored),
            conflicts => $conflicts,
            map { $_ => CGI::escapeHTML($metadata->{$_}||"") } keys %$metadata,
        );
        $self->process_template(
            template => "edit_conflict.tt",
            node     => $node,
            vars     => \%tt_vars,
        );
    }
}

sub revert_node {
    my ($self, $node, $version) = @_;

    my %node_data = $self->{wiki}->retrieve_node( name=>$node, version=>$version );
    my %current_node = $self->{wiki}->retrieve_node( $node );

    my $written = $self->{wiki}->write_node( $node, $node_data{content}, $current_node{checksum}, { username => "Auto Revert", comment => "Reverted to version $version" } );

    if ($written) {
        $self->display_node($node);

    } else {
        die "Can't revert node for some reason.\n";
    }
}

sub create_node {
    my ($self, %args) = @_;
    my $name = $args{name} || "";
    if ( $name ) {
        #Kludge - CGI::Wiki::Formatter::* needs a canonicalise_node_name method
        if ( $self->{formatter}->can( "_do_freeupper" ) ) {
            $name = $self->{formatter}->_do_freeupper( $name );
        }
        my $url = $self->{cgi_path} . "?action=edit;node=" .CGI->escape($name);
        my $header = CGI->redirect( $url );
        return $header if $self->{return_output};
        print $header;
    } else {
        $self->process_template(
            template => "create_page.tt",
        );
    }
}

sub do_search {
    my ($self, $terms) = @_;

    my %finds   = $self->{wiki}->search_nodes($terms);
    my @sorted  = sort { $finds{$a} cmp $finds{$b} } keys %finds;
    my @results = map {
        {
            url   => CGI::escape($_),
            title => CGI::escapeHTML($_)
        }
    } @sorted;
    my %tt_vars = ( results => \@results );
    $self->process_template(
        template => "search_results.tt",
        vars     => \%tt_vars
    );
}

sub redirect_to_node {
    my ($self, $node) = @_;
    print CGI::redirect("$self->{cgi_path}?node=".CGI::escape($node));
    exit 0;
}

sub list_all_versions {
    my ($self, $node) = @_;

    my %curr_data = $self->{wiki}->retrieve_node($node);
    my $curr_version = $curr_data{version};

    my @history;
    for my $version ( 1 .. $curr_version ) {
        my %node_data = $self->{wiki}->retrieve_node(
            name    => $node,
            version => $version
        );
        push @history, {
            version  => CGI::escapeHTML( $version ),
            modified => CGI::escapeHTML( $node_data{last_modified} ),
            username => CGI::escapeHTML( $node_data{metadata}{username}[0] ),
            comment  => CGI::escapeHTML( $node_data{metadata}{comment}[0] ),
        };
    }

    @history = reverse @history;
    my %tt_vars = (
        node         => $node,
        version      => $curr_version,
        history      => \@history,
        not_editable => 1,
    );
    $self->process_template(
        template => "node_history.tt",
        node     => $node,
        vars     => \%tt_vars,
    );
}

sub show_backlinks {
    my ($self, $node) = @_;

    my @backlinks = $self->{wiki}->list_backlinks( node => $node );
    my @results = map {
        { url   => CGI::escape($_),
          title => CGI::escapeHTML($_)
        }
    } sort @backlinks;

    my %tt_vars = ( results      => \@results,
                    num_results  => scalar @results,
                    not_editable => 1 );

    $self->process_template(
        template => "backlink_results.tt",
        node     => $node,
        vars     => \%tt_vars,
    );
}

sub search {
    my ($self, $search) = @_;

    my %results = $self->{wiki}->search_nodes($search);
    my @results = map { $_ }
        ( sort { $results{$a} <=> $results{$b} } keys(%results) );

    my %tt_vars = ( results      => \@results,
                    num_results  => scalar @results,
                    search => $search,
                    not_editable => 1 );

    $self->process_template(
        template => "search_results.tt",
        vars     => \%tt_vars,
    );
}

sub do_userstats {
    my ($self, %args) = @_;
    my $username = $args{username};
    my $num_changes = $args{n} || 5;
    die "No username supplied to show_userstats" unless $username;
    my @nodes = $self->{wiki}->list_recent_changes(
        last_n_changes => $num_changes,
        metadata_is    => { username => $username }
    );
    @nodes = map {
        {
          name          => CGI::escapeHTML($_->{name}),
          last_modified => CGI::escapeHTML($_->{last_modified}),
          comment       => CGI::escapeHTML($_->{metadata}{comment}[0]),
          url           => $self->{cgi_path} . "?node=" . CGI::escape($_->{name}),
        }
                 } @nodes;
    my %tt_vars = ( nodes        => \@nodes,
                    username     => CGI::escapeHTML($username),
                    not_editable => 1,
                  );
    $self->process_template(
        template => "userstats.tt",
        vars     => \%tt_vars,
    );
}

sub show_preferences_form {
    my $self = shift;
    # Get defaults for form fields from cookie.
    my %prefs = $self->get_prefs_from_cookie;
    $self->process_template(
        template => "preferences.tt",
        vars     => {
                      %prefs,
                      show_prefs_form => 1,
                      not_editable    => 1,
                    },
    );
}

sub get_prefs_from_cookie {
    my $self = shift;
    my %cookies = CGI::Cookie->fetch;
    my $cookie_name = $self->prefs_cookie_name;
    my %data;
    if ( $cookies{$cookie_name} ) {
        %data = $cookies{$cookie_name}->value; # call ->value in list context
      }
    return ( username => $data{username} || "",
           );
}

sub set_preferences {
    my ($self, %args) = @_;
    my $cookie = $self->make_prefs_cookie( %args );
    $self->process_template(
        template => "preferences.tt",
        vars     => {
                      not_editable => 1,
                    },
        cookies  => $cookie,
    );
}

sub make_prefs_cookie {
    my ($self, %args) = @_;
    my $cookie_name = $self->prefs_cookie_name;
    my $cookie = CGI::Cookie->new(
        -name    => $cookie_name,
        -value   => {
                      username => $args{username},
                    },
        -expires => $self->prefs_expire,
    );
    return $cookie;
}

sub prefs_expire {
    my $self = shift;
    return $self->{prefs_expire};
}

sub prefs_cookie_name {
    my $self = shift;
    my $name = $self->{site_name} . "_userprefs";
    $name =~ s/\W//g;
}

1;
