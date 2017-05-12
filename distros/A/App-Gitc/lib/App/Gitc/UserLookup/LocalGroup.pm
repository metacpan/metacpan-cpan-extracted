package App::Gitc::UserLookup::LocalGroup;

use strict;
use warnings;

# ABSTRACT: App::Gitc::Util helper
our $VERSION = '0.60'; # VERSION

use App::Gitc::Util qw( project_config );

# Users are local users in a specific group.
sub users {
    my $group = project_config()->{ user_lookup_group };

    return split m{,}, ( getgrnam( $group ) )[3]
}

1;

__END__

=pod

=head1 NAME

App::Gitc::UserLookup::LocalGroup - App::Gitc::Util helper

=head1 VERSION

version 0.60

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Grant Street Group.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
