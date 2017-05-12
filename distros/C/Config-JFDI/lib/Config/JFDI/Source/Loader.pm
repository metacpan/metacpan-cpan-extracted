package Config::JFDI::Source::Loader;

use Any::Moose;

use Config::Any;
use Carp;
use List::MoreUtils qw/ any /;

has name => qw/ is ro required 0 isa Str|ScalarRef /;

has path => qw/ is ro default . /;

has driver => qw/ is ro lazy_build 1 /;
sub _build_driver {
    return {};
}

has local_suffix => qw/ is ro required 1 lazy 1 default local /;

has no_env => qw/ is ro required 1 /, default => 0;

has no_local => qw/ is ro required 1 /, default => 0;

has env_lookup => qw/ is ro /, default => sub { [] };

has path_is_file => qw/ is ro default 0 /;

has _found => qw/ is rw isa ArrayRef /;

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
        $self->{name} = $name;
    }

    if (defined $self->env_lookup) {
        $self->{env_lookup} = [ $self->env_lookup ] unless ref $self->env_lookup eq "ARRAY";
    }

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
    die if @_;
    return @{ $self->_found };
}

around found => sub {
    my $inner = shift;
    my $self = shift;
    
    $self->read unless $self->{_found};

    return $inner->( $self, @_ );
};

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
        my $path;
        $path = $self->_env_lookup('CONFIG') unless $self->no_env;
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
            croak "Can't handle file extension $extension" unless any { $_ eq $extension } @extensions;
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
#    $suffix = _env($self->name, 'CONFIG_LOCAL_SUFFIX') if $name && ! $self->no_env;
    $suffix ||= $self->local_suffix;

    return $suffix;
}

sub _get_extensions {
    return @{ Config::Any->extensions }
}

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
#    $path = _env($name, 'CONFIG') if $name && ! $self->no_env;
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
