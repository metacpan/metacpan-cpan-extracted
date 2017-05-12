package # hide from PAUSE
  Bread::Board::LazyLoader::Obj;

# DEPRECATED - use Bread::Board::LazyLoader qw(load_container)

use Moose;

# ABSTRACT: lazy loader for Bread::Board containers


use Moose::Util ();
use Bread::Board;
use List::MoreUtils qw(uniq);
#use Bread::Board::LazyLoader::Container;
use Carp qw(confess);

# default name
has name => ( is => 'ro', required => 1, default => 'Root' );

# remember the subs returned from builder files
has cache_codes => ( is => 'ro', default => 1 );

# builders (files and codes) for current container
has builders => ( is => 'ro', isa => 'ArrayRef', default => sub { [] }, );

has container_class => (
    is      => 'ro',
    default => 'Bread::Board::Container',
);

sub get_builder_paths {
    my $this = shift;
    my $prefix = shift // '';

    return grep { $prefix eq '' || m{^$prefix(?:/|$)} }
        map { $_->[0] } @{ $this->builders };
}

sub _normalize_path {
    my ($path) = @_;

    return
        defined $path
        ? join( '/', grep { length($_) > 0 } split m{/}, $path )
        : '';
}

sub _sub_path {
    my ($parent, $name) = @_;

    return join '/', grep { $_ ne ''} $parent, $name;
}

sub add_builder {
    my ($this, $path, $code) = @_;

    push @{$this->builders}, [ $path, $code ];
}


sub add_file {
    my ( $this, $file, $where ) = @_;

    -f $file or confess "No file '$file' found";

    $this->add_builder(
        _normalize_path($where),
        sub {
            my ($this, $c) = @_;
            $this->apply_file($c, $file);
        }
    );
}

sub add_code {
    my ( $this, $code, $where ) = @_;

    ref($code) eq 'CODE'
        or confess "\$builder->add_code( CODEREF, [ \$under ])\n";
    $this->add_builder(
        _normalize_path($where),
        sub {
            my ($this, $c) = @_;
            $this->apply_code($c, $code);
        }
    );
}

sub add_tree {
    my ( $this, $dir, $extension, $where ) = @_;

    $this->_add_tree( $dir, $extension,
        defined $where && $where =~ m{[^/]} ? $where : '' );
}

sub _add_tree {
    my ( $this, $dir, $extension, $where ) = @_;

    opendir( my $dh, $dir ) or die "can't opendir $dir: $!";
    for my $basename ( grep { /[^\.]/ } readdir($dh) ) {
        my $path = "$dir/$basename";
        if ( -f $path ) {
            if ( my ($name) = $basename =~ /(.*)\Q.$extension\E$/ ) {
                $this->add_file( $path,
                    !$where && $name eq $this->name
                    ? ()
                    : "$where/$name"  );
            }
        }
        elsif ( -d $path ) {
            $this->_add_tree( $path, $extension, "$where/$basename");
        }
    }
    closedir $dh;
}

# ->build($container) ...
# ->build($name) ...
# ->build() ...
sub build {
    my ( $this, $arg ) = @_;
    return $this->_build_container( '', $arg // $this->name );
}

sub _build_container {
    my ($this, $path, $in) = @_;

    # applying builders
    my @builders = map {
        my ( $builder_path, $builder ) = @$_;
        $builder_path eq $path ? $builder : ();
    } @{ $this->builders };

    my $c = $this->_apply_builders($path, $in, @builders);
    my $cc = ref $c? $c: $this->container_class->new(name => $c);
    Moose::Util::apply_all_roles($cc, $this->lazy_sub_container_role($path));
    return $cc;
}

sub _apply_builders {
    my ( $this, $path, $in, @builders ) = @_;

    my ( $builder, @rest ) = @builders or return $in;

    my $c = $this->$builder($in);
    blessed($c) && $c->isa('Bread::Board::Container')
        or confess "Builder for '$path' did not return a container";

    my $name = ref($in) ? $in->name : $in;
    $c->name eq $name
        or confess
        "Builder for '$path' returned container with unexpected name ('"
        . $c->name . "')";
    return $this->_apply_builders( $path, $c, @rest );
}

sub lazy_sub_container_role {
    my ( $this, $path ) = @_;

    my %sub_containers;

    my $meta = Moose::Meta::Role->create_anon_role();
    $meta->add_around_method_modifier(
        has_sub_container => sub {
            my ( $orig, $container, $name ) = @_;

            return $container->$orig($name)
                || $this->get_builder_paths( _sub_path( $path, $name ) )
                || 0;
        },
    );
    $meta->add_around_method_modifier(
        get_sub_container_list => sub {
            my ( $orig, $container ) = @_;

            my $prefix = $path eq ''? $path: "$path/";
            return uniq( $container->$orig, map {
                 m{^$prefix([^/]+)}; } $this->get_builder_paths($path) );
        }
    );

    $meta->add_around_method_modifier(
        get_sub_container => sub {
            my ( $orig, $container, $name ) = @_;

            return $sub_containers{$name} if exists $sub_containers{$name};

            my $sub_container  = $container->$orig($name);
            my $sub_path       = _sub_path( $path, $name );
            my $builder_exists = $this->get_builder_paths($sub_path);

            if ( $builder_exists || $sub_container ) {
                my $built = $this->_build_container( $sub_path,
                    $sub_container // $name );
                $sub_containers{$name} = $built;
                $container->add_sub_container($built);
                return $built;
            }
            else {
                # there is nothing and I will remember it
                $sub_containers{$name} = undef;
                return undef;
            }
        }
    );
    return $meta;
}

# loads file in a sandbox package
sub get_code_from {
    my ( $this, $file ) = @_;

    my $package = $file;
    $package =~ s/([^A-Za-z0-9_])/sprintf("_%2x", unpack("C", $1))/eg;

    my $code = eval sprintf <<'END_EVAL', 'Bread::Board::LazyLoader', $package;
package %s::Sandbox::%s;
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

my %code_from;
around get_code_from => sub {
    my ( $orig, $this, $file ) = @_;

    return $this->cache_codes
        ? $code_from{$file} ||= $this->$orig($file)
        : $this->$orig($file);
};

sub apply_file {
    my ( $this, $c, $file ) = @_;

    return $this->get_code_from($file)->($c);
}

sub apply_code {
    my ( $this, $c, $code ) = @_;

    return $code->($c);
}

__PACKAGE__->meta->make_immutable;
1;

# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78: 

__END__

=pod

=encoding UTF-8

=head1 NAME

Bread::Board::LazyLoader::Obj - lazy loader for Bread::Board containers

=head1 VERSION

version 0.14

=head1 SYNOPSIS

    package MyApp::IOC;
    use strict;
    use warnings;

    use Path::Class qw(dir);
    use Bread::Board::LazyLoader;

    # loads all *.ioc files under .../MyApp/IOC/
    # from each .../MyApp/IOC/<REL_PATH>.ioc file
    # a <REL_PATH> subcontainer is created
    # from .../MyApp/IOC/Root.ioc a root container is created
    #
    # examples
    # file .../MyApp/IOC/Root.ioc defines the root container
    # file .../MyApp/IOC/Database.ioc defines the Database subcontainer 
    # file .../MyApp/IOC/WebServices/Extranet.ioc defines the WebServices/Extranet subcontainer

    sub loader {  
        my $dir = __FILE__;
        $dir =~ s/\.pm$//;

        my $loader = Bread::Board::LazyLoader->new;

        dir($dir)->traverse(sub {
            my ($f, $cont, $rel) = @_;

            return $cont->( [ $rel ? @$rel : (), $f->basename ] ) if -d $f;
            my ($name) = -f $f && $f->basename =~ /(.*)\.bb$/
                or return;

            $loader->add_file( $f,
                $name eq 'Root' && @$rel == 1
                ? ()
                : join( '/', ( splice @$rel, 1, ), $name ) );
        });
        return $loader->build;
    }

    sub root {
        my $this = shift;
        return $this->loader(@_)->build;
    }

=head1 DESCRIPTION

Imagine we have a large L<Bread::Board> root container (with nested subcontainers). 
This container is used among scripts, psgi application files, ...
Each place of usage uses only part of the tree (usually it resolves one service only).

You can have the root container defined in a single file, but such extensive file can be hard to maintain.
Also the complete structure is loaded in every place of usage, 
which can be quite consuming (if some part of your tree is an L<OX> aplication for example). 

Bread::Board::LazyLoader enables you to define your containers (subcontainers) 
in independent files which are loaded lazily when the container is asked for
(C<< $parent->get_subcontainer >>).

Having our IOC root defined like

    my $dir     = '...';
    my $builder = Bread::Board::LazyLoader->new;
    $builder->add_file("$dir/Root.ioc");
    $builder->add_file( "$dir/Database.ioc"    => 'Database' );
    $builder->add_file( "$dir/WebServices.ioc" => 'WebServices' );
    $builder->add_file( "$dir/Integration.ioc" => 'Integration' );
    $builder->build;

we can have Integration/manager service resolved in a script 
while the time consuming WebServices container (OX application)
is not loaded.

=head2 Definition file

Definition file for a container is a perl file returning 
(the last expression of file is) an anonymous subroutine.

The subroutine is called with the name of the container 
and returns the container (L<Bread::Board::Container> instance)
with the same name.

The file may look like:

    use strict;
    use Bread::Board;

    sub {
        my $name = shift;
        container $name => as {
            ...
        }
    };

Of course we can create the instance of our own container

    use strict;
    use Bread::Board;
    
    use MyApp::Extranet; # our big OX based application

    sub {
        my $name = shift;
        MyApp::Extranet->new(
            name => $name
        );
    };

A single container can be built from more definition files,
the subroutine from second file is then called with the container created
by the first subroutine call: C<< my $container = $sub3->($sub2->($sub1->($name))); >>

The construction C<< container $name => as { ... }; >> from L<Bread::Board>
can be used even when C<< $name >> is a container, not a name.

The definition files (the subroutines) are applied 
even if the container was already created inside parent container.

=head1 METHODS

=over 4

=item C<new(%args)>

Constructor with optional arguments

=over 4

=item name

The name of container built, default is C<Root>.

=item cache_codes

Whether the subroutines returned from builder files are remembered.
Default is 1.

=back

=item C<add_file(FILE, [ UNDER ])>

Adds a file building the current or nested container. 
Optional second parameter is is a path to nested container.  

=item C<add_code(CODEREF, [ UNDER ])>

Similar to add_file, but the anonymous subroutine is passed directly
not loaded from a file.

=item C<add_tree(DIR, EXTENSION, [ UNDER ])>

Adds all files under directory with given extension (without leading .) to
builder.

Having files C<./IOC/Root.ioc>, C<./IOC/Database.ioc>, C<./IOC/WebServices/REST.ioc>
then C<< $loader->add('./IOC', 'ioc') >> adds first file into current container 
(if its name is Root), the other files cause subcontainers to be created.

=item C<build>

Builds the container. Each call of <build> returns a new container.

=item C<build($container)>

Modify existing container (it the builders allow it).

=back

=head1 AUTHOR

Roman Daniel <roman@daniel.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Roman Daniel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
