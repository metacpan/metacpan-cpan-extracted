use 5.006;    # our
use strict;
use warnings;

package App::cpanoutdated::fresh;

our $VERSION = '0.001006';

# ABSTRACT: Indicate out-of-date modules by walking the metacpan releases backwards

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Carp qw( croak );
use Moo qw( has );
use MooX::Lsub qw( lsub );
use Getopt::Long;
use Search::Elasticsearch;
use Module::Metadata;
use Path::ScanINC;
use Pod::Usage qw( pod2usage );
use version;





has ua => ( is => 'ro', predicate => 'has_ua' );
lsub trace => sub { undef };
lsub es => sub {
  my ($self) = @_;
  my %args = (
    nodes            => 'api.metacpan.org',
    cxn_pool         => 'Static::NoPing',
    send_get_body_as => 'POST',

    #    trace_to         => 'Stderr',
  );
  if ( $self->has_ua ) {
    $args{handle} = $self->ua;
  }
  if ( $self->trace ) {
    $args{trace_to} = 'Stderr';
  }
  return Search::Elasticsearch->new(%args);
};
lsub _sort       => sub { 'desc' };
lsub scroll_size => sub { 1000 };
lsub age         => sub { '7d' };
lsub age_seconds => sub {
  my ($self) = @_;
  my $table = {
    'm' => (60),
    'h' => ( 60 * 60 ),
    's' => (1),
    'd' => ( 24 * 60 * 60 ),
    'w' => ( 7 * 24 * 60 * 60 ),
    'M' => ( 31 * 24 * 60 * 60 ),
    'Y' => ( 365 * 24 * 60 * 60 ),
  };
  return $self->age + 0 if $self->age =~ /\A\d+([.]\d+)?\z/msx;
  if ( my ( $time, $multiplier ) = $self->age =~ /\A(\d+)([[:alpha:]]+)\z/msx ) {
    if ( not exists $table->{$multiplier} ) {
      croak("Unknown time multiplier <$multiplier>");
    }
    return $time * $table->{$multiplier};
  }
  croak( 'Cant parse age <' . $self->age . '>' );
};
lsub min_timestamp => sub {
  my ($self) = @_;
  return time() - $self->age_seconds;
};
lsub developer    => sub { undef };
lsub all_versions => sub { undef };
lsub authorized   => sub { 1 };
lsub _inc_scanner => sub { Path::ScanINC->new() };

sub _es_version {
  my ( $self, $wanted_version ) = @_;
  local $@ = undef;
  return eval { $self->es->VERSION($wanted_version); 1 };    ## no critic (RequireCheckingReturnValueOfEval)
}

sub _mk_scroll {
  my ($self) = @_;

  my $body = {
    query => {
      range => {
        'stat.mtime' => {
          gte => $self->min_timestamp,
        },
      },
    },
  };
  if ( not $self->developer or $self->authorized ) {
    $body->{filter} ||= {};
    $body->{filter}->{term} ||= {};
  }
  if ( not $self->developer ) {
    $body->{filter}->{term}->{'maturity'} = 'released';
  }
  if ( $self->authorized ) {
    $body->{filter}->{term}->{'authorized'}        = 'true';
    $body->{filter}->{term}->{'module.authorized'} = 'true';
  }

  my $fields = [
    qw(
      name distribution path
      stat.mtime module author
      authorized date indexed
      directory maturity release
      status version
      ),
  ];

  my %scrollargs = (
    scroll => '5m',
    index  => 'v0',
    type   => 'module',
    size   => $self->scroll_size,
    body   => $body,
    ( $self->_es_version(5) ? 'stored_fields' : 'fields' ) => $fields,
  );
  if ( not $self->_sort ) {
    $scrollargs{'search_type'} = 'scan';
  }
  else {
    $body->{sort} = { 'stat.mtime' => $self->_sort };
  }
  ( $self->_es_version(5) )
    ? ( require Search::Elasticsearch::Client::5_0::Scroll )
    : ( require Search::Elasticsearch::Scroll );

  return $self->es->scroll_helper(%scrollargs);
}

sub _check_fresh {
  my ( $self, $data_hash, $module ) = @_;
  return unless $module->{indexed} and $module->{authorized} and $module->{version};

  my (@parts) = split /::/msx, $module->{name};
  $parts[-1] .= '.pm';

  my $file = $self->_inc_scanner->first_file(@parts);
  return unless $file;

  my $mm = Module::Metadata->new_from_file($file);
  return if not $mm;

  my $mm_version = $mm->version;

  my $v = version->parse( $module->{version} );

  if ( not defined $v and not defined $mm_version ) {
    return;
  }
  if ( defined $v and not defined $mm_version ) {

    # noop, upstream got defined vs local, == upgrade
  }
  elsif ( not defined $v and defined $mm_version ) {

    # uhh, have version locally but not upstream, DONT upgrade
    return;
  }
  elsif ( $mm_version >= $v ) {
    return;
  }

  return {
    name      => $module->{name},
    cpan      => ( $v ? $v->stringify : q[0] ),
    release   => $data_hash->{release},
    installed => ( $mm_version ? $mm_version->stringify : q[0] ),
    meta      => $data_hash,
  };

}

sub _get_next {
  my ( $self, $scroll ) = @_;
  if ( not exists $self->{stash_cache} ) {
    $self->{stash_cache} = {};
  }
  if ( not exists $self->{upgrade_cache} ) {
    $self->{upgrade_cache} = {};
  }

  my $stash_cache   = $self->{stash_cache};
  my $upgrade_cache = $self->{upgrade_cache};

  while ( my $scroll_result = $scroll->next ) {
    return unless $scroll_result;
    my $data_hash = $scroll_result->{'_source'} || $scroll_result->{'fields'};

    my $cache_key = $data_hash->{path};
    my $upgrade_key =
        ( $data_hash->{author}       || 'NOAUTHOR' ) . q[/]
      . ( $data_hash->{distribution} || 'NODISTRIBUTION' ) . q[/]
      . ( $data_hash->{version}      || 'NOVERSION' );
    if ( $self->all_versions ) {
      $cache_key = $data_hash->{release};
    }

    #  pp($data_hash);
    next if exists $stash_cache->{$cache_key};
    next if not $self->developer and 'developer' eq $data_hash->{maturity};

    next if $data_hash->{path} =~ /\Ax?t\//msx;
    next unless $data_hash->{path} =~ /[.]pm\z/msx;
    next unless $data_hash->{module};
    next unless @{ $data_hash->{module} };
    for my $module ( @{ $data_hash->{module} } ) {
      my $fresh_data = $self->_check_fresh( $data_hash, $module );
      next unless $fresh_data;
      next if $upgrade_cache->{$upgrade_key};
      $upgrade_cache->{$upgrade_key} = 1;
      $stash_cache->{$cache_key}     = 1;
      return $fresh_data;
    }
    $stash_cache->{$cache_key} = 1;
  }
  return;
}









sub new_from_command {
  my ( $class, $defaults ) = @_;
  Getopt::Long::Configure('bundling');
  $defaults ||= {};
  my ( $help, $man );
  Getopt::Long::GetOptions(
    'age|a=s' => sub {
      my ( undef, $value ) = @_;
      $defaults->{age} = $value;
    },
    'develop|devel|dev!' => sub {
      my ( undef, $value ) = @_;
      if ($value) {
        $defaults->{developer} = 1;
        return;
      }
      $defaults->{developer} = undef;
    },
    'authorized|authed!' => sub {
      my ( undef, $value ) = @_;
      if ($value) {
        $defaults->{authorized} = 1;
      }
      else {
        $defaults->{authorized} = undef;
      }
    },
    'help|h|?' => \$help,
    'man'      => \$man,
  ) or do { $help = 1 };
  if ( $help or $man ) {
    if ($help) {
      return pod2usage( { -exitval => 1, }, );
    }
    return pod2usage( { -exitval => 1, -verbose => 2, }, );
  }
  return $class->new( %{$defaults} );
}









sub run {
  my ($self) = @_;
  my $iterator = $self->_mk_scroll;
  while ( my $result = $self->_get_next($iterator) ) {
    printf "%s\@%s\n", $result->{name}, $result->{cpan};
  }
  return 0;
}









sub run_command {
  my ($class) = @_;
  return $class->new_from_command->run();
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cpanoutdated::fresh - Indicate out-of-date modules by walking the metacpan releases backwards

=head1 VERSION

version 0.001006

=head1 METHODS

=head2 new_from_command

Create an instance of this class parsing options from C<@ARGV>

  my $instance = App::cpanoutdated::fresh->new_from_command;

=head2 run

Execute the main logic and printing found modules to C<STDOUT>

  $object->run;

=head2 run_command

Shorthand for

  $class->new_from_command->run();

=for Pod::Coverage ua has_ua

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
