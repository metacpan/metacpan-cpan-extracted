package App::PAUSE::CheckPerms;
$App::PAUSE::CheckPerms::VERSION = '0.05';
use 5.010;
use Moo;
use MooX::Options;

use PAUSE::Permissions 0.06;
use PAUSE::Packages 0.07;

option 'user'      => (is => 'ro', format => 's');

sub execute
{
    my $self = shift;
    my %perm;
    my %owner;
    my $packages;
    my ($signature, $previous_signature, $mismatch, %user);

    $self->_load_permissions(\%perm, \%owner);

    my $release_iterator = PAUSE::Packages->new()->release_iterator();

    my $bad_count = 0;

    RELEASE:
    while (my $release = $release_iterator->next_release) {
        if ($self->user) {
            my $seen_user = 0;
            my $USER      = uc($self->user);
            foreach my $module (@{ $release->modules }) {
                $seen_user = 1 if grep { $_ eq $USER } @{ $perm{$module->name} };
            }
            next RELEASE unless $seen_user;
        }

        $mismatch = 0;
        $previous_signature = undef;
        %user = ();
        foreach my $module (@{ $release->modules }) {
            $signature = join(' ', map { _capitalise_author($_, $module->name, \%owner) } @{ $perm{$module->name} });
            foreach my $pause_id (@{ $perm{$module->name} }) {
                $user{ $pause_id } = 1;
            }
            if (defined($previous_signature) && $signature ne $previous_signature) {
                $mismatch = 1;
                $bad_count++;
            }
            $previous_signature = $signature if !defined($previous_signature);
        }
        $self->_display_release($release, \%user, \%perm, \%owner) if $mismatch;
    }
    if ($bad_count > 0) {
        print "\n"
    } else {
        print "  all good\n";
    }
}

sub _display_release
{
    my $self    = shift;
    my $release = shift;
    my $usermap = shift;
    my $perm    = shift;
    my $owner   = shift;
    my @users   = sort keys %$usermap;
    my $maxlength = 0;
    my $entry;

    foreach my $module (@{ $release->modules }) {
        $maxlength = length($module->name) if length($module->name) > $maxlength;
    }

    print "\n", $release->distinfo->dist, "\n";
    foreach my $module (sort { $a->name cmp $b->name } @{ $release->modules }) {
        print '  ', $module->name;
        print ' ' x ($maxlength - length($module->name)) if (length($module->name) < $maxlength);
        print ' |';
        foreach my $user (@users) {
            print ' ';
            ($entry) = grep { $_ eq $user } @{ $perm->{$module->name} };
            if (defined($entry)) {
                print _capitalise_author($user, $module->name, $owner);
            } else {
                print ' ' x length($user);
            }
        }
        print "\n";
    }
}

sub _capitalise_author
{
    my $user   = shift;
    my $module = shift;
    my $owner  = shift;

    if (exists($owner->{ $module }) && $owner->{ $module } eq $user) {
        return uc($user);
    } else {
        return lc($user);
    }
}

sub _load_permissions
{
    my $self  = shift;
    my $perm  = shift;
    my $owner = shift;

    my $module_iterator = PAUSE::Permissions->new()->module_iterator();

    while (my $module = $module_iterator->next_module) {
        $perm->{ $module->name }  = [ $module->all_maintainers ];
        $owner->{ $module->name } = $module->owner if defined($module->owner);
    }
}

1;

=head1 NAME

App::PAUSE::CheckPerms - check if PAUSE permissions are consistent for all modules in a dist

=head1 SYNOPSIS

 use App::PAUSE::CheckPerms;
 
 my $app = App::PAUSE::CheckPerms->new_with_options();
 
 $app->execute();

=head1 DESCRIPTION

This module provides the functionality for the L<pause-checkperms> script.
Please look at that script's documentation for more details.

=head1 CAVEAT

This is my first attempt writing an App:: module and partner script using MooX::Options.
It feels all wrong, but I've been wanting to release a tool to do this for a while,
so I'm sucking it and seeing.

Feel free to suggest better ways to do this.

=head1 SEE ALSO

L<pause-checkperms>, L<PAUSE::Permissions>, L<PAUSE::Packages>,
L<App::PAUSE::Comaint>.

=head1 REPOSITORY

L<https://github.com/neilbowers/App-PAUSE-CheckPerms>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

