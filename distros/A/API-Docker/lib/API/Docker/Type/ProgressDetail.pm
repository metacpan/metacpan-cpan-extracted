package API::Docker::Type::ProgressDetail;
# ABSTRACT: The value of C<BuildInfo.progressDetail>
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker current => Int, wire => 'current';


docker total => Int, wire => 'total';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ProgressDetail - The value of C<BuildInfo.progressDetail>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ProgressDetail> definition of C<spec/v1.51.yaml>, which
the swagger leaves undescribed. Nothing in C<paths:> reaches it either; it
is the value of C<BuildInfo.progressDetail>,
C<CreateImageInfo.progressDetail> and C<PushImageInfo.progressDetail>. The
two numbers behind the C<progress> field of a build, pull or push event,
which the swagger describes as "a pre-formatted presentation of
progressDetail".

=head2 current

Undocumented upstream. How much is done. Absent from every event of
F<t/fixtures/images_pull_stream.ndjson>, where C<progressDetail> is an empty
object throughout. Serialised as C<current> -- spelled out, because deriving
it from the Perl name would produce C<Current>.

=head2 total

Undocumented upstream. How much there is to do, the other half of
L</current>. Serialised as C<total> -- spelled out, because deriving it from
the Perl name would produce C<Total>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-api-docker/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
