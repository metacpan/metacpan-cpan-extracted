#
# Perl module for applying incremental database deltas/migrations to a database
#

package DBIx::Delta;

use strict;
use FindBin qw($Bin);
use File::Basename;
use Getopt::Std;
use File::Path qw(make_path);
use IO::File;
use IO::Dir;
use DBI;

use vars qw($VERSION);
$VERSION = '1.0.0';

# abstract connect() - should be overridden with a sub returning a valid $dbh
sub connect
{
    die "connect() is an abstract method that must be provided by a subclass";
}

# Return a string for the environment if you want to distinguish prod/test etc.
sub environment
{
    return '';
}

sub _die 
{
    my $self = shift;
    $self->{dbh}->disconnect;
    die join ' ', @_;
}

# For subclassing to localise statements e.g. mysql grants in dev might need to
#   use different IP addresses in production
#   e.g. s/^\s* (grant\b.*?) localhost /${1}192.168.0.1/x
sub filter_statement
{
    my $self = shift;
    shift;
}

# Parse arguments
sub parse_args
{
    my $self = shift;
    @ARGV = @_ if @_;

    my %opts = ();
    getopts('?bdfhnqsu',\%opts);

    if ($opts{'?'} || $opts{h}) {
      print "usage: " . basename($0) . " [-qbd] [-n] [-f] [-s|-u] [<delta> ...]\n";
      exit 1;
    }

    $self->{brief}      = $opts{b} || '';
    $self->{debug}      = $opts{d} || '';
    $self->{force}      = $opts{f} && @ARGV ? $opts{f} : '';
    $self->{noop}       = $opts{n} || '';
    $self->{quiet}      = $opts{q} || '';
    $self->{statements} = $opts{s} || '';
    $self->{update}     = $opts{u} || '';

    if ($self->{debug}) {
        printf "+ brief: %s\n",  $self->{brief};
        printf "+ debug: %s\n",  $self->{debug};
        printf "+ force: %s\n",  $self->{force};
        printf "+ noop: %s\n",   $self->{noop};
        printf "+ quiet: %s\n",  $self->{quiet};
        printf "+ statements: %s\n", $self->{statements};
        printf "+ update: %s\n", $self->{update};
    }

    return @ARGV;
}

# Return a hashref containing the set of deltas we've already applied
sub load_applied_deltas
{
    my $self = shift;

    my $env = $self->environment;
    $env = "_$env" if $env;

    my $applied_dir = "$Bin/applied$env";
    unless (-d $applied_dir) {
        warn "No 'applied' directory found - creating\n";
        make_path($applied_dir) or die "Directory create failed: $!\n";
        return {};
    }
    die "Cannot write to directory '$applied_dir' - aborting\n" 
        unless -w $applied_dir;
    $self->{applied_dir} = $applied_dir;

    my $loaded = {};
    my $d = IO::Dir->new($applied_dir)
        or die "Cannot read from applied directory '$applied_dir': $!\n";
    while (defined (my $applied = $d->read)) {
        next if $applied =~ m/^\./;
        $applied = basename $applied;
        $applied =~ s/\.sql$//;
        $loaded->{$applied} = 1;
    }

    print "+ applied deltas: " . join(',', keys %$loaded) . "\n" if $self->{debug};

    return $loaded;
}

# Find an array of outstanding delta filenames
sub find_deltas
{
    my $self = shift;
    my @delta = @_;
    @delta = <*.sql> unless @delta;

    unless (@delta) {
      print ("No '*.sql' deltas found - exiting.\n");
      exit 0;
    }
    print "+ candidate deltas: " . join(',', @delta) . "\n" if $self->{debug};

    my @outstanding = ();
    for my $d (@delta) {
        my $name = $d;
        $name =~ s/\.sql$//;
        if ($self->{force} || ! exists $self->{applied}->{$name}) {
            push @outstanding, $d;
        }
    }
    print "+ oustanding deltas: " . join(',', @outstanding) . "\n" if $self->{debug};

    return @outstanding;
}

# Apply the given deltas to the database
sub apply_deltas
{
    my $self = shift;

    # Connect to db
    my $dbh = $self->{dbh} = $self->connect
        or die "Database connect failed\n";

    my @st = ();
    for my $d (@_) {
        # Load delta
        my $fh = IO::File->new($d, 'r') or die("cannot open delta '$d': $!");
        my $delta;
        {
            local $/ = undef;
            $delta = <$fh>;
        }

        # Apply miscellaneous cleanups
        $delta =~ s/^--[^\n]*\n/\n/mg;
        $delta =~ s/^\s*\n+//;
        $delta =~ s/\n\s*\n+/\n/g;

        # Escape semicolons inside single-quoted strings
        my @bits = split /(?<!\\)'/, $delta;
        printf "+ delta split into %d bits\n", scalar(@bits) if $self->{debug};
        for (my $i = 1; $i <= $#bits; $i += 2) {
            print "+ checking string '$bits[$i]' for semi-colons\n" if $self->{debug};
            $bits[$i] =~ s/(?<!\\);/\\;/g;
            print "+ munged string: '$bits[$i]'\n" if $self->{debug};
        }
        $delta = join("'", @bits);
#       do {} while $delta =~ s/\G([^']*'[^']*)(?<!\\);([^']*')/$1\\;$2/gsm;
        # Split each file into a set of statements on (non-escaped) semicolons
        my @stmt = split /(?<!\\);/, $delta;
        # Skip everything after the last semicolon
        pop @stmt if @stmt > 1;
        $self->{stmt}->{$d} = \@stmt if $self->{test_mode};
        printf "+ [%s] %d statement(s) found:\n---\n%s\n---\n", 
            $d, scalar(@stmt), join("\n---", @stmt) if $self->{debug};

        # Execute the statements 
        for (my $i = 0; $i <= $#stmt; $i++) {
            print "+ executing stmt $i ... " if $self->{debug};
            # Unescape semicolons escaped above
            $stmt[$i] =~ s/\\;/;/g;
            # Trim leading whitespace
            $stmt[$i] =~ s/^\s+//;
            my $st = $self->filter_statement( $stmt[$i] );
            push @st, $st if $self->{statements};
            if ($self->{noop}) {
              print "\n\n[NOOP]\n$st\n\n";
            }
            elsif ($self->{update}) {
              $dbh->do($st)
                or $self->_die("[$d] update failed: " . $dbh->errstr . "\ndoing: $st\n");
            }
            print "+ done\n" if $self->{debug} && ! $self->{noop};
        }

        # Record that the delta has been applied
        if ($self->{update} && ! $self->{noop}) {
            print "+ creating applied entry ... " if $self->{debug};
            my $filename = $self->{applied_dir} . '/' . $d;
            $filename =~ s/\.sql$//;
            IO::File->new($filename, 'w')
                or die "Create of applied file '$filename' failed: $!";
            print "done\n" if $self->{debug};
        }
    }

    print "All done.\n" unless $self->{quiet};

    return $self->{statements} ? @st : @_;
}

# Main method
sub run
{
    my $class = shift;
    my $self = bless {}, $class;

    # Parse arguments
    my @args = @_;
    unless (@args) {
      @args = @ARGV;
      @ARGV = ();
    }
    @args = $self->parse_args(@args);

    # Load applied deltas
    $self->{applied} = $self->load_applied_deltas;

    # Find outstanding deltas
    my @outstanding = $self->find_deltas(@args);
    if (! @outstanding) {
        if (@args) {
            print "$_ already applied.\n" for @args;
        }
        else {
            print "No outstanding deltas found.\n";
        }
        return 0;
    }

    my @return = @outstanding;

    unless ($self->{quiet}) {
      print $self->{update} ? "Applying deltas:\n" : "Outstanding deltas:\n" unless $self->{brief};
      foreach (@outstanding) {
        print $self->{brief} ? '' : '  ';
        print "$_\n";
      }
    }

    @return = $self->apply_deltas(@outstanding) 
      if $self->{update} || $self->{statements};

    return wantarray ? ( scalar(@return), \@return ) : scalar (@return);
}

1;

__END__

=head1 NAME

DBIx::Delta - a module for applying outstanding database deltas
(migrations) to a database instance

=head1 SYNOPSIS

    # Must be used via a subclass providing a db connection e.g.
    package Foo::Delta;
    use base qw(DBIx::Delta);
    use DBI;
    sub connect { 
        DBI->connect('dbi:SQLite:dbname=foo.db');
    }
    1;

    # Then:
    perl -MFoo::Delta -le 'Foo::Delta->run'
    # Or create a delta run script (e.g. delta.pl):
    use Foo::Delta;
    Foo::Delta->run;

    # Then to check for deltas that have not been applied
    ./delta.pl 
    # And to apply those deltas and update the database
    ./delta.pl -u


=head1 DESCRIPTION

DBIx::Delta is a module used to apply database deltas (migrations) to a 
database instance.

It is intended for use in maintaining multiple database schemas in sync
e.g. you create deltas on your development database instance, and
subsequently apply those deltas to your test instance, and then finally
to production.

It is simple and only requires DBI/DBD for your database connectivity.

=head2 DELTAS

Deltas are just '*.sql' files containing arbitrary sql statements, in
your current directory. Any deltas that haven't been seen before are
executed against your database, and if successful, the filename is
recorded in an 'applied' subdirectory, and those deltas are thereafter
ignored. 

This means that you can't change or add to a delta after it has been
applied to the database. Changes to existing database objects must be 
done via new deltas using appropriate 'ALTER' commands.

=head2 USAGE

    # Must be used via a subclass providing a db connection e.g.
    package Foo::Delta;
    use base qw(DBIx::Delta);
    use DBI;
    sub connect { 
        DBI->connect('dbi:SQLite:dbname=foo.db','','');
    }
    1;

    # And then ...
    perl -MFoo::Delta -le 'Foo::Delta->run'


=head2 STATEMENT FILTERING

As of version 0.5 DBIx::Delta supports statement filtering, allowing 
subclasses to do arbitrary munging of statements before they're applied.
This is done by overriding the filter_statement method in your subclass:

    sub filter_statement {
      my ($self, $statement) = @_;

      # Munge $statement

      return $statement;
    }

This can be useful, for instance, if you're doing IP-based grants in your
deltas, and need to use different addresses for your different environments.
For instance, you could use the following grant in your delta (mysql syntax):

    grant all on db.table to user@localhost;

and then modify it in your production DBIx::Delta subclass by doing:

    $statement =~ s/^(grant.*)localhost/${1}192.168.0.10/;


=head1 AUTHOR

Gavin Carr <gavin@openfusion.com.au>

=head1 LICENCE

Copyright 2005-2014, Gavin Carr.

This program is free software. You may copy or redistribute it under the 
same terms as perl itself.

=cut

# vim:sw=4
