package App::DrivePlayer::Setup;

use parent 'ToolSet';

ToolSet->use_pragma('strict');
ToolSet->use_pragma('warnings');
ToolSet->use_pragma('utf8');

ToolSet->export(
    'Moo'             => undef,
    'Readonly'        => undef,
    'Types::Standard' => 'Str HashRef ArrayRef InstanceOf HasMethods CodeRef Bool Int Num Maybe',
    'YAML::Any'       => 'Dump',
);

1;

__END__

=head1 NAME

App::DrivePlayer::Setup - Common imports for all DrivePlayer modules

=head1 DESCRIPTION

A L<ToolSet> subclass that bundles the standard set of imports used across
DrivePlayer modules: L<Moo>, L<Readonly>, the C<strict>, C<warnings>, and
C<utf8> pragmas, and the most common L<Types::Standard> type constraints.

Every DrivePlayer Moo class starts with C<use App::DrivePlayer::Setup> instead of
listing these individually.

=cut
