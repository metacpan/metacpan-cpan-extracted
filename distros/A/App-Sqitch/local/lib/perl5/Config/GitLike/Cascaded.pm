package Config::GitLike::Cascaded;
use Moo;
use Cwd;
use File::Spec;

extends 'Config::GitLike';

has 'cascade' => (
    default => sub { 1 },
    is => 'rw',
);

__PACKAGE__->meta->make_immutable;
no Moo;

1;

__END__

=head1 NAME

Config::GitLike::Cascaded - git-like config file parsing with cascaded inheritance

=head1 SYNOPSIS

This module exists purely for backwards compatibility; its use is
deprecated, and will be removed in a future release.

=head1 METHODS

=head2 cascade

This module simply defaults L<Config::GitLike/cascade> to a true value.

=head1 SEE ALSO

L<Config::GitLike|Config::GitLike>

=head1 LICENSE

You may modify and/or redistribute this software under the same terms
as Perl 5.8.8.

=head1 COPYRIGHT

Copyright 2010 Best Practical Solutions, LLC

=head1 AUTHORS

Alex Vandiver <alexmv@bestpractical.com>,
Christine Spang <spang@bestpractical.com>
