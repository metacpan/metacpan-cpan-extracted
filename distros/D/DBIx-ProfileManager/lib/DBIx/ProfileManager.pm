package DBIx::ProfileManager;

use strict;
use warnings;

our $VERSION = '0.03';

use DBI;
use DBI::Profile;
use Scalar::Util qw(weaken);

our %ORIGINAL_METHODS;

sub new {
    my ( $class, %args ) = @_;
    bless +{
        config => $args{config} || '!Statement',
        data => +{},
        path => [],
        is_started => 0,
    } => $class;
}

{
    no strict 'refs';
    for my $attr ( qw/config data path is_started/ ) {
        *{$attr} = sub {
            if ( @_ == 2 ) {
                $_[0]->{$attr} = $_[1];
            }
            else {
                return $_[0]->{$attr};
            }
        };
    }
}

sub profile_start {
    my ( $self, @db_handles ) = @_;

    my $config = $self->config;

    unless ( @db_handles > 0 ) {
        @db_handles = $self->_active_db_handles;
        $ENV{DBI_PROFILE} = $config;
    }
    
    if ( @db_handles > 0 ) {
        for my $dbh (@db_handles) {
            $dbh->{Profile} = $config;
        }
        if ( $db_handles[0] ) {
            $self->path($db_handles[0]->{Profile}{Path});
        }
    }

    $self->data(+{});
    $self->path( [ split(':', $config) ] ) if ( @{$self->path} == 0 );

    {
        no strict 'refs';
        no warnings 'redefine';

        my $pfm = $self;
        weaken( $pfm );

        my $cb = sub {
            my $dbh = shift;
            $pfm->_fetch_profile_data($dbh);
        };

        unless ( exists $DBI::db::{DESTROY} ) {
            *DBI::db::DESTROY = $cb;
        }

        $ORIGINAL_METHODS{disconnect} = \&DBI::db::disconnect;
        *DBI::db::disconnect = sub {
            my $dbh = shift;
            $cb->($dbh);
            $ORIGINAL_METHODS{disconnect}->($dbh);
        };
    };
    
    $self->is_started(1);
}

sub profile_stop {
    my $self = shift;
    return unless ($self->is_started);
    my @db_handles = $self->_active_db_handles;

    delete $ENV{DBI_PROFILE};
    delete $DBI::db::{DESTROY};
    
    for my $dbh (@db_handles) {
        $self->_fetch_profile_data( $dbh );
    }

    {
        no warnings 'redefine';
        *DBI::db::disconnect = $ORIGINAL_METHODS{disconnect};
    };
    
    $self->is_started(0);
}

sub data_formatted {
    my ($self, $format, @results) = @_;
    $format ||= '%{statement} : %{total}s / %{count} = %{avg}s avg (first %{first}s, min %{min}s, max %{max}s)';
    @results = $self->data_structured unless ( @results > 0 );
    my @formatted;

    for my $result ( @results ) {
        my $log = $format;
        $log =~ s/%\{?([\w_]+)\}?/(exists $result->{$1})?$result->{$1}:sprintf('%%{%s}',$1)/gex;
        push(@formatted, $log);
    }

    return wantarray ? @formatted : join("\n", @formatted);
}

sub data_structured {
    my $self = shift;
    my $data = $self->data;
    my @results;
    for my $dsn ( keys %$data ) {

        my $depth = 0;
        my $profile_data = $self->_data_structured_recursive(
            +{ dsn => $dsn }, $data->{$dsn}, \@results, $depth,
        );
    }

    return wantarray ? @results : \@results;
}

sub _fetch_profile_data {
    my ( $self, $dbh ) = @_;

    return unless ( exists $dbh->{Profile} && defined $dbh->{Profile}{Data} );
    my $dsn = sprintf( 'dbi:%s:%s', $dbh->{Driver}{Name}, $dbh->{Name} );
    return if ( exists $self->data->{$dsn} );
    
    $self->data->{$dsn}
      = +{
        map { $_ => $dbh->{Profile}{Data}{$_} }
        grep { length $_ } keys %{ $dbh->{Profile}{Data} }
      };
    $dbh->{Profile}{Data} = undef;
}

sub _active_db_handles {
    my %drhs = DBI->installed_drivers;
    my @handles;
    for my $drh ( values %drhs ) {
        for my $dbh ( grep { $_->{Active} } @{ $drh->{ChildHandles} } ) {
            push( @handles, $dbh );
        }
    }
    wantarray ? @handles : \@handles;
}

sub _data_structured_recursive {
    my ($self, $default, $data, $results, $depth) = @_;

    if ( @{$self->path} == $depth ) {
        my %profile_data = %$default;
        @profile_data{qw/count total first min max start end/} = @$data;
        $profile_data{avg} = $profile_data{total} / $profile_data{count};
        
        push( @$results, \%profile_data );
        return;
    }

    my $sp_const = lcfirst(substr($self->path->[$depth], 1));
    $sp_const =~ s/([A-Z])/'_'.lc($1)/gex;
    $sp_const =~ s/\~/_/g;
    
    for my $key ( keys %$data ) {
        $default->{$sp_const} = $key;
        $self->_data_structured_recursive( $default, $data->{$key}, $results, $depth + 1 );
    }
}

1;
__END__

=for :stopwords attr avg dsn min params DBI SQL formatters profiler unformatted

=head1 NAME

DBIx::ProfileManager - Helps to fine control your DBI profiling without hassles

=head1 SYNOPSIS

  use DBI;
  use DBIx::ProfileManager;

  my $dbh = DBI->connect(...);

  # enable profiling of all the active handle(s)
  my $pm = DBIx::ProfileManager->new;
  $pm->profile_start;

  # do something with the handle
  my $res = $dbh->selectall_arrayref(...);

  $pm->profile_stop;
  my @results = $pm->data_formatted;
  local $, = "\n";
  print @results;

=head1 DESCRIPTION

L<DBI> has a built-in profiler named L<DBI::Profile>. You can use it
just by setting the C<DBI_PROFILE> environmental variable to something
DBI understands. This is quite handy and works beautifully when your
code is small, but doesn't help much when your application grows.
You get too much.

You might want to embed this variable in your code to limit its effect,
which works, but only if you set it before you instantiate DBI handles,
and that doesn't always happen in the same block you want to profile.

You can also enable profiler by setting the C<Profile> attribute of
each handle you want to profile. This also works, though tedious
especially if you have multiple handles to profile and/or want to
do something with the profile data.

L<DBIx::ProfileManager> allows you to add SQL performance profiler
to wherever you want with a few lines of code. It looks for active
DBI handles, and applies your configuration to each of them. When
you stop profiling, it collects the result from the handles.
It also provides custom formatters. You can pass the formatted
string(s) to your application's logger, or to anything you like,
instead of simply printing it to the screen.

=head1 METHODS

=head2 new(%args)

Creates a manager object to control flow and hold profile data.
Available option(s) are:

=over

=item config

The value you want to pass to the C<Profile> attribute of DBI handles
(C<!Statement> by default).

=back

=head2 profile_start(@db_handles)

Sets the configuration to each of the @db_handles (or all the active
handles if you don't pass anything) to start profiling.

=head2 profile_stop()

Stops profiling and store the data into the manager object for later
use. You can pass all the handles will be affected.

=head2 data_formatted($format)

Returns an array of formatted strings (or a concatenated string in
the scalar context) of the profile data. You can use the following
special strings for convenience like this:

  $pm->data_formatted( q|%{statement} : %{max}, %{min}, %{avg}| );

=over

=item statement, method_name, method_class, caller, caller2, file, file2, time, time_{n}

Each of these corresponds with C<!Statement>, C<!MethodName>, and
the likes. See L<DBI::Profile#Special Constant> for details.

=item count, total, first, min, max, start, end

Each of these corresponds with the column of a profile data node,
which is described in L<DBI::Profile#OVERVIEW> as follows.

  [
    106,                  # 0: %{count} of samples at this node
    0.0312958955764771,   # 1: %{total} duration
    0.000490069389343262, # 2: %{first} duration
    0.000176072120666504, # 3: shortest duration (%{min})
    0.00140702724456787,  # 4: longest duration (%{max})
    1023115819.83019,     # 5: time of first sample (%{start})
    1023115819.86576,     # 6: time of last sample (%{end})
  ]

=item avg

Average duration (= %{total} / %{count})

=item dsn

A DSN string you passed to the DBI handle you're profiling.

=back

=head2 data_structured()

Returns raw, unformatted data structure of the profile data.

=head2 data, config, path, is_started

These are accessors for the manager attributes of the name.

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou@cpan.orgE<gt>

=head1 SEE ALSO

=over

=item L<DBI>

=item L<DBI::Profile>

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
