package DBIx::Factory;

use Moose;
use namespace::autoclean;
use Scalar::Util qw/ blessed /;
use Config::Any;
use File::Spec;
use DBI;

our $VERSION = "0.09";

has "config_base" => (
    is       => "ro",
    isa      => "Str",
    required => 1,
    default  => sub { defined $ENV{DBIF_BASE} ? $ENV{DBIF_BASE} : q{} },
);

has "config_file" => (
    is       => "rw",
    isa      => "Str",
    required => 1,
    default  => q{},
);

around BUILDARGS => sub {
    my ($next_method, $class, @args) = @_;

    $class->$next_method(
        _isa_str(@args) ? ( config_base => $args[0] ) : @args
    );
};

sub get_dbh {
    my ($class_or_self, @args) = @_;
    my $self;

    if ( blessed $class_or_self ) {
        $self = $class_or_self;
        $self->config_file( $args[0] ) if _isa_str(@args);
    }
    else {
        $self = $class_or_self->new(
                _isa_str(@args) ? ( config_file => $args[0] ) :
            _has_odd_elm(@args) ? ( @args, undef )            : @args
        );
    }

    $self->_get_dbh(
        _is_empty($self->config_file) ?
            ( ref $args[0] ? $args[0] : [@args] ) : $self->_get_config
    );
}

sub _get_config {
    my $self = shift;

    my ($file, $dir) = ($self->config_file, $self->config_base);
    my $path
        = ( _is_abs_path($file) or _is_empty($dir) ) ? $file :
                                       join "/", $dir, $file ;

    Config::Any->load_files(
        { files => [$path], use_ext => 1, flatten_to_hash => 1 }
    )->{$path}
        or confess "failed to read config file: $path\n";
}

sub _get_dbh {
    my ($self, $args) = @_;

    DBI->connect(
        _isa_hashref($args) ? @$args{qw/ dsn userid passwd attr /} : @$args
    );
}

sub _isa_str     { @_ == 1 and not ref $_[0]                }

sub _isa_hashref { ref $_[0] eq "HASH"                      }

sub _is_abs_path { File::Spec->file_name_is_absolute($_[0]) }

sub _is_empty    { $_[0] eq q{}                             }

sub _has_odd_elm { @_ % 2                                   }

__PACKAGE__->meta->make_immutable;

1; # End of DBIx::Factory

__END__

=head1 NAME

DBIx::Factory - a simple factory class for DBI database handle

=head1 SYNOPSIS

  # ... preparing to use ...

  $ cat > /config/base/dir/oracle/xe.yaml
  userid: bahoo
  passwd: typer
  dsn:    dbi:Oracle:XE
  attr:
    RaiseError:  0
    PrintError:  1
    LongReadLen: 2079152

  # ... and in your script ...

  # as a class method
  my $dbh = DBIx::Factory->get_dbh(
      config_base => "/config/base/dir",
      config_file => "oracle/xe.yaml"
  );

  # or simply...
  # (in this case, $ENV{DBIF_BASE} is used as config_base.
  #  if not also defined $ENV{DBIF_BASE}, the argument specified
  #  is assumed as a relative path from your current directory)
  my $dbh = DBIx::Factory->get_dbh("oracle/xe.yaml");

  # you can also specify it as an absolute path from '/'
  # (and config_base is ignored even if it is specified)
  my $dbh = DBIx::Factory->get_dbh("/config/base/dir/oracle/xe.yaml");

  # or you can even do just like DBI::connect
  my $dbh = DBIx::Factory->get_dbh("dbi:Oracle:XE", "bahoo", "typer");

  # as an instance method
  my $factory = DBIx::Factory->new("/config/base/dir");
  my $dbh     = $factory->get_dbh("oracle/xe.yaml");

  # when you set RaiseError attr to 1 in your config file
  my $dbh = eval { $factory->get_dbh("oracle/xe.yaml") };
  die $@ if $@;

=head1 ABSTRACT

When you release applications which use L<DBI>, you're putting
the same database connection info into different files every time,
aren't you? This module is useful for collecting up those info
into a single file, simplifying managing them, and also a little bit
simplifies making connection to the databases.

=head1 PREPARATION

After installation, you can first decide which directory is
the base directory where connection info files reside. Then,
you can create file(s) that contain database connection info,
one info per one file.

Each connection info can be described in any format
which L<Config::Any> covers, parsed properly according to
the file extension, but must contain some items as follows:

  userid
  passwd
  dsn
  attr

These items must be hash keys that contain simple string values,
except C<attr> must contain hash for connection attributes such
as C<RaiseError>, C<AutoCommit> or so. See L</SYNOPSIS> for
a simple example.

Created connection info file(s), you can place them under
the base directory. You can create any level of subdirectories
(such as "oracle", "host1/mysql" and so on) to simplify managing
those files.

You can also place connection info file(s) anywhere else, when
you don't decide the base directory. In this case, you would
use connection info file(s) by specifying their absolute paths
from "/", or relative paths from your current directory.

Besides, you can get connection without any connection info file,
by passing args to L</get_dbh> just like L<DBI::connect>.

=head1 METHODS

=head2 new

Creates a new instance of DBIx::Factory. It can take one argument,
which is the base directory of the connection info files. If no
argument is specified, it assumes that C<$ENV{DBIF_BASE}> or
an empty string (which is later assumed as your current directory)
are specified as the base directory.

When L</get_dbh> method is invoked as a class method, L</new>
will then be invoked internally.

=head2 get_dbh

There are two ways that you can invoke this method. The first is to
invoke this method as a class method. Doing so, this method will
take either hash argument which contains two keys, C<config_base>
(which is the base directory of the connection info files) and
C<config_file> (path from config_base to the specific connection
info file) with their values, or a simple string value which is
used as C<config_file>, while $ENV{DBIF_BASE} or an empty string
(if the $ENV is not defined) are used as C<config_base>.
Both C<config_base> and C<config_file> are passed to L</new> method
which will then be invoked.

The second way is to invoke this method as an instance method.
Doing so, this method will take a single string argument which
is used as C<config_file>.

Either way, please note that if you specify an absolute path
(which leads with '/') as C<config_file>, then C<config_base>
is always ignored.

If the specified connection info file is unreadable,
this method will throw an exception. The same is true when C<RaiseError>
attribute is on and actually error happened while connecting to the
database.

Besides, when invoking as either a class method or an instance method,
you can even pass the args just like when you call L<DBI::connect>.

=head1 AUTHOR

Bahootyper, C<< <bahootyper at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests, or funny english found
in this documentation to C<bug-dbix-factory at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Factory>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Factory

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Factory>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Factory>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Factory>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Factory/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Bahootyper.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
