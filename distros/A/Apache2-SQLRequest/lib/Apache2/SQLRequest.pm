package Apache2::SQLRequest;

=head1 NAME

Apache2::SQLRequest - Supply SQL queries to an Apache request object

=head1 VERSION

Version 0.02

=cut

use strict;
use warnings FATAL => 'all';

use mod_perl2 1.999023   ();

# this breaks for some reason
#use base qw(Apache2::RequestRec);

use Apache2::SQLRequest::Config ();

use Apache2::RequestRec  ();
use Apache2::RequestUtil ();
use Apache2::Module      ();
use Apache2::Log         ();

use Apache2::Const   -compile => qw(OK SERVER_ERROR);
#use APR::Const      -compile => qw(SUCCESS :error);

#use DBI     ();
use Carp    ();

our @ISA = qw(Apache2::RequestRec);
our $VERSION = '0.02';
my  %DBCONNS; # do i want to do this?

=head1 SYNOPSIS

    # httpd.conf

    PerlLoadModule Apache2::SQLRequest
    DSN         dbi:Foo:Bar
    DBUser      foo
    DBPassword  bar
    <Location /foo>
    SQLQuery dummy "SELECT DUMMY FROM DUAL WHERE DUMMY = :y"
    BindParameter dummy y X
    </Location>

=head1 DESCRIPTION

This module functions as a base class for containing preloaded SQL
queries. It supplies methods to bind parameters, execute queries
and access record sets.

=cut

sub new {
    my $class   = shift;
    my $r       = bless { r => shift };
    my $log     = $r->log;

    my $conf    = Apache2::Module::get_config
        (__PACKAGE__.'::Config', $r->server);
    my $dconf   = Apache2::Module::get_config
        (__PACKAGE__.'::Config', $r->server, $r->per_dir_config);

    map { $r->{$_} ||= defined $dconf->{$_} ? $dconf->{$_} : 
      defined $conf->{$_} ? $conf->{$_} : '' } qw(dsn user password);

    # guarantee the dbi 
    $r->log->debug(sprintf("dsn: '%s', user: '%s', pass: '%s'", 
        map { defined $_ ? $_ : '' } @{$r}{qw(dsn user password)}));
    require DBI;
    $r->log->debug("DBI loaded.");
    my $dbh     = $r->{dbh}  = $DBCONNS{$r->{dsn}} ||= 
    #join(" ", @{$r}{qw(dsn user password)});
        DBI->connect(@{$r}{qw(dsn user password)}) or die 
        "Cannot connect to database with dsn $r->{dsn}: " .  DBI->errstr;
    $r->log->debug("DBI really loaded.");

    # configuration is transient
    $r->{sth} ||= {};
    for my $query (keys %{$dconf->{queries}}) {
        my $c = $dconf->{queries}{$query};
        eval { $r->prepare_query($query, $c->{string}) } or do {
            $log->crit($@);
            return Apache2::Const::SERVER_ERROR;
        };
    }
    $r;
}

sub prepare_query {
    my ($r, $qname, $query) = @_;
    Carp::croak("Query $qname is already cached") if defined $r->{sth}{$qname};
    $r->{sth}{$qname} = eval { $r->{dbh}->prepare($query) } or Carp::croak
        ("Cannot prepare configured SQL query: " . $r->{dbh}->errstr);
}

sub sth {
    my ($r, $qname) = @_;
    Carp::croak("Must supply name of query") unless defined $qname;
    my $sth = $r->{sth}{$qname};
    Carp::croak("Cannot find statement handle for query $qname.")
        unless defined $sth;
    $sth;
}

sub bind_query {
    my ($r, $qname, $params) = @_;
    my $sth = eval { $r->sth($qname) };
    Carp::croak $@ if $@;
    my %p;
    if (defined $params) {
        if (UNIVERSAL::isa($params, 'ARRAY')) {
            %p = map { $_+1 => $params->[$_] } (0..$#$params);
        }
        elsif (UNIVERSAL::isa($params, 'HASH')) {
            %p = %$params;
        }
        else {
            Carp::croak("params passed are not an ARRAY or HASH ref.");
        }
    }
    %p = (%p, %{$r->{conf}{queries}{$qname}{params}||{}});
    for my $k (keys %p) {
        Carp::croak("Attempt to bind parameter $k failed: " . $sth->errstr)
            unless ($sth->bind_param(":$k", $p{$k}));
    }
    #APR::SUCCESS;
    0E0;
}

sub execute_query {
    my ($r, $qname, @params) = @_;
    my $sth = eval { $r->sth($qname) };
    Carp::croak $@ if $@;
    if (@params) {
        my $param = @params > 1 ? [@params] : $params[0];
        eval { $r->bind_query($qname, $param) };
        Carp::croak $@ if $@;
    }
    $sth->execute;
}

sub fetchrow_arrayref {
    my ($r, $qname) = @_;
    my $sth = eval { $r->sth($qname) };
    Carp::croak $@ if $@;
    $sth->fetchrow_arrayref;
}

sub fetchrow_hashref {
    my ($r, $qname) = @_;
    my $sth = eval { $r->sth($qname) };
    Carp::croak $@ if $@;
    $sth->fetchrow_hashref;
}

sub handler : method {
    my $class   = shift;
    my $r       = new($class, shift);
    return Apache2::Const::OK;
}

=head1 AUTHOR

dorian taylor, C<< <dorian@icrystal.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-apache-sqlrequest@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2004 dorian taylor, iCrystal Software, Inc. All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Apache2::SQLRequest
