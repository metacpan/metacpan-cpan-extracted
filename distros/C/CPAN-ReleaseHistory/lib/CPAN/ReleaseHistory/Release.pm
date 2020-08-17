package CPAN::ReleaseHistory::Release;
$CPAN::ReleaseHistory::Release::VERSION = '0.16';
use Moo;
use CPAN::DistnameInfo;

has 'path'      => (is => 'ro');
has 'timestamp' => (is => 'ro');
has 'size'      => (is => 'ro');
has 'distinfo'  => (is => 'lazy');
has 'date'      => (is => 'lazy');

sub _build_distinfo
{
    my $self = shift;

    return CPAN::DistnameInfo->new($self->path);
}

sub _build_date
{
    my $self = shift;
    my @gmt  = gmtime($self->timestamp);

    return sprintf('%d-%.2d-%.2d', $gmt[5]+1900, $gmt[4]+1, $gmt[3]);
}

1;

=head1 NAME

CPAN::ReleaseHistory::Release - data object with information about one CPAN release

=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY>

=head1 REPOSITORY

L<https://github.com/neilbowers/CPAN-ReleaseHistory>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
