# $Id: Revision.pm,v 1.5 2003/01/28 21:50:58 barbee Exp $

=head1 NAME

Apache::CVS::Revision - class that implements a CVS revision

=head1 SYNOPSIS

 use Rcs();
 use Apache::CVS::Revision();

 $revision = Apache::CVS::Revision->new($rcs, '1.2');

 $person_who_broke_build = $revision->author();
 $number =          $revision->number();
 $state =           $revision->state();
 $symbol =          $revision->symbol();
 $epoch =           $revision->date();
 $the_bright_idea = $revision->comment();
 %age =             %{ $revision->age() };
 $is_binary =       $revision->is_binary();
 $fh =              $revision->filehandle();
 $content =         $revision->content();
 $rcs =             $revision->rcs();

=head1 DESCRIPTION

The C<Apache::CVS::Revision> class implements a CVS revision.

=over 4

=cut

package Apache::CVS::Revision;

use strict;

$Apache::CVS::Revision::VERSION = $Apache::CVS::VERSION;

sub _new_rcs {
    my ($rcs, $revision) = @_;
    my $self = {};

    eval {
        $self->{rcs} = $rcs;
        $self->{number} = $revision;
        $self->{author} = $rcs->author($self->{number});
        $self->{state} = $rcs->state($self->{number});
        my @symbols = $rcs->symbol($self->{number});
        $self->{symbol} = \@symbols;
        $self->{date} = $rcs->revdate($self->{number});
        my %comments = $rcs->comments;
        $self->{comment} = $comments{$self->{number}};
    };
    if ( $@ ) {
        die "Apache::CVS::Revision : Received error from Rcs: $@\n";
    }
    return $self;
}

=item Apache::CVS::Revision->new($rcs, $revision_number)

Construct a new C<Apache::CVS::Revision>. The first argument is a instance
of the Rcs class. The second is the revision number of this revision.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = undef;

    $self = _new_rcs(shift, shift);

    $self->{co_file} = undef;

    bless ($self, $class);
    return $self;
}

sub co_file {
    my $self = shift;
    $self->{co_file} = shift if scalar @_;
    return $self->{co_file};
}

=item $revision->number()

Returns the number of the revision.

=cut

sub number {
    my $self = shift;
    $self->{number} = shift if scalar @_;
    return $self->{number};
}

=item $revision->author()

Returns the author of the revision.

=cut

sub author {
    my $self = shift;
    $self->{author} = shift if scalar @_;
    return $self->{author};
}

=item $revision->state()

Returns the state of the revision.

=cut

sub state {
    my $self = shift;
    $self->{state} = shift if scalar @_;
    return $self->{state};
}

=item $revision->symbol()

Returns the symbol of the revision.

=cut

sub symbol {
    my $self = shift;
    $self->{symbol} = shift if scalar @_;
    return $self->{symbol};
}

=item $revision->date()

Returns the date of the revision in Unix epoch time.

=cut

sub date {
    my $self = shift;
    $self->{date} = shift if scalar @_;
    return $self->{date};
}

=item $revision->comment()

Returns the comments associated with this revision.

=cut

sub comment {
    my $self = shift;
    $self->{comment} = shift if scalar @_;
    return $self->{comment};
}

sub time_diff {

    my ($later, $earlier) = @_;
    my $seconds_in_minute = 60;
    my $seconds_in_hour = $seconds_in_minute * 60;
    my $seconds_in_day = $seconds_in_hour * 24;

    return undef unless $later >= $earlier;

    my %time;

    my $diff = $later - $earlier;

    my $remainder = $diff % $seconds_in_day;
    $time{days} = ($diff - $remainder) / $seconds_in_day;
    $diff = $remainder;

    $remainder = $diff % $seconds_in_hour;
    $time{hours} = ($diff - $remainder) / $seconds_in_hour;
    $diff = $remainder;

    $remainder = $diff % $seconds_in_minute;
    $time{minutes} = ($diff - $remainder) / $seconds_in_minute;
    $time{seconds} = $remainder;

    return \%time;
}

=item $revision->age()

Returns a hash that indicates the age of the revision. The keys of this hash
are: days, hours, minutes, and seconds.

=cut

sub age {
    my $self = shift;
    return time_diff(time, $self->{date});
}

sub _checkout {
    my $self = shift;

    eval {
        $self->rcs()->co("-r" . $self->number());
        $self->co_file($self->rcs()->workdir . '/' . $self->rcs()->file);
    };

    if ($@) {
        die 'Apache::CVS::Revsion ' . $@;
    }
}

=item $revision->is_binary()

Returns true if the revision is binary and false otherwise.

=cut

sub is_binary {
    my $self = shift;
    $self->_checkout() unless $self->co_file();
    return -B $self->co_file();
}

=item $revision->filehandle()

Returns the filehandle of a checkout of this revision. The consumer is
is responsible for closing this filehandle once they are done.

=cut

sub filehandle {
    my $self = shift;
    $self->_checkout() unless $self->co_file();
    open FILE, $self->co_file();
    return *FILE;
}

=item $revision->content()

Returns the content of this revision as a string.

=cut

sub content {
    my $self = shift;
    $self->_checkout() unless $self->co_file();
    return undef if $self->is_binary();
    open FILE, $self->co_file();
    my $content = join '', <FILE>;
    close FILE;
    return $content;
}

=item $revision->rcs()

Returns the C<Rcs> object of this revision.

=cut

sub rcs {
    my $self = shift;
    return $self->{rcs};
}

sub DESTROY {
    my $self = shift;
    unlink $self->co_file();
    $self->{number} = undef;
    $self->{author} = undef;
    $self->{state} = undef;
    $self->{symbol} = undef;
    $self->{date} = undef;
    $self->{comment} = undef;
    $self->{rcs} = undef;
    $self->{co_file} = undef;
}

=back

=head1 SEE ALSO

L<Apache::CVS>, L<Rcs>

=head1 AUTHOR

John Barbee <F<barbee@veribox.net>>

=head1 COPYRIGHT

Copyright 2001-2002 John Barbee

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
