package Class::DBI::ViewLoader::Auto;

use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME

Class::DBI::ViewLoader::Auto - Load views for existing Class::DBI classes

=head1 SYNOPSIS

    package MyMovieClass;

    use strict;
    use warnings;

    use Class::DBI;
    use Class::DBI::ViewLoader::Auto;

    our @ISA = qw( Class::DBI );

    __PACKAGE__->connection('dbi:Pg:dbname=mymoviedb', 'me', 'mypasswd');

    # load views from database mymoviedb to MyMovieClass::*
    @loaded = __PACKAGE__->load_views();

    # load only views starting with film_
    @loaded = __PACKAGE__->load_views(qr/^film_/);

    # or pass more options:
    @loaded = __PACKAGE__->load_views(
            namespace => 'MyMovieClass::View',
            exclude => qr(^test_),
        );

=head2 DESCRIPTION

This module provides a simpler interface to Class::DBI::ViewLoader.

=cut

use Carp qw( croak );
use Exporter;

use Class::DBI::ViewLoader;

our @ISA    = qw( Exporter );
our @EXPORT = qw( load_views );

=head1 EXPORTS

This module exports the load_views method into the calling package

=cut

=head1 METHODS

=head2 load_views

    $loader = $cdbi_class->load_views( %opts or $include )

Loads views from the database connection in $cdbi_class.

The default namespace is the same as the calling class.

%opts is passed to the Class::DBI::Loader constructor. If a scalar argument is
given instead of a hash or hashref, it is interpreted as being the include
pattern.

The options dsn, username, password and options are silently ignored.

$cdbi_class should always be the leftmost base class of the generated classes.
base_classes and left_base_classes options are supported, but it might make more
sense to add those bases to the calling class manually.

Returns the same as Class::DBI::ViewLoader->load_views, i.e. a list of loaded
classes.

=cut

# Class::DBI::ViewLoader options to ignore
my @unsupported = qw( dsn username password options );

sub load_views {
    my $class = shift;
    my %opts;

    if (@_ == 1) {
        my $proto = shift;
        if (ref $proto eq 'HASH') {
            %opts = %$proto;
        }
        else {
            $opts{'include'} = $proto;
        }
    }
    else {
        %opts = @_;
    }

    delete @opts{@unsupported};
    $opts{'namespace'} ||= $class;

    Class::DBI::ViewLoader->_compat(\%opts);

    my $sub = $class->can('db_Main')
        or croak "$class has no connection";

    my $dbh = &$sub($class);
    my $driver = $dbh->{'Driver'}->{'Name'};

    return Class::DBI::ViewLoader->new(%opts)
                                 ->_load_driver($driver)
                                 ->_set_dbi_handle($dbh)
                                 ->_set_keepalive(1)
                                 ->add_left_base_classes($class)
                                 ->load_views;
}

1;

__END__

=head1 DIAGNOSTICS

=head2 %s has no connection

The given class had no connection set up to read views from.

=cut

vim: ts=8 sts=4 sw=4 noet sr
