package # hide from PAUSE
  Bread::Board::LazyLoader::Site;

# DEPRECATED - use Bread::Board::LazyLoader qw(load_container)

use strict;
use warnings;

# ABSTRACT: loads tree of IOC files alongside pm file


# imports methods root into caller's namespace

use Bread::Board::LazyLoader;
use Carp qw(confess croak);
use Class::Load;

# import imports into caller namespace 
# root   - returns the appropriate root

sub import {
    my $this = shift;
    my ( $caller_package, $caller_filename ) = caller;

    my $to_import = $this->_build( $caller_package, $caller_filename, @_ );
    for my $method ( keys %$to_import ) {
        no strict 'refs';
        *{ join '::', $caller_package, $method } = $to_import->{$method};
    }
}

sub _throw {
    croak join '', __PACKAGE__, '->import: ', @_, "\n";
}

sub _build {
    my ( $this, $caller_package, $caller_filename, %args ) = @_;

    # base is a package which loader we use and add to
    my $base = delete $args{base};
    if ($base) {
        Class::Load::load_class($base);
        $base->can('loader')
          or _throw "base package '$base' has no method loader";
    }

    # load all ioc files "belonging" to perl file
    # given $dir/Manggis/Core.pm
    # loads all *.ioc files under $dir/Manggis/Core/
    my $dir = delete $args{dir}
      || do {

        # we add files according to *.pm
        $caller_filename =~ /^(.*)\.pm$/;
        $1;
      };

    -d $dir or _throw "There is no directory $dir to look for ioc files";

    my $suffix = delete $args{suffix} || 'ioc';

    !%args
      or _throw sprintf
      "Unrecognized or ambiguous parameters (%s)", join( ', ', keys %args );

    return {
        loader => sub {
            my $loader = Bread::Board::LazyLoader->new;
            $loader->add_tree( $dir, $suffix );
            return $loader;
        },
        root => sub {
            my $this = shift;
            return $this->loader->build( $base ? $base->root(@_) : @_ );
        },
    };
}

1;

# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78:

__END__

=pod

=encoding UTF-8

=head1 NAME

Bread::Board::LazyLoader::Site - loads tree of IOC files alongside pm file

=head1 VERSION

version 0.14

=head1 SYNOPSIS

In module dir we have files, each one containing the definition of 
one Bread::Board::Container

    lib/My/Site/Supp/Database.ioc
    lib/My/Site/Root.ioc
    lib/My/Site/Config.ioc
    lib/My/Site/Database.ioc
    lib/My/Site/Planner.ioc
    lib/My/Site/AQ.ioc

the "site" module C<lib/My/Site.pm> is defined like

    package My::Site;
    use strict;
    use warnings;

    use Bread::Board::LazyLoader::Site;

    1;

in the script 

    use My::Site;

    my $root = My::Site->root;
    my $db_container = $root->fetch('Database');
    my $dbh = $root->resolve(service => 'Database/dbh');

=head1 DESCRIPTION

Site module is a module with a class method C<root> returning an instance of C<Bread::Board::Container>.

C<Bread::Board::LazyLoader::Site> just imports such C<root> method.

=head2 import parameters

   use Bread::Board::LazyLoader::Site %params;

=over 4

=item dir  

Directory searched for container files. By default it is the directory with the same name
as module file without suffix. 

=item suffix

Suffix of container files. By default C<ioc>.

=item base

Another site module. All container files are loaded on top of the base file containers.

=back

=head1 AUTHOR

Roman Daniel <roman@daniel.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Roman Daniel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
