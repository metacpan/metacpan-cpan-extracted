package Win32::WQL;
use strict;
use Win32::OLE; #  qw(EVENTS);
# Events support will follow later
use base 'Class::Accessor';

=head1 NAME

Win32::WQL - DBI-like wrapper for the WMI

=head1 SYNOPSIS

  use Win32::WQL;
  my $wmi = Win32::WQL->new( machine => 'remote_computer' );
  my $sth = $wmi->prepare(<<'WQL');

    ASSOCIATORS OF {Win32_Directory.Name='C:\\WINNT'}
    WHERE ResultClass = CIM_DataFile

  WQL

  my $remote_files = $sth->execute;
  while (my $file = $remote_files->fetch()) {
      print $file->{Name},"\n";
  };

=head1 OVERVIEW

This module implements a bare bones DBI clone
which is similar yet different. You will most likely
want to use the real thing, L<DBD::WMI>, which
is a compatibility layer over this module.

=cut

use vars qw($VERSION);
$VERSION = '0.07';

Win32::OLE->Option(Warn => 3);

__PACKAGE__->mk_accessors(qw(statement_class event_iterator_class collection_iterator_class wmi));

=head1 METHODS

=head2 C<< new %ARGS >>

Initializes the thin wrapper over the L<Win32::OLE>
WMI instance. All parameters are optional.

  machine

The parameter is the machine name to connect to. It defaults
to the local machine.

  wmi

A preinitialized WMI object to use. Defaults to creating
a fresh instance.

  statement_class

The class into which the results of C<prepare>
are blessed. Defaults to C<Win32::WQL::Statement>.

  event_iterator_class

The class into which the results of C<fetchrow>
are blessed for event queries. Defaults to
C<Win32::WQL::Iterator::Event>.

  collection_iterator_class

The class into which the results of C<fetchrow>
are blessed for static queries. Defaults to
C<Win32::WQL::Iterator::Collection>.

=cut

sub new {
    my ($package, %args) = @_;
    my $machine = delete $args{machine} || '.';
    my $self = {
        wmi             => Win32::OLE->GetObject("winmgmts:\\\\$machine\\root\\cimV2"),
        statement_class => 'Win32::WQL::Statement',
        event_iterator_class  => 'Win32::WQL::Iterator::Event',
        collection_iterator_class  => 'Win32::WQL::Iterator::Collection',
        %args,
    };
    $package->SUPER::new($self);
};

=head2 C<< $wmi->prepare QUERY >>

Returns a prepared query by calling

    return $self->statement_class->new({
        query => $query,
        wmi => $self,
        iterator_class => $class,
        wmi_method => $method,
    });

=cut

sub prepare {
    my ($self,$query) = @_;

    my ($class,$method,$fetch);
    if ($self->event_query($query)) {
        $class = $self->event_iterator_class;
        $method = 'ExecNotificationQuery';
    } else {
        $class = $self->collection_iterator_class;
        $method = 'ExecQuery';
    };

    return $self->statement_class->new({
        query => $query,
        wmi => $self,
        iterator_class => $class,
        wmi_method => $method,
    });
}

=head2 C<< $wmi->event_query QUERY >>

Determines whether a query is an event query
or a static query.

Event queries return a row whenever a new event
arrives and block if there is no event available.

Static queries are static and return all rows in
one go.

A query is considered an event query if it
matches

     $query =~ /\b__instance(?:\w+)event\b/i
  or $query =~ /\wEvent\b/i

=cut

sub event_query {
    my ($package, $query) = @_;
    return
    (   $query =~ /\b__instance(?:\w+)event\b/i
     or $query =~ /\wEvent\b/i
    )
}

package Win32::WQL::Statement;
use strict;
use Win32::OLE;
use base 'Class::Accessor';

__PACKAGE__->mk_accessors(qw(iterator_class wmi query wmi_method));

sub execute {
    my ($self) = @_;
    my $m = $self->wmi_method;
    my $i = $self->wmi->wmi->$m( $self->query );
    return $self->iterator_class->new({
        wql_iterator => $i
    });
}

package Win32::WQL::Iterator::Collection;
use strict;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(wql_iterator items));

use Win32::OLE qw(in);
use Data::Dumper;

# Finite, prefetched list

sub new {
    my ($package,$args) = @_;
    my @items = in delete $args->{wql_iterator};
    $args->{items} = \@items;
    $package->SUPER::new($args);
}

sub fetchrow {
    my ($self) = @_;
    if (@{ $self->items }) {
        shift @{ $self->items };
    } else {
        return ()
    };
}

package Win32::WQL::Iterator::Event;
use strict;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(wql_iterator));

# potentially infinite list

sub fetchrow {
    my ($self) = @_;
    return $self->wql_iterator->NextEvent();
}

1;

=head1 SEE ALSO

L<DBD::WMI> for more examples

=head1 TODO

=over 4

=item * Implement parameters for and credentials

=item * Implement a multiplexer by using multiple, waiting threads so you can C<SELECT>
events from more than one WMI namespace

=back

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/dbd-wmi>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=DBD-WMI>
or via mail to L<www-mechanize-phantomjs-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2009-2015 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
