package Data::Shared::Storage;
use strict;
use warnings;
use Carp ();
use Scalar::Util ();
use Data::Shared::Manifest ();

our $VERSION = '0.01';

our @CARP_NOT = qw(Data::Shared Data::Shared::Manifest Data::Shared::Storage
                   Data::Shared::Composite);
my %LOADED;

sub plan {
    my ($root, $resolved, $name, $args) = @_;
    my $class = $resolved->{class};
    my @args = @$args;
    my $plan = { resolved => $resolved, name => $name, args => \@args, paths => [] };
    my @explicit;
    $plan->{kind} = $resolved->{convention};
    if ($plan->{kind} eq 'handle') {
        if (@args == 1 && defined $args[0] && !ref $args[0]) {
            $plan->{file} = $args[0];
            push @explicit, $args[0];
        } elsif (@args == 1 && ref $args[0] eq 'HASH') {
            my $opt = $args[0];
            $plan->{file} = $opt->{path};
            push @explicit, $opt->{path} if defined $opt->{path};
            $plan->{file} = $root->_file_for($name) if !defined $plan->{file} && defined $root->{dir};
            $plan->{build} = exists $opt->{build_int} ? 'build_int' : exists $opt->{build_str} ? 'build_str' : undef;
            $plan->{keys} = $opt->{ $plan->{build} } if $plan->{build};
            Carp::croak('Data::Shared: perfecthash build keys must be an ARRAY reference')
                if $plan->{build} && ref $plan->{keys} ne 'ARRAY';
        } else {
            Carp::croak('Data::Shared: a perfecthash spec takes a built file path or a'
                . ' {build_int|build_str, path} hashref; pass a factory or a loaded'
                . ' handle as the spec itself instead');
        }
        Carp::croak('Data::Shared: perfecthash mount requires a path') unless defined $plan->{file};
    } elsif ($plan->{kind} eq 'options') {
        Carp::croak("Data::Shared: sortedset:strings takes options, not a path"
            . " placeholder: pass max => N (and optionally set/keys)")
            if @args && (!defined $args[0] || (!ref $args[0] && $args[0] eq ':file'));
        Carp::croak('Data::Shared: sortedset:strings options must be a hashref or key/value pairs')
            if !(@args == 1 && ref $args[0] eq 'HASH') && @args % 2;
        my %opt = @args == 1 && ref $args[0] eq 'HASH' ? %{ $args[0] } : @args;
        Carp::croak("Data::Shared: sortedset:strings mount requires 'max'") unless defined $opt{max};
        push @explicit, grep { defined $_ } @opt{qw(set keys)};
        if (defined $root->{dir}) {
            $opt{set} = $root->_file_for($name) unless defined $opt{set};
            $opt{keys} = $root->_file_for($name . '__keys') unless defined $opt{keys};
        }
        $plan->{options} = \%opt;
        $plan->{file} = $opt{set};
        $plan->{paths} = [grep { defined $_ } @opt{qw(set keys)}];
    } else {
        if (defined $root->{dir} && (!@args || !defined $args[0] || (!ref $args[0] && $args[0] eq ':file'))) {
            shift @args if @args;
            unshift @args, $root->_file_for($name);
        }
        elsif (@args && defined $args[0] && !ref $args[0]) {
            push @explicit, $args[0];
        }
        # Slot 0 is the backing file; a reference there is refused below.
        $plan->{file} = $args[0] if @args && defined $args[0];
    }
    # construct uses load() or new() for these kinds and would ignore a named ctor.
    Carp::croak("Data::Shared: a $class spec does not take a ctor;"
        . ' it is constructed by ' . ($plan->{kind} eq 'handle' ? 'load' : 'new'))
        if $resolved->{ctor_named} && $plan->{kind} ne 'leading';
    $plan->{paths} = [$plan->{file}] if $plan->{kind} ne 'options' && defined $plan->{file};
    # SortedSet::Strings may mix one explicit backing path with one derived path.
    my %explicit = map { $_ => 1 } grep { !ref $_ } @explicit;
    for my $path (@{ $plan->{paths} }) {
        Carp::croak("Data::Shared: invalid backing path for '$name'")
            if ref $path || !length($path) || index($path, "\0") >= 0;
        # Explicit paths must be absolute; derived paths follow the root's directory spelling.
        Carp::croak("Data::Shared: backing path for '$name' must be absolute,"
            . " since every process that opens this store resolves it again"
            . " (got '$path')")
            if $explicit{$path} && $path !~ m{\A/};
    }
    return $plan;
}

sub require_files {
    my ($plan) = @_;
    Carp::croak("Data::Shared: mount '$plan->{name}' has no backing file to reopen") unless @{ $plan->{paths} };
    for my $path (@{ $plan->{paths} }) {
        Carp::croak("Data::Shared: missing backing file '$path' for '$plan->{name}'; refusing to recreate storage")
            unless -f $path;
    }
    return;
}

sub _load {
    my ($resolved) = @_;
    my $load = $resolved->{load} || $resolved->{class};
    my $minimum = $resolved->{entry} && $resolved->{entry}{min_version};
    my $key = $load . "\0" . ($minimum // '');
    return if $LOADED{$key};
    # Variant module names do not determine the distribution that provides them.
    Data::Shared::_require_class($load, $resolved->{entry} && $resolved->{entry}{dist});
    if ($minimum) {
        eval { $load->VERSION($minimum) };
        Carp::croak("Data::Shared: backend $load requires version $minimum or newer: $@") if $@;
    }
    $LOADED{$key} = 1;
}

sub readonly_capable {
    my ($resolved) = @_;
    _load($resolved);
    return 1 if $resolved->{entry} && $resolved->{entry}{immutable};
    return $resolved->{class}->can('new_readonly') ? 1 : 0;
}

sub check_readonly {
    my ($resolved, $name) = @_;
    return if readonly_capable($resolved);
    Carp::croak("Data::Shared: strict read-only access is not supported by $resolved->{class}"
        . (defined $name && length $name ? " at mount '$name'" : ''));
}

sub construct {
    my ($root, $plan) = @_;
    my $resolved = $plan->{resolved};
    my $class = $resolved->{class};
    my $ctor = $resolved->{ctor} || 'new';
    my $opening = $root->{_opening} || $root->{readonly};
    require_files($plan) if $opening;
    check_readonly($resolved, $plan->{name}) if $root->{strict_readonly};
    _load($resolved);
    my $handle;
    if ($plan->{kind} eq 'handle') {
        if (!-e $plan->{file}) {
            Carp::croak("Data::Shared: perfecthash file '$plan->{file}' does not exist;"
                . " build it first or mount a loaded handle")
                unless $plan->{build} && !$opening;
            my $build = $plan->{build};
            my ($keys) = Data::Shared::Manifest::snapshot($plan->{keys});
            $class->$build($plan->{file}, $keys);
        }
        $handle = $class->load($plan->{file});
    } elsif ($plan->{kind} eq 'options') {
        my ($options) = Data::Shared::Manifest::snapshot($plan->{options});
        $handle = $class->new(%$options);
    } elsif ($root->{readonly} && $class->can('new_readonly')) {
        $handle = $class->new_readonly($plan->{file});
    } else {
        my ($args) = Data::Shared::Manifest::snapshot($plan->{args});
        # Frozen files refuse writable constructors, including during a subtree walk.
        if (($root->{_cleanup} || $root->{_frozen_ok}) && $class->can('new_readonly')) {
            $handle = eval { $class->$ctor(@$args) };
            my $error = $@;
            if (!$handle) {
                $handle = eval { $class->new_readonly($plan->{file}) };
                die $error unless $handle;
            }
        } elsif (!defined $root->{dir} && @$args && !defined $args->[0]
                 && $class->can('new_anon')) {
            # Buffer's new(undef, ...) fails with EFAULT; new_anon only after the ordinary ctor fails.
            $handle = eval { $class->$ctor(@$args) };
            if (!$handle) {
                my $error = $@;
                $handle = eval { $class->new_anon(@{$args}[1 .. $#$args]) };
                die $error unless $handle;
            }
        } else {
            $handle = $class->$ctor(@$args);
        }
    }
    Carp::croak("Data::Shared: constructor for '$plan->{name}' did not return a handle")
        unless Scalar::Util::blessed($handle);
    return ($handle, $plan->{file}, $plan->{paths});
}

1;

__END__

=head1 NAME

Data::Shared::Storage - Internal storage planning and construction

=head1 DESCRIPTION

Internal to L<Data::Shared>; not a public API. Resolves constructor
paths without opening backends, validates existing files on reopen, and
selects native constructors.
PerfectHash files are built only when first created. Strict read-only opens
require a native read-only constructor or an immutable backend.

=cut
