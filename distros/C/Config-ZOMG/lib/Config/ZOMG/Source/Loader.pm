package Config::ZOMG::Source::Loader;
{
  $Config::ZOMG::Source::Loader::VERSION = '1.000000';
}

use Moo;
use Sub::Quote 'quote_sub';

use Config::Any;
use List::Util 'first';

has name => (
   is => 'rw',
);

has path => (
   is => 'ro',
   default => quote_sub q{ '.' },
);

has driver => (
   is => 'ro',
   default => quote_sub q[ {} ],
);

has local_suffix => (
   is => 'ro',
   default => quote_sub q{ 'local' },
);

has no_env => (
   is => 'ro',
   default => quote_sub q{ 0 },
);

has no_local => (
   is => 'ro',
   default => quote_sub q{ 0 },
);

has env_lookup => (
   is => 'ro',
   default => quote_sub q{ [] },
);

has path_is_file => (
   is => 'ro',
   default => quote_sub q{ 0 },
);

has _found => (
   is => 'rw',
);

sub _env (@) {
    my $key = uc join "_", @_;
    $key =~ s/::/_/g;
    $key =~ s/\W/_/g;
    return $ENV{$key};
}

sub BUILD {
    my $self = shift;
    my $given = shift;

    if (defined( my $name = $self->name )) {
        if (ref $name eq "SCALAR") {
            $name = $$name;
        }
        else {
            $name =~ s/::/_/g;
            $name = lc $name;
        }
        $self->name($name);
    }

    $self->{env_lookup} = [ $self->env_lookup ]
      if defined $self->env_lookup && ref $self->env_lookup ne 'ARRAY';
}

sub read {
    my $self = shift;

    my @files = $self->_find_files;
    my $cfg_files = $self->_load_files(\@files);
    my %cfg_files = map { (%$_)[0] => $_ } reverse @$cfg_files;
    $self->_found( [ map { (%$_)[0] } @$cfg_files ] );

    my (@cfg, @local_cfg);
    {
        # Anything that is local takes precedence
        my $local_suffix = $self->_get_local_suffix;
        for (sort keys %cfg_files) {

            my $cfg = $cfg_files{$_};

            if (m{$local_suffix\.}ms) {
                push @local_cfg, $cfg;
            }
            else {
                push @cfg, $cfg;
            }
        }
    }

    return $self->no_local ? @cfg : (@cfg, @local_cfg);
}

sub found {
    my $self = shift;
    return ( $self->_found ? @{ $self->_found } : () );
}

sub find {
    my $self = shift;
    return grep { -f $_ } $self->_find_files;
}

sub _load_files {
    my $self = shift;
    my $files = shift;
    return Config::Any->load_files({
        files => $files,
        use_ext => 1,
        driver_args => $self->driver,
    });
}

sub _find_files { # Doesn't really find files...hurm...
    my $self = shift;

    if ($self->path_is_file) {
        my $path = $self->_env_lookup('CONFIG') unless $self->no_env;
        $path ||= $self->path;
        return ($path);
    }
    else {
        my ($path, $extension) = $self->_get_path;
        my $local_suffix = $self->_get_local_suffix;
        my @extensions = $self->_get_extensions;
        my $no_local = $self->no_local;

        my @files;
        if ($extension) {
            die "Can't handle file extension $extension" unless first { $_ eq $extension } @extensions;
            push @files, $path;
            unless ($no_local) {
                (my $local_path = $path) =~ s{\.$extension$}{_$local_suffix.$extension};
                push @files, $local_path;
            }
        }
        else {
            push @files, map { "$path.$_" } @extensions;
            push @files, map { "${path}_${local_suffix}.$_" } @extensions unless $no_local;
        }

        return @files;
    }
}

sub _env_lookup {
    my $self = shift;
    my @suffix = @_;

    my $name = $self->name;
    my $env_lookup = $self->env_lookup;
    my @lookup;
    push @lookup, $name if $name;
    push @lookup, @$env_lookup;

    for my $prefix (@lookup) {
        my $value = _env($prefix, @suffix);
        return $value if defined $value;
    }

    return;
}

sub _get_local_suffix {
    my $self = shift;

    my $name = $self->name;
    my $suffix;
    $suffix = $self->_env_lookup('CONFIG_LOCAL_SUFFIX') unless $self->no_env;
    $suffix ||= $self->local_suffix;

    return $suffix;
}

sub _get_extensions { @{ Config::Any->extensions } }

sub file_extension ($) {
    my $path = shift;
    return if -d $path;
    my ($extension) = $path =~ m{\.([^/\.]{1,4})$};
    return $extension;
}

sub _get_path {
    my $self = shift;

    my $name = $self->name;
    my $path;
    $path = $self->_env_lookup('CONFIG') unless $self->no_env;
    $path ||= $self->path;

    my $extension = file_extension $path;

    if (-d $path) {
        $path =~ s{[\/\\]$}{}; # Remove any trailing slash, e.g. apple/ or apple\ => apple
        $path .= "/$name"; # Look for a file in path with $self->name, e.g. apple => apple/name
    }

    return ($path, $extension);
}


1;

__END__

=pod

=head1 NAME

Config::ZOMG::Source::Loader

=head1 VERSION

version 1.000000

=head1 AUTHORS

=over 4

=item *

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=item *

Robert Krimen <robertkrimen@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
