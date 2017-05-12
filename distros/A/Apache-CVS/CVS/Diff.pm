# $Id: Diff.pm,v 1.2 2002/04/23 04:18:28 barbee Exp $

=head1 NAME

Apache::CVS::Diff - class that implements a CVS diff

=head1 SYNOPSIS

 use Apache::CVS::File();
 use Apache::CVS::Diff();

 $diff = Apache::CVS::Diff->new($source, $target, $style);
 @content = @{ $diff->content() };

=head1 DESCRIPTION

The C<Apache::CVS::Diff> class implements a CVS diff. What you would get with
your plain 'ol cvs diff command.

=over 4

=cut

package Apache::CVS::Diff;

use strict;

$Apache::CVS::Diff::VERSION = $Apache::CVS::VERSION;;

=item $diff = Apache::CVS::Diff->new($source, $target, $styles)

Construct a new C<Apache::CVS::Diff> object. The first two arguments should be
instancesof C<Apache::CVS::Version>. The third is the arguments to rcsdiff(1).
The style defaults to 'ua'.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    $self->{source} = shift;
    $self->{target} = shift;
    $self->{style} = shift;
    $self->{default_style} = shift;
    $self->{content} = undef;

    bless ($self, $class);
    return $self;
}

=item $revision = $diff->source()

Returns the source revision of this diff.

=cut

sub source {
    my $self = shift;
    return $self->{source};
}

=item $revision = $diff->target()

Returns the target revision of this diff.

=cut

sub target {
    my $self = shift;
    return $self->{target};
}

sub load {
    my $self = shift;
    my @content;
    eval {
        @content =
            $self->source()->rcs()->rcsdiff('-' . $self->style() . ' -r' .
                                            $self->source()->number(), '-r' .
                                            $self->target()->number());
    };
    if ($@) {
        die 'Apache::CVS::Diff ' . $@;
    }
    $self->content(\@content);
}

=item $diff->style()

Returns or set the style of the diff.

=cut

sub style {
    my $self = shift;
    $self->{style} = shift if scalar @_;
    $self->{style} = 'ua' unless $self->{style};
    return $self->{style};
}

=item $diff->content()

Returns the contents of the diff as a references to an array of lines.

=cut

sub content {
    my $self = shift;
    $self->{content} = shift if scalar @_;
    $self->load() unless $self->{content};
    return $self->{content};
}

=back

=head1 SEE ALSO

L<Apache::CVS>, L<Apache::CVS::File>

=head1 AUTHOR

John Barbee <F<barbee@veribox.net>>

=head1 COPYRIGHT

Copyright 2001-2002 John Barbee

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
