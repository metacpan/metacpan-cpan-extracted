#---------------------------------------------------------------------
package App::BarnesNoble::WishListMinder;
#
# Copyright 2014 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 15 Jun 2014
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Monitor a Barnes & Noble wishlist for price changes
#---------------------------------------------------------------------

use 5.010;
use strict;
use warnings;

our $VERSION = '0.004';
# This file is part of App-BarnesNoble-WishListMinder 0.004 (December 20, 2014)

use Path::Tiny;
#use Smart::Comments;

use Moo;
use namespace::clean;

# Like == but undef equals only itself
sub _numEq
{
  my ($one, $two) = @_;

  return !1 if (defined($one) xor defined($two));
  return 1 unless defined $one;
  $one == $two;
} # end _numEq

# Like eq but undef equals only itself
sub _eq
{
  my ($one, $two) = @_;

  return !1 if (defined($one) xor defined($two));
  return 1 unless defined $one;
  $one eq $two;
} # end _numEq

sub _format_price {
  my $price = shift;
  if (defined $price) {
    $price = sprintf '$%03d', $price;
    substr($price, -2, 0, '.');
    $price;
  } else {
    'unavailable';
  }
} # end _format_price

sub _format_timestamp {
  require Time::Piece;

  Time::Piece->gmtime(shift)->strftime("%Y-%m-%d %H:%M:%S");
}

#=====================================================================

has mech => qw(is lazy);
sub _build_mech {
  require WWW::Mechanize;
  WWW::Mechanize->new(
    autocheck => 1,
    cookie_jar => { file => shift->cookie_file, autosave => 1 },
  );
} # end _build_mech

has dir => qw(is lazy);
sub _build_dir {
  require File::HomeDir;
  File::HomeDir->VERSION(0.93); # my_dist_data

  path(File::HomeDir->my_dist_data('App-BarnesNoble-WishListMinder',
                               { create => 1 })
       or die "Can't determine data directory");
} # end _build_dir

has config_file => qw(is lazy);
sub _build_config_file {
  shift->dir->child('config.ini');
} # end _build_config_file

has config => qw(is lazy);
sub _build_config {
  my $self = shift;
  require Config::Tiny;
  my $fn = $self->config_file;

  Config::Tiny->read("$fn", 'utf8')
        or die "Unable to read $fn: " . Config::Tiny->errstr;
} # end _build_config

has cookie_file => qw(is lazy);
sub _build_cookie_file {
  shift->dir->child('cookies.txt');
} # end _build_cookie_file

has db_file => qw(is lazy);
sub _build_db_file {
  shift->dir->child('wishlist.sqlite');
} # end _build_db_file

has dbh => qw(is lazy  predicate 1  clearer _clear_dbh);
sub _build_dbh {
  my $self = shift;

  require DBI;
  DBI->VERSION(1.38);           # last_insert_id

  my $fn = $self->db_file;
  my $exists = $fn->exists;

  my $dbh = DBI->connect("dbi:SQLite:dbname=$fn","","",
                         { AutoCommit => 0, PrintError => 0, RaiseError => 1,
                           sqlite_unicode => 1 });

  $self->create_database_schema($dbh) unless $exists;

  $dbh;
} # end _build_dbh

sub close_dbh
{
  my $self = shift;

  if ($self->has_dbh) {
    my $dbh = $self->dbh;
    $dbh->rollback;
    $dbh->disconnect;
    $self->_clear_dbh;
  }
} # end close_dbh

has scraper => qw(is lazy);
sub _build_scraper {
  require Web::Scraper::BarnesNoble::WishList;

  Web::Scraper::BarnesNoble::WishList::bn_scraper();
} # end _build_scraper

has updates => qw(is ro  default) => sub { {} };

#---------------------------------------------------------------------
sub configure
{
  my ($self) = @_;

  my $config_file = $self->config_file;

  say "Your config file is:\n $config_file";

  unless ($config_file->is_file) {
    die "$config_file is a directory!\n" if $config_file->is_dir;
    $config_file->spew_utf8(<<'END CONFIG');
;						-*-conf-windows-*-
; Your credentials for logging in to the Barnes & Noble website go here:
email    = YOUR EMAIL HERE
password = YOUR PASSWORD HERE

; If you want the Price Drop Alert emails to go to a different address,
; uncomment the next line and set the email address.
;report   = EMAIL ADDRESS FOR ALERTS

; Next, you need one or more wishlists to monitor.
; Each wishlist must have a unique name in [brackets].

[My Wishlist]
wishlist = WISHLIST URL HERE
END CONFIG
    say "\nYou need to replace the ALL CAPS placeholders with the correct values.";
  }

  if (my $editor = $ENV{VISUAL} || $ENV{EDITOR}) {
    require Text::ParseWords;
    system(Text::ParseWords::shellwords($editor), "$config_file");
  }
} # end configure

#---------------------------------------------------------------------
sub create_database_schema
{
  my ($self, $dbh) = @_;

  $dbh->do("PRAGMA foreign_keys = ON");

  $dbh->do(<<'');
CREATE TABLE books (
  ean         INTEGER PRIMARY KEY,
  title       TEXT NOT NULL,
  author      TEXT
)

  $dbh->do(<<'');
CREATE TABLE wishlists (
  wishlist_id   INTEGER PRIMARY KEY,
  url           TEXT NOT NULL UNIQUE,
  last_fetched  TIMESTAMP
)

  $dbh->do(<<'');
CREATE TABLE wishlist_books (
  wishlist_id   INTEGER NOT NULL REFERENCES wishlists,
  ean           INTEGER NOT NULL REFERENCES books,
  priority      INTEGER,
  date_added    DATE NOT NULL DEFAULT CURRENT_DATE,
  date_removed  DATE,
  PRIMARY KEY (wishlist_id,ean)
)

  $dbh->do(<<'');
CREATE TABLE prices (
  ean            INTEGER NOT NULL REFERENCES books,
  first_recorded TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_checked   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  current        TINYINT NOT NULL DEFAULT 1,
  price          INTEGER,
  list_price     INTEGER,
  discount       INTEGER,
  PRIMARY KEY (ean,first_recorded)
)

  $dbh->commit;

} # end create_database_schema

#---------------------------------------------------------------------
sub login
{
  my ($self) = shift;

  my ($config, $m) = ($self->config->{_}, $self->mech);

  $m->get('https://www.barnesandnoble.com/signin');

  #path("/tmp/login.html")->spew_utf8($m->content);

  $m->submit_form(
    with_fields => {
      'login.email'    => $config->{email},
      'login.password' => $config->{password},
    },
  );
} # end login
#---------------------------------------------------------------------

sub scrape_response
{
  my ($self, $response) = @_;

  my $books = $self->scraper->scrape($response);

  for my $book (@$books) {
    $book->{priority} //= 3;
    for ($book->{discount}) {
      next unless defined $_;
      s/^\s+//;
      s/\s+\z//;
      s/^\((.+)\)\z/$1/;
      s/^You save\s*//i;
    }
    $book->{date_added} =~ s!^(\d\d)/(\d\d)/(\d\d)$!20$3-$1-$2!;
  }

  $books;
} # end scrape_response
#---------------------------------------------------------------------

sub write_db
{
  my ($self, $wishlist_url, $time_fetched, $books) = @_;

  $time_fetched = _format_timestamp($time_fetched);

  my $dbh = $self->dbh;
  my $updates = $self->updates;

  my $wishlist_id = $self->get_wishlist_id($wishlist_url);

  my $existing_priority = $self->get_existing_books($wishlist_id);

  my $get_book = $dbh->prepare(<<'');
    SELECT title, author FROM books WHERE ean = ?

  my $get_price = $dbh->prepare(<<'');
    SELECT price, list_price, discount, first_recorded FROM prices
    WHERE ean = ? AND current == 1

  for my $book (@$books) {
    my $ean = $book->{ean};
    my $current_price_row;

    # Update or add the book to the books table
    my $book_row = $dbh->selectrow_hashref($get_book, undef, $ean);
    if ($book_row) {
      # The book exists.  Update title & author if necessary
      unless (_eq($book_row->{title}, $book->{title}) and
              _eq($book_row->{author}, $book->{author})) {
        $dbh->do(<<'', undef, @$book{qw(title author ean)});
          UPDATE books SET title = ?, author = ? WHERE ean = ?

      }
      # Since the book exists, it might have a price
      $current_price_row = $dbh->selectrow_hashref($get_price, undef, $ean);
    } else {
      # The book doesn't exist; add it
      $dbh->do(<<'', undef, @$book{qw(title author ean)});
        INSERT INTO books (title, author, ean) VALUES (?,?,?)

    }

    # Update or add the book to the wishlist_books table
    if (exists $existing_priority->{ $ean }) {
      # The book is already in the wishlist.  Update priority if necessary
      unless (_numEq($book->{priority}, $existing_priority->{ $ean })) {
        $dbh->do(<<'', undef, $book->{priority}, $wishlist_id, $ean);
          UPDATE wishlist_books SET priority = ?
          WHERE wishlist_id = ? AND ean = ?

      }
    } else {
      # Add book to this wishlist
###   Inserting: @$book{qw(ean priority date_added)}
      $dbh->do(<<'', undef, $wishlist_id, @$book{qw(ean priority date_added)});
        INSERT INTO wishlist_books (wishlist_id, ean, priority, date_added)
        VALUES (?,?,?,?)

    }

    for my $price (@$book{qw(price list_price)}) {
      next unless defined $price;
      $price =~ s/^\s*\$//;
      $price = int($price * 100 + 0.5);
    }

    { no warnings 'uninitialized';  $book->{discount} =~ s/\%// }

    # Update or add the prices entry
    if ($current_price_row and
        _numEq($current_price_row->{price}, $book->{price}) and
        _numEq($current_price_row->{list_price}, $book->{list_price}) and
        _numEq($current_price_row->{discount}, $book->{discount})) {
      $dbh->do(<<'', undef, $time_fetched, $ean, $current_price_row->{first_recorded});
        UPDATE prices SET last_checked = ?
        WHERE ean = ? AND first_recorded = ?

    } else {
      if ($current_price_row) {
        $dbh->do(<<'', undef, $ean, $current_price_row->{first_recorded});
          UPDATE prices SET current = 0 WHERE ean = ? AND first_recorded = ?

      }
      $updates->{$ean} = {
        old => $current_price_row,
        new => $book,
      };
###   Inserting: $ean
      $dbh->do(<<'', undef, @$book{qw(ean price list_price discount)}, ($time_fetched)x2);
        INSERT INTO prices (ean, price, list_price, discount, first_recorded, last_checked)
        VALUES (?,?,?,?,?,?)

    }
  } # end for each $book in @$books

  $dbh->commit;
} # end write_db

sub reduced_price_eans
{
  my $updates = shift->updates;

  sort {
    $updates->{$a}{new}{price} <=> $updates->{$b}{new}{price} or
    $updates->{$a}{new}{title} cmp $updates->{$b}{new}{title}
  } grep {
    my ($old, $new) = @{$updates->{$_}}{qw(old new)};
    $old and defined($new->{price})
        and (!defined($old->{price}) or $new->{price} < $old->{price});
  } keys %$updates;
} # end reduced_price_eans

sub get_existing_books
{
  my ($self, $wishlist_id) = @_;

  my %existing_priority;

  my $s = $self->dbh->prepare(<<'');
    SELECT ean, priority FROM wishlist_books
    WHERE wishlist_id = ? AND date_removed IS NULL

  $s->execute($wishlist_id);
  $s->bind_columns( \( my ($ean, $priority) ) );
  while ($s->fetch) {
    $existing_priority{$ean} = $priority;
  }

  \%existing_priority;
} # end get_existing_books

sub get_wishlist_id
{
  my ($self, $wishlist_url) = @_;

  my $dbh = $self->dbh;

  my ($wishlist_id) = $dbh->selectrow_array(<<'', undef, $wishlist_url);
    SELECT wishlist_id FROM wishlists WHERE url = ?

  unless (defined $wishlist_id) {
    $dbh->do(<<'', undef, $wishlist_url);
      INSERT INTO wishlists (url) VALUES (?)

    $wishlist_id = $dbh->last_insert_id((undef)x4)
        // die "Unable to insert wishlist $wishlist_url";
  }

  $wishlist_id;
} # end get_wishlist_id
#---------------------------------------------------------------------

sub describe_selected_updates
{
  my $self = shift;

  my $updates = $self->updates;

  map {
    my $book = $updates->{$_}{new};
    my $price = _format_price($book->{price});
    if (my $old = $updates->{$_}{old}) {
      $price .= sprintf ' (was %s)', _format_price($old->{price});
    }
    <<"END UPDATE";
Title:  $book->{title}  ($_)
Author: $book->{author}
Price:  $price
END UPDATE
  } @_;
} # end describe_selected_updates

#---------------------------------------------------------------------

sub email_price_drop_alert
{
  my ($self) = @_;

  my @eans = $self->reduced_price_eans or return;

  require Email::Sender::Simple;
  require Email::Simple;
  require Email::Simple::Creator;
  require Encode;

  my $updates = $self->updates;
  my $config  = $self->config->{_};

  my $address = $config->{report} || $config->{email};
  my @body = $self->describe_selected_updates(@eans);

  my $subject = (@eans > 2)
    ? sprintf('%d books', scalar @eans)
    : Encode::encode('MIME-Header',
        join(' & ', map { $updates->{$_}{new}{title} } @eans)
      );

  my $email = Email::Simple->create(
    header => [
      To      => $address,
      From    => qq'"Barnes & Noble Wishlist" <$address>',
      Subject => "Price Drop Alert: $subject",
      'MIME-Version' => '1.0',
      'Content-Type' => 'text/plain; charset=UTF-8',
      'Content-Transfer-Encoding' => '8bit',
    ],
    body => Encode::encode('utf8', join("\n", @body)),
  );

  Email::Sender::Simple->send($email);
} # end email_price_drop_alert
#---------------------------------------------------------------------

sub print_matching_books
{
  my ($self, $search, $all_history) = @_;

  my $books = $self->dbh->selectall_arrayref(<<'END SEARCH', undef, ("%$search%")x2);
SELECT ean, price, title, author FROM books NATURAL JOIN prices
WHERE prices.current AND (title LIKE ? OR author LIKE ?)
ORDER by title, author
END SEARCH

  if ($all_history or @$books == 1) {
    foreach my $row (@$books) {
      print "$row->[0] ";
      $self->print_price_history($row->[0]);
    }
  } else {
    foreach my $row (@$books) {
      $row->[1] = _format_price($row->[1]);
      printf "%s %6s %s by %s\n", @$row;
    }
    print "\n";
  }
} # end print_matching_books
#---------------------------------------------------------------------

sub print_updates_since
{
  my ($self, $since_date) = @_;

  my $s = $self->dbh->prepare(<<'END SEARCH');
SELECT ean, price, title, author FROM books NATURAL JOIN prices
WHERE prices.current AND first_recorded >= ?
ORDER by first_recorded, price, title, author
END SEARCH

  $s->execute($since_date);

  while (my $row = $s->fetch) {
    $row->[1] = _format_price($row->[1]);
    printf "%s %6s %s by %s\n", @$row;
  }

  print "\n";
} # end print_updates_since
#---------------------------------------------------------------------

sub print_price_history
{
  my ($self, $ean) = @_;

  my $dbh = $self->dbh;

  my $book = $dbh->selectrow_hashref(
    'SELECT title, author FROM books WHERE ean = ?', undef, $ean
  );

  print "$book->{title} by $book->{author}\n";

  my $history = $dbh->prepare(<<'END HISTORY');
SELECT first_recorded, last_checked, price, list_price, discount
FROM prices WHERE ean = ? ORDER BY first_recorded
END HISTORY

  $history->execute($ean);

  while (my $row = $history->fetchrow_hashref) {
    $_ =~ s/ .+// for @$row{qw(first_recorded last_checked)};
    printf("%s - %s %6s%s%s\n", @$row{qw(first_recorded last_checked)},
           _format_price($row->{price}),
           $row->{list_price}
           ? " (list " . _format_price($row->{list_price}) . ")"
           : '',
           $row->{discount} ? " ($row->{discount}% off)" : '');
  }

  print "\n";
} # end print_price_history

#---------------------------------------------------------------------

sub print_updates
{
  my $self = shift;

  my $updates = $self->updates;

  my @eans = sort {
    $updates->{$a}{new}{title}  cmp $updates->{$b}{new}{title} or
    $updates->{$a}{new}{author} cmp $updates->{$b}{new}{author}
  } keys %$updates;

  print join("\n", $self->describe_selected_updates(@eans));
} # end print_updates
#---------------------------------------------------------------------

sub have_user_cookie
{
  my $have_cookie;
  my $min_expires = time() + 30;

  shift->mech->cookie_jar->scan(sub {
    $have_cookie = 1 if $_[1] eq 'userid'
                    and $_[4] eq '.barnesandnoble.com'
                    and $_[8] > $min_expires
  });

  $have_cookie;
} # end have_user_cookie

#---------------------------------------------------------------------

sub update_wishlists
{
  my $self = shift;

  my $config  = $self->config;
  my $m       = $self->mech;

  # Ensure we can open the database before we start making web requests
  $self->dbh;

  $self->login unless $self->have_user_cookie;

  for my $wishlist (sort keys %$config) {
    next if $wishlist eq '_';   # the root INI section

    my $response = $m->get( $config->{$wishlist}{wishlist} );
    my $books    = $self->scrape_response($response);
    unless (@$books) {
      warn "$config->{$wishlist}{wishlist} has no entries\n";
      # Save the response for debugging:
      $self->dir->child("empty-$wishlist.html")->spew_utf8($response->content);
    }
#    path("/tmp/wishlist.html")->spew_utf8($response->content);
    $self->write_db($config->{$wishlist}{wishlist}, $response->last_modified // $response->date, $books);
  }
} # end update_wishlists

#---------------------------------------------------------------------

sub usage {
  my $name = $0;
  $name =~ s!^.*[/\\]!!;

  shift->close_dbh;

  print "$name $VERSION\n";
  exit if $_[0] and $_[0] eq 'version';
  print <<"END USAGE";
\nUsage:  $name [options] [EAN_or_TITLE_or_AUTHOR] ...
  -a, --all-history        Show price history even when multiple items match
  -e, --email              Send Price Drop Alert email (implies --update)
  -q, --quiet              Don't print list of updates
  -s, --since=DATE         Print books whose price changed on or after DATE
  -u, --update             Download current prices from wishlist
      --configure          Create and/or edit the config file
      --help               Display this help message
      --version            Display version information
END USAGE

    exit;
} # end usage
#---------------------------------------------------------------------

sub run
{
  my ($self, @args) = @_;

  # Process command line options
  my ($all_history, $fetch_wishlist, $quiet, $send_email, $since_date);
  {
    require Getopt::Long; Getopt::Long->VERSION(2.24); # object-oriented
    my $getopt = Getopt::Long::Parser->new(
      config => [qw(bundling no_getopt_compat)]
    );
    my $usage = sub { $self->usage(@_) };

    $getopt->getoptionsfromarray(\@args,
      'all-history|a' => \$all_history,
      'email|e'   => \$send_email,
      'quiet|q'   => \$quiet,
      'since|s=s' => \$since_date,
      'update|u'  => \$fetch_wishlist,
      'configure' => sub { $self->configure; exit },
      'help'      => $usage,
      'version'   => $usage
    ) or $self->usage;
  }

  # Update database & send email if requested
  if ($fetch_wishlist or $send_email) {
    $self->update_wishlists;

    $self->email_price_drop_alert if $send_email;
    $self->print_updates unless $quiet;
  } elsif (not @args and not $since_date) {
    # Didn't fetch updates and no request to display book data
    if ($self->config_file->is_file) {
      $self->usage;
    } else {
      $self->configure;
    }
  }

  if ($since_date) {
    $self->print_updates_since($since_date);
  }

  # Display data from the database about requested books
  foreach my $arg (@args) {
    if ($arg =~ /^[0-9]{13}\z/) {
      $self->print_price_history($arg);
    } else {
      $self->print_matching_books($arg, $all_history);
    }
  }

  # Disconnect from the database
  $self->close_dbh;
} # end run

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

App::BarnesNoble::WishListMinder - Monitor a Barnes & Noble wishlist for price changes

=head1 VERSION

This document describes version 0.004 of
App::BarnesNoble::WishListMinder, released December 20, 2014
as part of App-BarnesNoble-WishListMinder version 0.004.

=head1 SYNOPSIS

  use App::BarnesNoble::WishListMinder;
  App::BarnesNoble::WishListMinder->new->run(@ARGV);

=head1 DESCRIPTION

App::BarnesNoble::WishListMinder is an application for monitoring a
Barnes & Noble wishlist for price changes.  For user documentation,
see L<bn-wishlist>.

The internals are not currently documented and subject to change.
If you're interested in using this module directly, let me know and
we can discuss the API.

=head1 SEE ALSO

L<bn-wishlist>

L<http://www.barnesandnoble.com/>


=for Pod::Coverage
.*

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-App-BarnesNoble-WishListMinder AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=App-BarnesNoble-WishListMinder >>.

You can follow or contribute to App-BarnesNoble-WishListMinder's development at
L<< https://github.com/madsen/App-BarnesNoble-WishListMinder >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
