

package Dist::Zilla::Plugin::CommentToPod;
$Dist::Zilla::Plugin::CommentToPod::VERSION = '0.002';
# ABSTRACT: disstzilla plugin for App::CommentToPod - turns comments to pod

use Moose;
with(
	'Dist::Zilla::Role::FileMunger',
	'Dist::Zilla::Role::FileFinderUser' => {
		default_finders => [':InstallModules'],
	},
);

sub munge_files {
	my $self = shift;
	$self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
	my ($self, $file) = @_;

	$self->log_debug([ 'pod\'ing %s', $file->name ]);

	require App::CommentToPod;
	my $pm = App::CommentToPod->new;
	$pm->addPod($file->content);
	$file->content($pm->podfile);

	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::CommentToPod - disstzilla plugin for App::CommentToPod - turns comments to pod

=head1 VERSION

version 0.002

=head1 SYNOPSIS

=head2 Methods

=head1 NAME

Dist::Zilla::Plugin::CommentToPod

=head1 AUTHOR

Kjell Kvinge <kjell@kvinge.biz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Kjell Kvinge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
