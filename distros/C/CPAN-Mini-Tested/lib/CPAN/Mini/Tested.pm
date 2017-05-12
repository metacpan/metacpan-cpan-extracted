package CPAN::Mini::Tested;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.23';

#--------------------------------------------------------------------------

###########################################################################
# Inheritence

use base 'CPAN::Mini';

###########################################################################
# Modules

use Cache::Simple::TimedExpiry  0.22;
use Config;
use DBI;
use DBD::SQLite                 1.00;
use File::Basename              qw( basename );
use File::Spec::Functions       qw( catfile );
use LWP::Simple                 qw( mirror RC_OK RC_NOT_MODIFIED );
use Regexp::Assemble            0.06;

###########################################################################
# Variables

my $TESTDB  = 'cpanstats.db';
my $TESTURL = 'http://devel.cpantesters.org/cpanstats.db';

#--------------------------------------------------------------------------

###########################################################################
# Public Interface

sub file_allowed {
    my ($self, $file) = @_;
    return (basename($file) eq $TESTDB) ? 1 :
        CPAN::Mini::file_allowed($self, $file);
}

sub mirror_indices {
    my $self = shift;

    warn "test_db_arch is deprecated"   if(defined $self->{test_db_arch});

    $self->{test_db_file} ||= catfile($self->{local}, $TESTDB);
    my $local_file = $self->{test_db_file};

    # test_db_age < 0, do not update it

    my $test_db_age = $self->{test_db_age};
    $test_db_age = 1, unless (defined $test_db_age);

    if (    $self->{force}
         || !-e $local_file
         || (   $test_db_age >= 0 
             && -e $local_file 
             && -M $local_file > $test_db_age) ) {

        $self->trace($TESTDB);
        my $db_src = $self->{test_db_src} || $TESTURL;
        my $status = mirror($db_src, $local_file);

        if ($status == RC_OK) {
            $self->trace(" ... updated\n");
        } elsif ($status == RC_NOT_MODIFIED) {
            $self->trace(" ... up to date\n");
        } else {
            warn "\n$db_src: $status\n";
            return;
        }
    }

    $self->_connect() if (-r $local_file);

    return CPAN::Mini::mirror_indices($self);
}

sub clean_unmirrored {
    my $self = shift;
    $self->_disconnect();
    return CPAN::Mini::clean_unmirrored($self);
}

###########################################################################
# Private Methods

sub _dbh {
    my $self = shift;
    return $self->{test_db};
}

sub _sth {
    my $self = shift;
    return $self->{test_db_sth};
}

sub _connect {
    my ($self, $database)  = @_;

    $database ||= $self->{test_db_file};
    die "Cannot find database file" unless (-r $database);

    $self->{test_db} = DBI->connect(
        "DBI:SQLite:dbname=".$database, "", "", {
            RaiseError => 1,
            %{$self->{test_db_conn} || { }},
        },
    ) or die "Unable to connect: ", $DBI::errstr;

    # TODO: support for additional reports fields such as perl version

    $self->{test_db_sth} =
        $self->_dbh->prepare( qq{
            SELECT COUNT(id) 
              FROM cpanstats
             WHERE status='PASS' 
               AND dist=? 
               AND version=? 
               AND osname=?
    }) or die "Unable to create prepare statement: ", $self->_dbh->errstr;

    return 1;
}

sub _disconnect {
    my $self = shift;
    if ($self->_dbh) {
        $self->_sth->finish if ($self->_sth);
        $self->_dbh->disconnect;
    }
    return 1;
}

sub _check_db {
    my ($self, $dist, $ver, $osname) = @_;

    my $sth = $self->_sth;
    die "Not connected to the database\n"   unless ($sth);

    $sth->execute($dist, $ver, $osname);
    my $row = $sth->fetch;

    return $row->[0]    if($row);
    return 0;
}

sub _reset_cache {
    my $self = shift;
    $self->{test_db_cache} = undef, if ($self->{test_db_cache});
    $self->{test_db_cache} = Cache::Simple::TimedExpiry->new;
    $self->{test_db_cache}->expire_after($self->{test_db_cache_expiry} || 300);
}

sub _passed {
    my ($self, $path) = @_;

    # CPAN::Mini 0.36 no longer calls the filter routine multiple times
    # per module, but it will for packages with multiple modules. So we
    # cache the results, but only for a limited time.

    $self->_reset_cache unless (defined $self->{test_db_cache});

    if ($self->{test_db_exceptions}) {

        if (ref($self->{test_db_exceptions}) eq "CODE") {
            return 1, if ( &{ $self->{test_db_exceptions} }($path) );
        } else {
            my $re = new Regexp::Assemble;

            if (ref($self->{test_db_exceptions}) eq "ARRAY") {
	            $re->add( @{ $self->{test_db_exceptions} } );
            } elsif ( (!ref($self->{test_db_exceptions})) || (ref($self->{test_db_exceptions}) eq "Regexp") ) {
	            $re->add( $self->{test_db_exceptions} );
            } else {
	            die "Unknown test_db_exception type: ", ref($self->{test_db_exceptions});
            }

            return 1, if ($path =~ $re->re);
        }
    }

    return $self->{test_db_cache}->fetch($path) if ($self->{test_db_cache}->has_key($path));

    my $count = 0;

    my $distver = basename($path);
    $distver =~ s/\.(tar\.gz|tar\.bz2|zip)$//;

    my $x       = rindex($distver, '-');
    my $dist    = substr($distver, 0, $x);
    my $ver     = substr($distver, $x+1);

    $self->{test_db_os} ||= $Config{osname};

    if (ref($self->{test_db_os}) eq 'ARRAY') {
        my @archs = @{ $self->{test_db_os} };
        while ( (!$count) && (my $arch = shift @archs) ) {
            $count += $self->_check_db($dist, $ver, $arch);
        }
    } else {
        $count += $self->_check_db($dist, $ver, $self->{test_db_os});
    }

    $self->{test_db_cache}->set($path, $count);

    return $count;
}

# TODO: if filtering in CPAN::Mini is changed to allow paths to be
# munged, then we can add the option to fall back to the latest
# version which passes tests.

sub _filter_module {
    my ($self, $args) = @_;
    return CPAN::Mini::_filter_module($self, $args)
        || (!$self->_passed($args->{path}));
}

1;

__END__

=head1 NAME

CPAN::Mini::Tested - Create a CPAN mirror using modules with passing test reports

=head1 SYNOPSYS

  use CPAN::Mini::Tested;

  CPAN::Mini::Tested->update_mirror(
      remote => "http://cpan.mirrors.comintern.su",
      local  => "/usr/share/mirrors/cpan",
      trace  => 1
  );

=head1 DESCRIPTION

This module is a subclass of L<CPAN::Mini> which checks a CPAN
Testers database for passing tests of that distribution on your
platform. Distributions will only be downloaded if there have passing
test reports.

The major differences are that it will download the F<testers.db> file
from the CPAN Testers web site when updating indices, and it will
check if a distribution has passed tests in the specified platform
before applying other filtering rules to it.

The following additional options are supported:

=over

=item test_db_exceptions

A Regexp or array of Regexps (or Regexp strings) of module paths that
will be included in the mirror even if there are no PASS reports for
them.

If it is a code reference, then it refers to a subroutine which takes
the module path as an argument and returns true if it is an exception.

Note that if these modules are already in the exclusion list used by
L<CPAN::Mini>, then they will not be included.

=item test_db_age

The maximum age of the local copy of the testers database, in
days. The default is C<1>.

When set to C<0>, or when the C<force> option is set, the latest copy
of the database will be downloaded no matter how old it is.

When set to C<-1>, a new copy will never be downloaded.

Note that the testers database can be quite large (over 15MB).

=item test_db_src

Where to download the latest copy of the CPAN Testers database. Defaults to
L<http://devel.cpantesters.org/cpanstats.db>, however please note this file 
is no longer updated since April 2013.

=item test_db_file

The location of the local copy of the CPAN Testers database. Defaults to
the root directory of C<local>.

=item test_db_os

The platform that tests are expected to pass.  Defaults to the current
platform C<$Config{osname}>.

If this is set to a list of platforms (an array reference), then it
expects tests on any one of those platforms to pass.  This is useful
for maintaining a mirror that supports multiple platforms, or in cases
where there tests are similar platforms are acceptable.

=item test_db_conn

Connection parameters for L<DBI>. In most cases these can be ignored.

=item test_db_cache_expiry

The number of seconds it caches database queries. Defaults to C<300>.

CPAN::Mini will check the filters multiple times for distributions
that contain multiple modules. (Older versions of CPAN::Mini will
check the filters multiple times per module.)  Caching the results
improves performance, but we need to maintain the results for very
long, nor do we want all of the results to use memory.

=back

=head2 Subclassed Methods

The following methods are subclasses from L<CPAN::Mini>:

=over

=item _filter_module

In addition to noting if a module is in the exclusion list, it also
notes if it has not passed any tests.

=item mirror_indices

Downloads the latest F<cpanstats.db> database file (if needed) and
connects to the database before it begins downloading indices.

=item file_allowed

Also notes if the file is the F<cpanstats.db> databse file.

=item clean_unmirrored

Disconnects from the database before cleaning files.

=back

=head1 CAVEATS

This module is only of use if there are active testers for your
platform.

Note that the lack of passing tests in the testers database does not
mean that a module will not run on your platform, only that it will
not be downloded. (There may be a lag of several days before test
results of the newest modules appear in the database.)  Likewise,
passing tests do not mean that a module will run on your platform.

If the way filters are handled in CPAN::Mini is changed in the future,
then some of these issues can be resolved by downloading the most
recent version which has passed tests.

=head1 SEE ALSO

L<CPAN::Mini>

L<CPAN::WWW::Testers>

CPAN Testers L<http://cpantesters.org>

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>

Barbie <barbie@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2014 by Robert Rothenberg.  All Rights Reserved.
Copyright (C) 2014      by Barbie.

This distribution is free software; you can redistribute it and/or
modify it under the Artistic Licence v2.

=cut
