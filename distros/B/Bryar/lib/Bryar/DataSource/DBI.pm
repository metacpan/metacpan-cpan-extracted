package Bryar::Comment::DBI;
use base qw(Class::DBI::mysql Bryar::Comment);
__PACKAGE__->set_db('Main','dbi:mysql:bryar');
__PACKAGE__->set_up_table('comments');

package Bryar::Document::DBI;
use base qw(Class::DBI::mysql);
use Class::DBI::AbstractSearch;
__PACKAGE__->set_db('Main','dbi:mysql:bryar');
__PACKAGE__->set_up_table('posts');
__PACKAGE__->has_many('comments' => 'Bryar::Comment::DBI' => 'document');
use Bryar::Document;
push @Bryar::Document::DBI::ISA, "Bryar::Document";

package Bryar::DataSource::DBI;
use Time::Piece;

=head1 NAME

Bryar::DataSource::DBI - Retrieve blog posts and comments from database

=head1 SYNOPSIS

=over 3

=item *

Create a mysql database called "bryar":

    CREATE TABLE posts (
          id mediumint(8) unsigned NOT NULL auto_increment,
          content text,
          title varchar(255),
          epoch timestamp,
          category varchar(255),
          author varchar(20),
          PRIMARY KEY(id)
    );

    CREATE TABLE comments (
          id mediumint(8) unsigned NOT NULL auto_increment,
          document mediumint(8),
          content text,
          epoch timestamp,
          url varchar(255),
          author varchar(20),
          PRIMARY KEY(id)
    );

=item *

Install C<Class::DBI::mysql> and C<Class::DBI::AbstractSearch>

=item *

Ensure the web server's database user can read from all tables, and 
write to the comments table.

=item *

Put C<source: Bryar::DataSource::DBI> in your Bryar config.

=item *

Get blogging!

=back

=cut

sub search {
    my ($self, $config, %params) = @_;
    return Bryar::Document::DBI->retrieve($params{id}) if $params{id};

    my %condition = (1 => 1); # To make sure we have something
    $condition{epoch} = {between => [ _epoch2ts($params{since}),
    _epoch2ts($params{before}) ] }        if $params{since};
    $condition{"lower(content)"} = {like => "%". lc $params{content}."%"}
        if $params{content};
    my %limits;
    $limit{limit} = $params{limit} if $params{limit};
    Bryar::Document::DBI->search_where(\%condition, \%limit);
}

sub _epoch2ts { Time::Piece->new(shift)->strftime("%Y%m%d%H%M%S"); }

sub add_comment { 
    my ($self, $config, %params) = @_; 
    Bryar::Document::Comment->new(\%params);
}
