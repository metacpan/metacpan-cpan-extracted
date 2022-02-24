package App::perlvars;

use Moo;
use autodie;

our $VERSION = '0.000004';

use Path::Tiny qw( path );
use PPI::Document ();
use Test::Vars import => [qw( test_vars )];

has ignore_file => (
    is        => 'ro',
    predicate => '_has_ignore_file',
);

has _ignore_for_package => (
    is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_ignore_for_package',
);

sub BUILD {
    my $self = shift;

    # We need to read the file before we start checking anything so we can die
    # if it contains bad lines and not have it look like a failure in a
    # particular file we're tidying.
    $self->_ignore_for_package;

    return;
}

sub validate_file {
    my $self = shift;
    my $file = path(shift);
    unless ( $file->exists ) {
        return ( 1, "$file could not be found" );
    }
    if ( $file->is_dir ) {
        return ( 1, "$file is a dir" );
    }

    my $doc = PPI::Document->new("$file");
    return ( 1, "$file could not be parsed as Perl" ) unless $doc;

    my $package_stmt = $doc->find_first('PPI::Statement::Package')
        or return ( 0, "$file contains no package" );

    my ( $exit_code, @msgs ) = test_vars(
        "$file",
        \&_result_handler,
        %{ $self->_ignore_for_package->{ $package_stmt->namespace } || {} },
    );

    return $exit_code, undef, @msgs;
}

sub _build_ignore_for_package {
    my $self = shift;

    return {} unless $self->_has_ignore_file;

    my %vars;
    my %regexes;

    my $file  = path( $self->ignore_file );
    my @lines = $file->lines( { chomp => 1 } );
    for my $line (@lines) {
        next unless $line =~ /\S/;

        my ( $package, $ignore ) = split( /\s*=\s*/, $line );
        unless ( defined $package && defined $ignore ) {
            die 'Invalid line in ' . $self->ignore_file . ": $line\n";
        }

        if ( $ignore =~ m{^qr} ) {
            local $@ = undef;
            ## no critic (BuiltinFunctions::ProhibitStringyEval)
            $ignore = eval $ignore;
            ## use critic
            die $@ if $@;

            push @{ $regexes{$package} }, $ignore;
        }
        else {
            push @{ $vars{$package} }, $ignore;
        }
    }

    my %ignore;
    for my $package ( keys %regexes ) {
        my @re = @{ $regexes{$package} };
        $ignore{$package}{ignore_if} = sub {
            my $check = shift;
            for my $re (@re) {
                return 1 if $check =~ /$re/;
            }
            return 0;
        };
    }

    for my $package ( keys %vars ) {
        $ignore{$package}{ignore_vars}{$_} = 1 for @{ $vars{$package} };
    }

    return \%ignore;
}

sub _result_handler {
    shift;
    my $exit_code = shift;
    my $results   = shift;

    my @errors = map { $_->[1] } grep { $_->[0] eq 'diag' } @{$results};
    return $exit_code, @errors;
}

1;

=pod

=encoding UTF-8

=head1 NAME

App::perlvars - CLI tool to detect unused variables in Perl modules

=head1 VERSION

version 0.000004

=head1 DESCRIPTION

You probably don't want to use this class directly. See L<perlvars> for
documentation on how to use the command line interface.

=head2 ignore_file

The path to a file containing a list of variables to ignore on a per-package
basis. The pattern is C<Module::Name = $variable> or C<Module::Name = qr/some
regex/>. For example:

    Local::Unused = $unused
    Local::Unused = $one
    Local::Unused = $two
    Local::Unused = qr/^\$.*hree$/

=head2 validate_file

Path to a file which will be validated. Returns an exit code, an error message
and a list of unused variables.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: CLI tool to detect unused variables in Perl modules


