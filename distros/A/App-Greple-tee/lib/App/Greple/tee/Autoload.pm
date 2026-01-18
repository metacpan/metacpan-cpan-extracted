package App::Greple::tee::Autoload;

use v5.24;
use warnings;
use Carp;

use Exporter 'import';
our @EXPORT_OK = qw(resolve);

# Mapping of short function names to full module::function
my %alias = (
    ansicolumn => 'App::ansicolumn::ansicolumn',
    ansifold   => 'App::ansifold::ansifold',
    'cat-v'    => __PACKAGE__ . '::cat_v',
);

sub cat_v {
    require App::cat::v;
    App::cat::v->new->run(@_);
}

sub resolve {
    my $name = shift;
    my $func = $alias{$name} // $name;
    if ($func =~ /^(.+)::([^:]+)$/) {
	my($mod, $sub) = ($1, $2);
	unless (defined &{$func}) {
	    eval "require $mod";
	    croak $@ if $@;
	}
    }
    no strict 'refs';
    defined &{$func} or croak "Undefined function: $func";
    \&{$func};
}

1;

__END__

=encoding utf-8

=head1 NAME

App::Greple::tee::Autoload - Autoload support for tee module

=head1 SYNOPSIS

    use App::Greple::tee::Autoload qw(resolve);

    my $code = resolve('ansicolumn');
    # Loads App::ansicolumn and returns \&App::ansicolumn::ansicolumn

    my $code = resolve('App::ansicolumn::ansicolumn');
    # Loads and returns code reference for fully qualified name

=head1 DESCRIPTION

This module provides function resolution for the L<App::Greple::tee>
module. It maps short function names to their full module paths,
automatically loads the required modules, and returns code references.

=head1 FUNCTIONS

=over 4

=item B<resolve>(I<name>)

Resolve a function name and return a code reference. If the name is
a short alias (like C<ansicolumn>), it is expanded to the full name
(C<App::ansicolumn::ansicolumn>). The module is loaded if necessary.

=back

=head1 ALIASES

=over 4

=item ansicolumn

Resolves to C<App::ansicolumn::ansicolumn>

=item ansifold

Resolves to C<App::ansifold::ansifold>

=item cat-v

Calls C<App::cat::v-E<gt>new-E<gt>run(@_)>

=back

=head1 SEE ALSO

L<App::Greple::tee>

=cut
