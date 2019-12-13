package CanvasCloud::API::Courses;
$CanvasCloud::API::Courses::VERSION = '0.007';
# ABSTRACT: extends L<CanvasCloud::API>

use Moose;
use namespace::autoclean;

extends 'CanvasCloud::API';


has course_id => ( is => 'ro', required => 1 );


augment 'uri' => sub {
    my $self = shift;
    my $rest = inner() || '';
    $rest = '/' if ( defined $rest && $rest && $rest !~ /^\// );
    return sprintf( '/courses/%s', $self->course_id ) . $rest;
};

sub get {
    my $self = shift;
    my $hash = shift || {};
    my $url = $self->uri;
    my ( $include );
    if ( exists $hash->{include} ) {
        my @accept = qw/needs_grading_count syllabus_body public_description total_scores current_grading_period_scores term account course_progress sections storage_quota_used_mb total_students passback_status favorites teachers observed_users all_courses permissions course_image/;
        for my $x ( @accept ) {
            if ( $hash->{include} eq $x ) {
                $include = $x;
                last;
            }
        }
    }
    $url .= '?include[]='.$include if ( $include );
    return $self->send( $self->request( 'GET',  $url ) );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CanvasCloud::API::Courses - extends L<CanvasCloud::API>

=head1 VERSION

version 0.007

=head1 ATTRIBUTES

=head2 course_id

I<required:> set to the user id for Canvas call

=head2 uri

augments base uri to append '/courses/course_id'

=head1 AUTHOR

Ted Katseres

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Ted Katseres.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
