package Bread::Board::LazyLoader;
$Bread::Board::LazyLoader::VERSION = '0.14';
use common::sense;

# ABSTRACT: loads lazily Bread::Board containers from files


use Exporter 'import';

use Path::Class;
use Type::Params;
use Types::Standard qw(is_CodeRef slurpy Dict ArrayRef Str Optional CodeRef Object is_Object is_ArrayRef);
use Carp qw(confess);
use Moose::Meta::Role ();
use Moose::Util;
use List::MoreUtils qw(uniq);
use Bread::Board::Container;

our @EXPORT_OK = qw(load_container);

# legacy code
sub new {
    require Bread::Board::LazyLoader::Obj;
    shift();
    Bread::Board::LazyLoader::Obj->new(@_);
}

my $load_container_params = Type::Params::compile(
    slurpy Dict [
        root_dir => Str | ArrayRef [Str],
        filename_extension => Str,
        container_name     => Optional [Str],
        container_factory  => Optional [CodeRef],
    ]
);

sub load_container {
    my ($params) = $load_container_params->(@_);

    my @root_dirs = map { is_ArrayRef($_) ? @$_ : $_ } $params->{root_dir};
    my $filename_extension = $params->{filename_extension};
    my $container_name     = $params->{container_name} // 'Root';
    my $container_factory  = $params->{container_factory} // sub {
        my ($name) = @_;
        return Bread::Board::Container->new( name => $name );
    };

    my $file_suffix = '.' . $filename_extension;
    my $node
        = _make_node( \@root_dirs, $file_suffix, $container_name,
        $container_factory );
    return _load_node($node);
}

# role lazily load the sub_containers
sub _load_sub_container_role {
    my ($children) = @_;

    my $role = Moose::Meta::Role->create_anon_role();
    $role->add_around_method_modifier(
        has_sub_container => sub {
            my ( $orig, $this, $name ) = @_;

            return $this->$orig($name) || exists $children->{$name};
        }
    );
    $role->add_around_method_modifier(
        get_sub_container => sub {
            my ( $orig, $this, $name ) = @_;

            my $sub_container = $this->$orig($name);
            if ( !$sub_container && $children->{$name} ) {
                $sub_container = _load_node( $children->{$name} );
                $this->add_sub_container($sub_container);
            }
            return $sub_container;
        }
    );
    $role->add_around_method_modifier(
        get_sub_container_list => sub {
            my $orig = shift;
            return uniq( $orig->(@_), keys %$children );
        }
    );
    return $role;
}

# loads file in a sandbox package
my $Sandbox_num = 0;

sub _load_file_content {
    my ( $file ) = @_;

    my $package = $file;
    $package =~ s/([^A-Za-z0-9_])/sprintf("_%2x", unpack("C", $1))/eg;

    my $sandbox_num = ++ $Sandbox_num;

    my $code = eval sprintf <<'END_EVAL', 'Bread::Board::LazyLoader', $sandbox_num, $package;
package %s::Sandbox::%d::%s;
{
    my $code = do $file;
    if ( !$code && ( my $error = $@ || $! )) { die $error; }
    $code;
}
END_EVAL

    confess "Evaluation of '$file' failed with: $@" if $@;
    ref($code) eq 'CODE'
        or confess "Evaluation of file '$file' did not return a coderef";
    return $code;
}

sub _load_file {
    my ( $name, $file, $next ) = @_;

    my $builder = _load_file_content($file);
    is_CodeRef($builder)
        or confess sprintf
        "File '%s' returned wrong value, expected CodeRef, got '%s'",
        $file, $builder;

    my $container = $builder->( $name, $next );
    is_Object($container) && $container->isa('Bread::Board::Container')
        or confess sprintf
        "Container builder (coderef) from file '%s returned wrong value, expected Bread::Board::Container instance, got '%s'",
        $file, $container;
    $container->name eq $name
        or confess sprintf
        "Container builder (coderef) from file '%s returned container with wrong name, expected '%s', got '%s'",
        $file, $name, $container->name;

    return $container;
}

sub _load_files {
    my ( $name, $files, $container_factory ) = @_;

    return @$files
        ? do {
        my ( $file, @rest ) = @$files;
        _load_file(
            $name, $file,
            sub {
                _load_files( $name, \@rest, $container_factory );
            }
        );
        }
        : $container_factory->($name);
}

sub _load_node {
    my ($node) = @_;

    my ( $name, $files, $children, $container_factory ) = @$node;

    my $container = _load_files( $name, $files, $container_factory );
    Moose::Util::ensure_all_roles( $container,
        _load_sub_container_role($children) );
    return $container;
}

sub _make_node {
    my ( $dirs, $suffix, $root_name, $container_factory ) = @_;

    my $new = sub { [ shift(), [], {}, $container_factory ] };
    my $add_to_parent = sub {
        my ( $parent, $name ) = @_;
        $parent->[2]{$name} //= $new->($name);
    };
    my $root = $new->($root_name);

    for my $dir (@$dirs) {

        # the only reason to pass coderef as third arg is that
        # I do not want to create containers for empty dirs
        dir($dir)->traverse(
            sub {
                my ( $f, $next, $level, $add ) = @_;

                if ( -d $f ) {
                    $next->(
                        $level + 1,
                        sub {
                            $add_to_parent->(
                                $add ? $add->( $f->basename ) : $root, shift()
                            );
                        }
                    );
                }
                elsif ( -f $f ) {
                    my ($name) = $f->basename =~ /(.*)$suffix$/ or return;

                    my $node
                        = $level == 1 && $name eq $root_name
                        ? $root
                        : $add->($name);

                    push @{ $node->[1] }, "$f";
                }
            },
            0,
        );
    }

    return $root;
}

1;

# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78: 

__END__

=pod

=encoding UTF-8

=head1 NAME

Bread::Board::LazyLoader - loads lazily Bread::Board containers from files

=head1 VERSION

version 0.14

=head1 SYNOPSIS

    use Bread::Board::LazyLoader qw(load_container);

    # having files defining Bread Board containers

    # ./ioc/Root.ioc
    # ./ioc/Database.ioc
    # ./ioc/Webapp/Rating.ioc

    # we can load them with

    my $root
        = load_container( root_dir => './ioc', filename_extension => '.ioc', );

    # then $root container is defined by file Root.ioc
    # $root->fetch('Database') is defined by file Database.ioc
    # $root->fetch('Webapp/Rating.ioc') is defined by

    # but all files except of Root.ioc are loaded lazily when the respective
    # container is needed (usually when a service from the container is
    # resolved by a dependency) 

=head1 DESCRIPTION

Bread::Board::LazyLoader loads a Bread::Board container from a directory
(directories) with files defining the container.

The container returned can also loads lazily its sub containers from the same directories.

=head1 FUNCTIONS

All functions are imported on demand.

=head2 load_container(%params)

Loads the container. The parameters are:

=over 4

=item root_dir

The directory (directories) to be traversed for container definition files.
Either string or an arrayref of strings. Mandatory parameter.

=item filename_extension

The extension of files (without dot) which are searched for container definitions.
Mandatory parameter.

=item container_name

The name of created container. Also the basename of the file which contains it.
"Root" by default.

=item container_factory

An anonymous subroutine used to create "intermediate" containers for directories - the ones
having no definition files. By default it is:

    sub {
        my ($name) = @_;
        return Bread::Board::Container->new(name => $name);
    }

=back

C<< load_container >>  searches under supplied root directories for plain files 
with the extension. Found files found are used to build root container or its subcontainers. 
The position of container in the hierarchy of the containers is same as the
relative path of the file (minus extension) under root directory.

The exception is the file C<< Root >>.extension which defines the root container
itself, not its subcontainer called C<< Root >>.

The container is built from its first definition file (the files are ordered
according their appropriate root in root_dir parameter).

Definition file for a container is a perl code file returning (its last expression is) 
an anonymous subroutine - a container builder.

The container builder is called like:

    my $container = $builder->($name, $next);

First argument to builder is a container name (the basename of the file found),
the second an anonymous subroutine creating the container via next definition file (if any) 
or by calling the container factory.

The definition file may look like:

    use strict;
    use Bread::Board;

    sub {
        my $name = shift;
        return container $name => as {
                service psgi => (...);
        }
    };

Wwhen there is more than one root directory, the most specific should be
mentioned first and their would look like:

    use strict;
    use Bread::Board;

    sub {
        my ($name, $next) = @_;

        my $c = $next->();
        return container $c => as {
            # modifying container specified by more generic files
                service psgi => (...);
        }
    };

The builder must return a Bread::Board container (an instance of Bread::Board::Container or its subclass)
with name C<< $name >>.

Every file is evaluated in a "sandbox", i.e. artificially created package, 
thus all imports and sub definitions in the file are private and not shared.

The root container is built immediately, the subcontainers (their files) 
are built lazily, typically when a service from them is needed.

=head1 AUTHOR

Roman Daniel <roman@daniel.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Roman Daniel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
