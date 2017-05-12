# $Id: File.pm,v 1.5 2003/01/11 16:44:03 barbee Exp $

=head1 NAME

Apache::CVS::File - class that implements a versioned file 

=head1 SYNOPSIS

 use Apache::CVS::RcsConfig();
 use Apache::CVS::File();
 use Apache::CVS::Revision();

 $versioned_file = Apache::CVS::File->new($path, $rcs_config);
 $name = $versioned_file->name();
 $path = $versioned_file->path();
 $num_revisions = $versioned_file->revision_count();

 $revision_one = $versioned_file->revision('first');
 $revision_two = $versioned_file->revision('next');
 $revision_first = $versioned_file->revision('1.1');

=head1 DESCRIPTION

The C<Apache::CVS::File> class implements a typical CVS file.

=over 4

=cut

package Apache::CVS::File;
use strict;

use Rcs();
use Apache::CVS::RcsConfig();
use Apache::CVS::File();
use Apache::CVS::Revision();
@Apache::CVS::File::ISA = ('Apache::CVS::PlainFile');

$Apache::CVS::File::VERSION = $Apache::CVS::VERSION;;

=item Apache::CVS::File->new($path, $rcs_config)

Construct a new C<Apache::CVS::File> object. The first argument is the
full path of the file. The second is a RCS configuration object.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(shift);

    $self->{rcs} = undef;
    $self->{rcs_stale} = 1;
    $self->{current_revision} = 0;
    $self->{revision_count} = 0;
    $self->{rcs_config} = shift;

    bless ($self, $class);
    return $self;
}

sub current_revision {
    my $self = shift;
    $self->{current_revision} = shift if scalar @_;
    return $self->{current_revision};
}

sub rcs_config {
    my $self = shift;
    $self->{rcs_config} = shift if scalar @_;
    return $self->{rcs_config};
}

=item $versioned_file->rcs()

Get an Rcs object associated with this file.

=cut

sub rcs {
    my $self = shift;

    if (scalar @_) {
        $self->{rcs} = shift;
        $self->rcs_stale(0);
    }

    # in case the path of our File has changed
    if ((not $self->{rcs}) || $self->rcs_stale()) {
        $self->{rcs} = _setup_rcs($self->path(), $self->rcs_config());
        $self->rcs_stale(0);
    }

    return $self->{rcs};
}

=item $versioned_file->path([$new_path])

Get or set the path of this file.

=cut

sub path {
    my $self = shift;
    if ( scalar @_ ) {
        $self->{path} = shift;
        $self->{rcs_stale} = 1;
    }
    return $self->{path};
}

sub _find_adjacent_revision {
    my ($revision, $revisions, $increment) = @_;

    my $rev_num = $revision->number();
    my $index = 0;

    for ($index = 0; $revisions->[$index]; $index++) {
        last if ($revisions->[$index] eq $rev_num);
    }

    return $revisions->[--$index] if $increment;
    return $revisions->[++$index];
}

sub _revision_exists {
    my ($revisions, $revision) = @_;
    foreach my $current ( @{ $revisions } ) {
        if ( $current eq $revision ) {
            return 1;
        }
    }
    return 0;
}

sub _setup_rcs {
    my ($path, $config) = @_;
    my $rcs = Rcs->new($path);
    Rcs->bindir($config->binary());
    Rcs->arcext($config->extension());
    $rcs->workdir($config->working());
    return $rcs;
}

sub rcs_stale {
    my $self = shift;
    $self->{rcs_stale} = shift if scalar @_;
    return $self->{rcs_stale};
}

=item $versioned_file->revisions()

Returns a reference to a list of C<Apache::CVS::Revision> objects in no
particular order.

=cut

sub revisions {
    my $self = shift;

    my @revisions = map {
                        Apache::CVS::Revision->new($self->rcs(), $_)
                    } $self->rcs()->revisions;
    return \@revisions;
}

=item $versioned_file->revision($index)

Returns a C<Apache::CVS::Revision> object for the given index. The index
can be an absolute revision number (1.1, 1.2, 1.3.2.4) or one of the following:
first, next, prev, last. Using the 'next' index  on the first invocation of
this method result in the same thing as using 'first'. Similarly using 'prev'
on the first invocation is the same and using 'last'. If no revision can be
found, the method will return undef.

=cut

sub revision {
    my $self = shift;
    my $revision = shift;
    my $revision_number = undef;
    my @revisions;

    @revisions = $self->rcs()->revisions;
    $self->revision_count(scalar @revisions);

    if ( $revision eq 'first' ) {
        $revision_number = $revisions[-1];
    } elsif ( $revision eq 'next' ) {
        if ( $self->current_revision() ) {
            $revision_number =
                _find_adjacent_revision($self->current_revision(),
                                        \@revisions, 1);
        } else {
            # default to first if we do not already have a revision number
            $revision_number = $revisions[-1];
        }
    } elsif ( $revision eq 'prev' ) {
        if ($self->current_revision()) {
            $revision_number = 
                _find_adjacent_revision($self->current_revision(),
                                        \@revisions);
        } else {
            # default to last if we do not already have a revision number
            $revision_number = $revisions[0];
        }
    } elsif ( $revision eq 'last' ) {
        $revision_number = $revisions[0];
    } else {
        # else an absolute revision number has been given
        $revision_number = $revision;
    }

    # make sure revision exists
    unless ( _revision_exists(\@revisions, $revision_number) ) {
        return undef;
    } else {
        $self->current_revision(Apache::CVS::Revision->new($self->rcs(),
                                                           $revision_number));
    }
    return $self->current_revision();
}

=item $versioned_file->revision_count()

Returns the number of revision associated with this file.

=cut

sub revision_count {
    my $self = shift;
    $self->{revision_count} ||= $self->rcs()->revisions;
    return $self->{revision_count};
}

=item $versioned_file->name()

Returns the filename of this file.

=cut

sub name {
    my $self = shift;
    my $name = $self->SUPER::name(shift);
    my $ext = $self->rcs_config()->extension();
    $name =~ s/$ext//;
    return $name;
} 

=back

=head1 SEE ALSO

L<Apache::CVS>, L<Apache::CVS::File>, L<Apache::CVS::Revision>,
L<Apache::CVS::RcsConfig>

=head1 AUTHOR

John Barbee <F<barbee@veribox.net>>

=head1 COPYRIGHT

Copyright 2001-2002 John Barbee

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
