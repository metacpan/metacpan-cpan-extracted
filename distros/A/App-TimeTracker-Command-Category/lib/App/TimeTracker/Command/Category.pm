package App::TimeTracker::Command::Category;

# ABSTRACT: use categories when tracking time with App::TimeTracker
our $VERSION = '1.003'; # VERSION

use strict;
use warnings;
use 5.010;

use Moose::Util::TypeConstraints;
use Moose::Role;

sub munge_start_attribs {
    my ( $class, $meta, $config ) = @_;
    my $cfg = $config->{category};
    return unless $cfg && $cfg->{categories};

    subtype 'ATT::Category' => as enum( $cfg->{categories} ) => message {
        "$_ is not a valid category (as defined in the current config)"
    };

    $meta->add_attribute(
        'category' => {
            isa           => 'ATT::Category',
            is            => 'ro',
            required      => $cfg->{required},
            documentation => 'Category',
        }
    );
}
after '_load_attribs_start'    => \&munge_start_attribs;
after '_load_attribs_append'   => \&munge_start_attribs;
after '_load_attribs_continue' => \&munge_start_attribs;

before [ 'cmd_start', 'cmd_continue', 'cmd_append' ] => sub {
    my $self = shift;

    return unless my $category = $self->category;

    if (my $prefix = $self->config->{category}{prefix}) {
        $category = $prefix.$category;
    }
    $self->add_tag( $category );
};

sub cmd_statistic {
    my $self = shift;

    my @files = $self->find_task_files(
        {   from     => $self->from,
            to       => $self->to,
            projects => $self->fprojects,
            tags     => $self->ftags,
            parent   => $self->fparent,
        }
    );
    my $cats = $self->config->{category}{categories};
    my $prefix = $self->config->{category}{prefix} || '';

    my $total = 0;
    my %stats;

    foreach my $file (@files) {
        my $task = App::TimeTracker::Data::Task->load( $file->stringify );
        my $time = $task->seconds // $task->_build_seconds;
        $total += $time;
        my %tags = map { $_ => 1 } @{ $task->tags };

        my $got_cat = 0;
        foreach my $cat (@$cats) {
            if ( $tags{$prefix.$cat} || $tags{$cat} ) {
                $stats{$cat}{abs} += $time;
                $got_cat = 1;
                last;
            }
        }
        $stats{_no_cat}{abs} += $time unless $got_cat;
    }

    while ( my ( $cat, $data ) = each %stats ) {
        $data->{percent} = sprintf( "%.1f", $data->{abs} / $total * 100 );
        $data->{nice} = $self->beautify_seconds( $data->{abs} );
    }

    $self->_say_current_report_interval;
    printf( "%39s\n", $self->beautify_seconds($total) );
    foreach my $cat ( sort keys %stats ) {
        my $data = $stats{$cat};
        printf( "%6s%%  %- 20s% 10s\n",
            $data->{percent}, $cat, $data->{nice} );
    }
}

sub _load_attribs_statistic {
    my ( $class, $meta ) = @_;
    $class->_load_attribs_worked($meta);
}

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TimeTracker::Command::Category - use categories when tracking time with App::TimeTracker

=head1 VERSION

version 1.003

=head1 DESCRIPTION

Define some categories, which act like 'Super-Tags', for example:
"feature", "bug", "maint", ..

=head1 CONFIGURATION

=head2 plugins

Add C<Category> to the list of plugins.

=head2 category

add a hash named C<category>, containing the following keys:

=head3 required

Set to a true value if 'category' should be a required command line option

=head3 categories

A list (ARRAYREF) of category names.

=head3 prefix

If set, add this prefix to the category when storing it as tag. Useful
to discern regular tags from category pseudo tags.

=head1 NEW COMMANDS

=head2 statistic

Print stats on time worked per category

    domm@t430:~/validad$ tracker statistic --last day
    From 2016-01-29T00:00:00 to 2016-01-29T23:59:59 you worked on:
                                   07:39:03
       9.9%  bug                   00:45:23
      33.2%  feature               02:32:21
      28.3%  maint                 02:09:52
      12.9%  meeting               00:59:21
      15.7%  support               01:12:06

You can use the same options as in C<report> to define which tasks you
want stats on (C<--from, --until, --this, --last, --ftag, --fproject, ..>)

=head1 CHANGES TO OTHER COMMANDS

=head2 start, continue, append

=head3 --category

    ~/perl/Your-Project$ tracker start --category feature

Make sure that 'feature' is a valid category and store it as a tag.

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
