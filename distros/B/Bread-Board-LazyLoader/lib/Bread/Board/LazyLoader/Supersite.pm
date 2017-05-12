package # hide from PAUSE
    Bread::Board::LazyLoader::Supersite;

# DEPRECATED - use Bread::Board::LazyLoader qw(load_container)

use strict;
use warnings;

# ABSTRACT: loads the proper IOC root with your Bread::Board setup


use Class::Load;
use Carp qw(croak);
use Module::Find qw(findsubmod);
use Bread::Board::LazyLoader;

sub _throw {
    croak join '', __PACKAGE__, '->import: ', @_, "\n";
}

sub import {
    my $this = shift;

    # sites is a list of subroutines building the container
    my @sites = _get_sites(@_);

    no strict 'refs';
    *{ caller . '::' . 'root' } = sub {
        my $this = shift;

        # there may be more than one site
        my ( $first, @next ) = reverse @sites;
        my $root = $first->(@_);
        $root = $_->($root) for @next;
        return $root;
    };
}

sub _load_module_site {
    my ( $module) = @_;

    Class::Load::load_class($module);
    return sub {
	$module->root(@_);
    };
}

sub _load_file_site {
    my ($file) = @_;

    my $loader = Bread::Board::LazyLoader->new;
    $loader->add_file($file);
    return sub {
        $loader->build(@_);
    };
}

# the variable may contain more than one site (either module or file) separated by semicolon
sub _load_var_sites {
    my ($content) = @_;

    my @content = split /;/, $content;
    return
        map { m{/} ? _load_file_site($_) : _load_module_site($_); } @content;
}

sub _get_sites {
    return @_ == 1 && ref $_[0] eq 'ARRAY'

        # array ref
        ? map { _get_sites($_) } @{ shift() }

        # hashref
        : ( @_ == 1 && ref $_[0] eq 'HASH' ) ? _get_sites( %{ shift() } )
        :                                      _get_site(@_);
}

sub _get_site {
    my %args = @_;

    my $env_var = $args{env_var};
    if (my $site = $env_var && $ENV{$env_var}){
        return _load_var_sites( $site );
    }

    if (my $file = delete $args{file}){
        return _load_file_site( $file );
    }

    my $site = delete $args{site}
      or _throw "No site argument supplied";

    if (! ref $site ){
        return _load_module_site($site);
    }
    elsif ( ref $site eq 'HASH' ){
        # we select the only site which fulfills the condition
        my $prefix = $site->{prefix};
        my $filter = $site->{filter};

        $prefix && $filter or _throw "Invalid site argument $site";

        return _load_only_module($prefix, $filter);
    }
    else {
        _throw "Invalid site argument $site";
    }

}

# there must be just one site module $prefix:: conforming the selection
# for example Manggis::Site::<name> module where name starts with lowercase (cz, sk)
sub _load_only_module {
    my ($prefix, $filter) = @_;

    my $select =
        ref $filter eq 'Regexp' ? sub { $_ =~ $filter }
      : ref $filter eq 'CODE'  ? $filter
      :                       _throw "Inapropriate filter $filter";
    my @sites = grep {  
            my ($name) = /^${prefix}::(.*)/;
            local $_ = $name;
            $select->($name);
    } findsubmod($prefix);

    _throw "No site module $prefix\:\:* conforming your selection found\n" if !@sites;
    _throw "More than one site module $prefix\:\:* found (" . join( ', ', @sites ) . ')'
        if @sites > 1;
    return _load_module_site($sites[0]); # "found as the only proper $prefix\:\:* installed module");
}

1;

# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78:

__END__

=pod

=encoding UTF-8

=head1 NAME

Bread::Board::LazyLoader::Supersite - loads the proper IOC root with your Bread::Board setup

=head1 VERSION

version 0.14

=head1 SYNOPSIS

    package MyApp::IOC;
    use strict;
    use warnings;

    use Bread::Board::LazyLoader::SuperSite 
	env_var => 'MY_APP_SITE',
        site => {
            prefix => 'My::Site',
            filter => qr{^[a-z]}
        };

    # in scripts, psgi apps

    use MyApp::IOC;

    my $root = MyApp::Root->root;
    $root->fetch('Scripts/MyApp-Web')->get()->run();

=head1 DESCRIPTION

This module creates a single proxy subroutine for IOC root, 
which may be loaded from different modules (for example 
national specific).

Better with example:

We have two instances of our application, czech and slovak, with IOC roots
implemented in C<< MyApp::Site::cz->root >> and C<< MyApp::Site::sk->root >>.
In each instance of our app only one this modules is installed.

Most of the scripts (tests, psgi files, ...) referencing the IOC root 
are not nationally specific, so we prefer them to use some common name.

Having defined "dispatcher" ioc module like this:

   package MyApp::IOC;
   use strict;

   use Bread::Board::LazyLoader::SuperSite 
	site => {
		prefix => 'MyApp::Site',
		filter => qr{^[a-z]},
	};

   1;

We can use C<< MyApp::IOC->root >> uniformly to get our IOC root of the application, 
which returns either C<< MyApp::Site::cz->root >> or C<< MyApp::Site::sk->root >> depending
on site.

Import looks through all C<< MyApp::Site::* >> installed modules and tries to find one
with next part starting with lowercase letter (lowercase, so that our base IOC module C<< MyApp::Site::Core >> is not found).
There must be exactly one such module or C<< use Bread::Board::LazyLoader::Supersite >> fails.

=head2 import parameters

   use Bread::Board::LazyLoader::Supersite %params;

=over 4

=item env_var=NAME 

The content of environment variable (if set) is used as site module (the one with root method).
There may be more than one modules separated by semicolon inside env var.

With 

    package MyApp::IOC;
    use strict;
    use warnings;

    use Bread::Board::LazyLoader::SuperSite env_var => 'MY_APP_SITE';

and 

    MY_APP_SITE='MyApp::Site::Sandbox;MyApp::Site::cz'

then

   MyApp::IOC->root

returns

   MyApp::Site::Sandbox->root( MyApp::Site::cz->root )

Environment variable may even contain paths:

    MY_APP_SITE="$HOME/app/sandbox.ioc;MyApp::Site::cz"

With C<< $HOME/app/sandbox.ioc >>

    use Bread::Board;
    sub {
	my $c = shift;

	# $c here is MyApp::Site::cz->root

	container $c => as {
		service dbh => some_mocked_dbh();
	};
    };

If C<env_var> option is used (and the appropriate variable set), it has priority over C<site> option.

=item site   

Used either like C<< site => $module >> or C<< site => { prefix => $module_prefix, filter => $name_filter_re } >>.    

Dispatches the C<< root >> to appropriate module. There may be just one.

=back

=head1 AUTHOR

Roman Daniel <roman@daniel.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Roman Daniel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
