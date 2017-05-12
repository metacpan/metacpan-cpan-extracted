package App::VTide::Command::Conf;

# Created on: 2016-02-08 10:42:09
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use version;
use Carp;
use English qw/ -no_match_vars /;
use YAML::Syck qw/ Dump /;
use Array::Utils qw/intersect/;

extends 'App::VTide::Command';

our $VERSION = version->new('0.1.1');
our $NAME    = 'conf';
our $OPTIONS = [
    'env|e',
    'terms|t',
    'which|w=s',
    'test|T!',
    'verbose|v+',
];
sub details_sub { return ( $NAME, $OPTIONS )};

sub _alphanum {
    my $A = $a;
    my $B = $b;
    $A =~ s/(\d+)/sprintf "%05i", $1/egxms;
    $B =~ s/(\d+)/sprintf "%05i", $1/egxms;
    return $A cmp $B;
}

sub run {
    my ($self) = @_;

    if ( $self->defaults->{env} ) {
        for my $env (sort keys %ENV ) {
            next if $env !~ /VTIDE/;
            printf "%-12s : %s\n", $env, $ENV{$env};
        }
        print "\n";
    }

    if ( $self->defaults->{which} ) {
        return $self->which( $self->defaults->{which} );
    }

    my $data  = $self->defaults->{terms}
        ? $self->config->get->{terminals}
        : $self->config->get->{editor}{files};
    my @files = sort _alphanum keys %{ $data };

    print $self->defaults->{terms} ? "Terminals configured:\n" : "File groups:\n";
    if ( $self->defaults->{verbose} ) {
        for my $file (@files) {
            my $data = Dump( $data->{$file} );
            $data =~ s/^---//xms;
            print $file, $data, "\n";
        }
    }
    else {
        print join "\n", @files, '';
    }

    return;
}

sub which {
    my ( $self, $which ) = @_;
    my $term = $self->config->get->{terminals};
    my $file = $self->config->get->{editor}{files};
    my (%files, %groups, %terms);

    for my $group (keys %$file) {
        my @found = grep {/$which/}
            @{ $file->{$group} },
            map { $self->_dglob($_) } @{ $file->{$group} };
        next if !@found;

        for my $found (@found) {
            $files{$found}++;
        }
        $groups{$group}++;
    }

    my @files  = sort keys %files;
    my @groups = sort keys %groups;
    my @terms;
    for my $terminal (sort keys %$term) {
        my $edit = !$term->{$terminal}{edit} ? []
            : ! ref $term->{$terminal}{edit} ? [ $term->{$terminal}{edit} ]
            :                                  $term->{$terminal}{edit};

        my @found = (
            ( intersect @files , @$edit ),
            ( intersect @groups, @$edit ),
        );
        next if !@found;
        push @terms, $terminal;
    }

    if (@files) {
        print "Files:     " . ( join ', ', @files )  . "\n";
        print "Groups:    " . ( join ', ', @groups ) . "\n";
        print "Terminals: " . ( join ', ', @terms )  . "\n" if @terms;
    }
    else {
        print "Not found\n";
    }

    return;
}

sub auto_complete {
    my ($self) = @_;

    my $env = $self->options->files->[-1];
    my @files = sort keys %{ $self->config->get->{editor}{files} };

    print join ' ', grep { $env ne 'conf' ? /^$env/xms : 1 } @files;

    return;
}

1;

__END__

=head1 NAME

App::VTide::Command::Conf - Show the current VTide configuration and environment

=head1 VERSION

This documentation refers to App::VTide::Command::Conf version 0.1.1

=head1 SYNOPSIS

    vtide conf [-e|--env] [-t|--terms] [-v|--verbose]

    OPTIONS
     -e --env       Show the current VTIide environment
     -t --terms     Show the terminal configurations
     -w --which[=]glob-name
                    Show the files found by "glob-name"
     -v --verbose   Show environment as well as config
        --help       Show this help
        --man        Show the full man page

=head1 DESCRIPTION

This module provide command line option to view the current configuration
of a L<vtide> project. This can be helpful when wanting to edit file and
you can't remember which file group has the files you are interested.

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Show's the current files configuration

=head2 C<which ( $what )>

Finds which terminals / file globs C<$what> belongs to.

=head2 C<auto_complete ()>

Auto completes sub-commands that can have help shown

=head2 C<details_sub ()>

Returns the commands details

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
