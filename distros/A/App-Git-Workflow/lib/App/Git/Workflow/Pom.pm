package App::Git::Workflow::Pom;

# Created on: 2014-08-06 19:04:05
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp qw/carp croak cluck confess longmess/;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use XML::Tiny;
use App::Git::Workflow::Repository qw//;
use App::Git::Workflow;
use base qw/App::Git::Workflow/;

our $VERSION = version->new(1.1.4);

sub new {
    my $class = shift;
    my $self  = App::Git::Workflow->new(@_);
    bless $self, $class;

    return $self;
}

sub _alphanum_sort {
    my $A = $a;
    $A =~ s/(\d+)/sprintf "%014i", $1/egxms;
    my $B = $b;
    $B =~ s/(\d+)/sprintf "%014i", $1/egxms;

    return $A cmp $B;
}

sub _max_age {
    my ($self) = @_;
    return $self->{MAX_AGE} ||= 60 * 60 * 24 * (
        $ENV{GIT_WORKFLOW_MAX_AGE}
        || $self->git->config('workflow.max-age')
        || 120
    );
}

sub get_pom_versions {
    my ($self, $pom, $match, $skip) = @_;
    my @branches = $self->branches('both');
    my $settings = $self->settings();
    my %versions;
    my $count = 0;
    my $max_age = $self->_max_age;
    my $run = !$settings->{max_age} || $settings->{max_age} == $max_age ? 0 : 1;

    while (!%versions && $run < 10) {
        BRANCH:
        for my $branch (sort @branches) {
            $settings->{pom_versions}{$branch} ||= {};
            my $saved = $settings->{pom_versions}{$branch};

            # skip branches marked as OLD
            next BRANCH if !$run && $saved->{old};
            next BRANCH if $match && $branch !~ /$match/;
            next BRANCH if $skip && $skip =~ /$skip/;

            my $current = eval { $self->commit_details($branch) } or next;

            # Skip any branches that are over $MAX_AGE old
            if ( $current->{time} < time - $max_age ) {
                $saved->{old} = 1;
                $self->save_settings() if $count++ % 20 == 0;
                next BRANCH;
            }

            delete $saved->{old};

            # used saved version if it exists.
            if ( $saved && $saved->{time} && $saved->{time} == $current->{time} ) {
                $versions{$saved->{numerical}}{$branch} = $saved->{version};
                next BRANCH;
            }

            my $xml = eval { $self->git->show("$branch:$pom"); };

            next BRANCH if !$xml;
            chomp $xml;
            next BRANCH if !$xml;

            $branch =~ s{^origin/}{}xms;

            my $numerical = my $version = eval { $self->pom_version($xml, $pom) };

            # make sure we get a valid version
            if ( $@ || !defined $numerical ) {
                next BRANCH;
            }

            # remove snapshots from the end
            $numerical =~ s/-SNAPSHOT$//xms;
            # remove any extranious text from the front
            $numerical =~ s/^\D+//xms;

            $versions{$numerical}{$branch} = $version;
            $settings->{pom_versions}{$branch} = {
                numerical => $numerical,
                version   => $version,
                time      => $current->{time},
            };
            $self->save_settings() if $count++ % 50 == 0;
        }
        $run++;
    }

    $self->save_settings();

    return \%versions;
}

sub pom_version {
    my ($self, $xml, $pom) = @_;

    if ( $pom && $pom =~ /[.]json$/ ) {
        require JSON;
        my $json = eval { JSON::decode_json($xml) }
            or do { warn "Could not read $xml as json : $@\n"; };
        return $json->{version};
    }
    if ( $pom && $pom =~ /[.]ya?ml$/ ) {
        require YAML;
        my $json = YAML::Load($xml);
        return $json->{version};
    }

    my $doc = XML::Tiny::parsefile( $xml !~ /\n/ && -f $xml ? $xml : '_TINY_XML_STRING_' . $xml);

    for my $elem (@{ $doc->[0]{content} }) {
        next if $elem->{name} ne 'version';

        return $elem->{content}[0]{content};
    }

    return;
}

sub next_pom_version {
    my ($self, $pom, $versions) = @_;
    $versions ||= $self->get_pom_versions($pom);

    # sanity check
    die "No POM versions found!" if !%$versions;

    my ($max) = reverse sort _alphanum_sort keys %{$versions};
    my ($primary, $secondary) = split /[.]/, $max;
    $secondary++;

    return "$primary.$secondary.0-SNAPSHOT";
}

1;

__END__

=head1 NAME

App::Git::Workflow::Pom - Tools for maven POM files with git

=head1 VERSION

This documentation refers to App::Git::Workflow::Pom version 1.1.4

=head1 SYNOPSIS

   use App::Git::Workflow::Pom qw/get_pom_versions pom_version next_pom_version/;

   # get all branch POM versions
   my $versions = $pom->get_pom_versions("pom.xml");
   # {
   #    1.0 => { "some_branch" => "1.0.0-SNAPSHOT" },
   #    ...
   # }

   # extract the version from the POM
   my $version = $pom->pom_version("pom.xml");

   # find the next unused POM version.
   my $next = $pom->next_pom_version("pom.xml");

=head1 DESCRIPTION

This library provides tools for looking at POM files in different branches.

=head1 SUBROUTINES/METHODS

=over 4

=item C<new (%params)>

Create a new C<App::Git::Workflow::Pom> object

=item C<get_pom_versions ($pom_file)>

Find all POM versions used in all branches.

=item C<pom_version ($xml_text_or_file)>

Extract the version number from C$xml_text_or_file>

=item C<next_pom_version ($pom, $versions)>

Find the next available POM version number.

=back

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

Copyright (c) 2014 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
