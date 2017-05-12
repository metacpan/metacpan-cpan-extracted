package CPAN::Search::Lite::DBI;
use strict;
use warnings;
use DBI;
our $VERSION = 0.77;

use base qw(Exporter);
our ($dbh, $tables, @EXPORT_OK);
@EXPORT_OK = qw($dbh $tables);

$tables = {
           mods => {
                    primary => {mod_id => q{SMALLINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT}},
                    other => {
                              mod_name => q{VARCHAR(100) NOT NULL},
                              dist_id => q{SMALLINT UNSIGNED NOT NULL},
                              mod_abs => q{TINYTEXT},
                              doc => q{bool},
                              src => q{bool},
                              mod_vers => q{VARCHAR(10)},
                              dslip => q{CHAR(5)},
                              chapterid => q{TINYINT(2) UNSIGNED},
                             },
                    key => [qw/dist_id mod_name(100)/],
                    text => [qw/mod_abs/],
                    name => 'mod_name',
                    id => 'mod_id',
                    has_a => {dists => 'dist_id',
                              chapters => 'chapterid',
                             },
                   },
           dists => {
                     primary => {dist_id => q{SMALLINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT}},
                     other => {
                               dist_name => q{VARCHAR(90) NOT NULL},
                               stamp => q{TIMESTAMP(8)},
                               auth_id => q{SMALLINT UNSIGNED NOT NULL},
                               dist_file => q{VARCHAR(110) NOT NULL},
                               dist_vers => q{VARCHAR(20)},
                               dist_abs => q{TINYTEXT},
                               size => q{MEDIUMINT UNSIGNED NOT NULL},
                               birth => q{DATE NOT NULL},
                               readme => q{bool},
                               changes => q{bool},
                               meta => q{bool},
                               install => q{bool},
                               md5 => q{CHAR(32)},
                              },
                     key => [qw/auth_id dist_name(90)/],
                     text => [qw/dist_abs/],
                     name => 'dist_name',
                     id => 'dist_id',
                     has_a => {auths => 'auth_id'},
                     has_many => {ppms => 'dist_id',
                                  reqs => 'dist_id',
                                  mods => 'dist_id',
                                  chaps => 'dist_id',
                                 },
                    },
           auths => {
                     primary => {auth_id => q{SMALLINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT}},
                     other => {
                               cpanid => q{VARCHAR(20) NOT NULL},
                               fullname => q{VARCHAR(40) NOT NULL},
                               email => q{TINYTEXT},
                              },
                     key => [qw/cpanid(20)/],
                     text => [qw/fullname/],
                     has_many => {dists => 'dist_id'},
                     name => 'cpanid',
                     id => 'auth_id',
                    },
           chaps => {
                     primary => {chap_id => q{SMALLINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT}},
                     other => {
                               dist_id => q{SMALLINT UNSIGNED NOT NULL},
                               chapterid => q{TINYINT(2) UNSIGNED},
                               subchapter => q{TINYTEXT},     
                              },
                     key => [qw/dist_id/],
                     id => 'chap_id',
                     has_a => {dists => 'dist_id',
                               chapters => 'chapterid',
                              },
                    },
           reqs => {
                    primary => {req_id => q{SMALLINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT}},
                    other => {
                              dist_id => q{SMALLINT UNSIGNED NOT NULL},
                              mod_id => q{SMALLINT UNSIGNED NOT NULL},
                              req_vers => q{VARCHAR(10)},
                             },
                    key => [qw/dist_id/],
                    id => 'req_id',
                    has_a => {dists => 'dist_id',
                              mods => 'mod_id',
                             },
                   },
           ppms => {
                    primary => {ppm_id => q{SMALLINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT}},
                    other => {
                              dist_id => q{SMALLINT UNSIGNED NOT NULL},
                              rep_id => q{TINYINT(2) UNSIGNED NOT NULL},
                              ppm_vers => q{VARCHAR(20)},
                             },
                    key => [qw/dist_id/],
                    id => 'ppm_id',
                    has_a => {dists => 'dist_id',
                              reps => 'rep_id',
                             },
                   },
           reps => {
                    primary => {rep_id => q{TINYINT(2) UNSIGNED NOT NULL PRIMARY KEY}},
                    other => {
                              abs => q{TINYTEXT},
                              mtime => q{DATETIME},
                              browse => q{TINYTEXT},
                              perl => q{VARCHAR(10)},
                              alias => q{VARCHAR(20)},
                             },
                    id => 'rep_id',
                   },
           chapters => {
                        primary => {chapterid => q{TINYINT(2) UNSIGNED NOT NULL PRIMARY KEY}},
                        other => {
                                  chap_link => q{TINYTEXT},
                                 },
                        id => 'chapterid',
                       },
          };


for my $table (keys %$tables) {
  foreach my $type (qw(primary other)) {
    foreach my $column (keys %{$tables->{$table}->{$type}}) {
      push @{$tables->{$table}->{columns}}, $column;
    }
  }
}

sub new {
  my ($class, %args) = @_;
  foreach (qw(db user passwd)) {
    die qq{Must supply an '$_' argument} unless defined $args{$_};
  }
  $dbh ||= DBI->connect("DBI:mysql:$args{db}", $args{user}, $args{passwd},
                        {RaiseError => 1, AutoCommit => 0})
    or die "Cannot connect to $args{db}";
  my $objs;
  foreach my $table (keys %$tables) {
    my $cl = $class . '::' . $table;
    $objs->{$table} = $cl->make($table);
  }
  bless {objs => $objs}, $class;
}

sub make {
  my ($class, $table) = @_;
  die qq{No table exists corresponding to '$class'} unless $table;
  my $info = $tables->{$table};
  die qq{No information available for table '$table'} unless $info;
  my $self = {table => $table,
              columns => $info->{columns},
              id => $info->{id},
             };
  foreach (qw(name has_a has_many)) {
    next unless defined $info->{$_};
    $self->{$_} = $info->{$_};
  }
  bless $self, $class;
}

sub db_error {
  my ($obj, $sth) = @_;
  return unless $dbh;
  $sth->finish if $sth;
  $obj->{error_msg} = q{Database error: } . $dbh->errstr;
}

#sub DESTROY {
#  $dbh->disconnect;
#}

1;

__END__



