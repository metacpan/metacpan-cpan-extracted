package DBIx::VersionedSubs::AutoLoad;
use strict;
use base 'DBIx::VersionedSubs';
use vars qw($VERSION);
use Carp qw(carp croak);

$VERSION = '0.08';

=head1 NAME

DBIx::VersionedSubs::AutoLoad - autoload subroutines from the database

=head1 SYNOPSIS

  package My::App;
  use strict;
  use base 'DBIx::VersionedSubs::AutoLoad';

  package main;
  use strict;

  My::App->startup($dsn);
  while (my $request = Some::Server->get_request) {
      My::App->update_code; # update code from the DB
      My::App->handle_request($request);
  }

=head1 ABSTRACT

This module overrides some methods in L<DBIx::VersionedSubs>
to prevent loading of the whole code at startup and installs
an AUTOLOAD handler to load the needed code on demand. This
is useful if startup time is more important than response time
or you fork() before loading the code from the database.

=head1 CAVEATS

You should be able to switch between the two implementations
without almost any further code changes. There is one
drawback of the AUTOLOAD implementation:

=head2 Preexisting functions don't get overwritten from the database

You need to explicitly load functions from the database
that you wish to overwrite Perl code obtained from elsewhere.

This is the price you pay for using AUTOLOAD.

=head1 CLASS METHODS

=cut

=head2 C<< __PACKAGE__->init_code >>

Overridden to just install the AUTOLOAD handler.

=cut

sub init_code {
    my ($package) = @_;
    no strict 'refs';
    if (! defined &{"$package\::AUTOLOAD"}) {
        *{"$package\::AUTOLOAD"} = sub {
            use vars qw($AUTOLOAD);
            if ($AUTOLOAD !~ /::(\w+)$/) {
                croak "Undecipherable subroutine '$AUTOLOAD' called";
            };
            my $name = $1;
            $package->install_and_invoke($name,@_);
        };
    } else {
        carp "$package->init_code called, but there already is an AUTOLOAD handler installed.";
    };

    my $begin = $package->retrieve_code('BEGIN');
    if (defined $begin) {
        eval "{ $begin }";
        carp "$package\::BEGIN: $@" if $@
    };
};

=head2 C<< __PACKAGE__->install_and_invoke NAME, ARGS >>

Loads code from the database, installs it
into the namespace and immediately calls it
with the remaining arguments via C<< goto &code; >>.

If no row with a matching name exists, an
error is raised.

=cut

sub install_and_invoke {
    my ($package,$name) = splice @_,0,2;

    my $code = $package->load_code($name);
    if (defined $code) {
        goto &$code;
    } else {
        croak "Undefined subroutine $package\::$name called";
    };
};

=head2 C<< __PACKAGE__->update_code >>

Overridden to do lazy updates. It wipes all code that
is out of date from the namespace and lets the AUTOLOAD
handler sort out the reloading.

=cut

sub update_code {
    my ($package) = @_;

    my $version = $package->code_version || 0;
    my $sth = $package->dbh->prepare_cached(sprintf <<'SQL', $package->code_history);
        SELECT distinct name,version FROM %s
            WHERE version > ?
            ORDER BY version DESC
SQL

    $sth->execute($version);

    # If update is needed, wipe the touched elements:
   my %seen;

    my $current_version = $version || 0;
    while (my ($name,$new_version) = $sth->fetchrow()) {
        next if $seen{$name}++;
        
        $current_version = $current_version < $new_version 
                         ? $new_version
                         : $current_version;

        delete $package->code_source->{$name};

        # This manual AUTOLOAD is less than ideal
        no strict 'refs';
        no warnings 'redefine';
        *{"$package\::$name"} = sub {
            local *AUTOLOAD = "$package\::$name";
            goto &{"$package\::AUTOLOAD"};
        };
        # = sub { $package->install_and_invoke( $name, @_ ); };
    }
    $package->code_version($current_version);
};

=head2 C<< __PACKAGE__->load_code NAME >>

Retrieves the code for the subroutine C<NAME>
from the database and calls
C<< __PACKAGE__->install_code $name,$code >>
to install it.

=cut

sub load_code {
    my ($package,$name) = @_;

    my $code = $package->retrieve_code($name);
    if (! defined $code) {
        # let caller decide whether to croak or to ignore
        return;
    };
    $package->create_sub($name,$code);
};

=head2 C<< __PACKAGE__->retrieve_code NAME >>

Retrieves the code for the subroutine C<NAME>
from the database and returns it as a string.

=cut

sub retrieve_code {
    my ($package,$name) = @_;

    my $sql = sprintf <<'SQL', $package->code_live;
        SELECT code FROM %s
           WHERE name = ?
SQL

    my $sth = $package->dbh->prepare_cached($sql);
    if (! $sth->execute($name)) {
        # let caller decide whether to croak or to ignore
        return;
    }
    my($code) = $sth->fetchrow;
    $sth->finish;

    return $code
};

=head1 INSTALLED CODE

=head2 C<< AUTOLOAD >>

An AUTOLOAD handler is installed to manage the loading
of code that has not been retrieved from the database
yet. If another AUTOLOAD handler already exists,
the AUTOLOAD handler is not installed and a warning
is issued.

=cut

1;

=head1 BUGS

=over 4

=item * Currently, if a routine gets changed, the AUTOLOAD
handler is not fired directly but by using a callback. This
is because I couldn't delete the typeglob properly such
that the AUTOLOAD fires again.

=back

=head1 AUTHOR

Max Maischein, E<lt>corion@cpan.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=cut

