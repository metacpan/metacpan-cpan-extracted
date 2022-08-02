package App::Changelord::Role::ChangeTypes;
our $AUTHORITY = 'cpan:YANICK';
$App::Changelord::Role::ChangeTypes::VERSION = 'v0.0.1';
use v5.36.0;

use Moo::Role;

use feature 'try';

has change_types => (
    is => 'lazy',
);

sub _build_change_types($self) {
    no warnings;
    return eval {
        $self->changelog->{change_types};
    } || [
            { title => 'Features'  , level => 'minor', keywords => [ 'feat' ] } ,
            { title => 'Bug fixes' , level => 'patch', keywords => [ 'fix' ]  },
            { title => 'Package maintenance' , level => 'patch', keywords => [ 'chore', 'maint', 'refactor' ]  },
            { title => 'Statistics' , level => 'patch', keywords => [ 'stats' ]  },
        ]
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Changelord::Role::ChangeTypes

=head1 VERSION

version v0.0.1

=head1 AUTHOR

Yanick Champoux <yanick@babyl.ca>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
