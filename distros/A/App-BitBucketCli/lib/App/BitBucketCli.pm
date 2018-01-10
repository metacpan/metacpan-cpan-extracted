package App::BitBucketCli;

# Created on: 2017-04-24 08:14:30
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use Carp;
use WWW::Mechanize;
use JSON::XS qw/decode_json encode_json/;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use App::BitBucketCli::Core;

our $VERSION = 0.003;

has core => (
    is      => 'ro',
    handles => [qw/
        opt
    /],
);

around BUILDARGS => sub {
    my ($orig, $class, @params) = @_;
    my %param;

    if ( ref $params[0] eq 'HASH' ) {
        %param = %{ shift @params };
    }
    else {
        %param = @params;
    }

    $param{core} = App::BitBucketCli::Core->new(%param);

    return $class->$orig(%param);
};

sub projects {
    my ($self) = @_;

    my @projects = sort {
            lc $a->name cmp lc $b->name;
        }
        $self->core->projects();

    my %len;
    for my $project (@projects) {
        $len{name} = length $project->name if !$len{name} || $len{name} < length $project->name;
        $len{key} = length $project->key if !$len{key} || $len{key} < length $project->key;
    }
    for my $project (@projects) {
        if ( $self->opt->long ) {
            my $desc = $project->description || '';
            if ( $desc ) {
                $desc =~ s/^\s+//xms;

                $desc = join "\n" . ' ' x ( $len{name} + $len{key} + 2 ),
                    split /\r?\n/, $desc;
            }

            printf "%-$len{name}s %-$len{key}s %s\n", $project->name, $project->key, $desc;
        }
        else {
            print $project->name . "\n";
        }
    }
}

sub repositories {
    my ($self) = @_;

    my @repositories = sort {
            lc $a->name cmp lc $b->name;
        }
        $self->core->repositories($self->opt->{project});

    my %len;
    for my $repository (@repositories) {
        $len{name} = length $repository->name if !$len{name} || $len{name} < length $repository->name;
        $len{state} = length $repository->state if !$len{state} || $len{state} < length $repository->state;
    }
    for my $repository (@repositories) {
        if ( $self->opt->long ) {
            printf "%-$len{name}s %-$len{state}s %s\n", $repository->name, $repository->state, $repository->self;
        }
        else {
            print $repository->name . "\n";
        }
    }
}

sub repository {
    my ($self) = @_;

    my $details  = $self->core->repository($self->opt->{project}, $self->opt->{repository});
    my $branches = @{ $self->core->get_branches($self->opt->{project}, $self->opt->{repository}) || [] };
    my $prs_open     = @{ $self->core->get_pull_requests($self->opt->{project}, $self->opt->{repository}) || [] };
    my $prs_merged   = @{ $self->core->get_pull_requests($self->opt->{project}, $self->opt->{repository}, 'merged') || [] };
    my $prs_declined = @{ $self->core->get_pull_requests($self->opt->{project}, $self->opt->{repository}, 'declined') || [] };

    print $self->opt->{repository}, "\n";
    print "  $details->{description}\n" if $details->{description};
    print "  git clone $details->{cloneUrl}\n";
    print "  Pull Requests: $prs_open / $prs_merged / $prs_declined\n";
    print "  Branches     : $branches\n";
}

sub pull_requests {
    my ($self) = @_;

    my @pull_requests = sort {
            lc $a->id cmp lc $b->id;
        }
        $self->core->pull_requests($self->opt->{project}, $self->opt->{repository});

    for my $pull_request (@pull_requests) {
        print $pull_request->id . ' - ' . $pull_request->title . "\n";
    }
}

sub branches {
    my ($self) = @_;

    my @pull_requests = sort {
            lc $a->id cmp lc $b->id;
        }
        $self->core->branches($self->opt->{project}, $self->opt->{repository});

    for my $pull_request (@pull_requests) {
        print $pull_request->id . ' - ' . $pull_request->title . "\n";
    }
}

1;

__END__

=head1 NAME

App::BitBucketCli - Library for talking to BitBucket Server (or Stash)

=head1 VERSION

This documentation refers to App::BitBucketCli version 0.003

=head1 SYNOPSIS

   use App::BitBucketCli;

   # create a stash object
   my $stash = App::BitBucketCli->new(
       url => 'http://stash.example.com/',
   );

   # Get a list of open pull requests for a repository
   my $prs = $stash->pull_requests($project, $repository);

=head1 DESCRIPTION

This module implement the sub-commands for the L<bb-cli> command line program.

=head1 SUBROUTINES/METHODS

=head2 C<projects ()>

Lists all of the projects the user can view.

=head2 C<repositories ()>

Lists all of the repositories in a project

=head2 C<repository ()>

Shows details of a repository

=head2 C<branches ()>

Lists the branches of a repository

=head2 C<pull_requests ()>

Lists the pull requests of a repository

=head2 C<BUILDARGS ()>

Moo builder

=head1 ATTRIBUTES

=head2 C<core>

Is a L<App::BitBucketCli::Core> object for talking to the server.

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

Copyright (c) 2017 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
