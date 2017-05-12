#!/usr/bin/perl
# Copyright (c) 2007-2009 David Caldwell,  All Rights Reserved. -*- perl -*-

package Darcs::Notify; use base qw(Class::Accessor::Fast); use strict; use warnings;
our $VERSION = '2.0.1';

Darcs::Notify->mk_accessors(qw(repo repo_name));

use Darcs::Inventory;
use Darcs::Inventory::Diff;
use Cwd;
use File::Basename;
use File::Copy "cp";

sub new($%) {
    my ($class, %option) = @_;
    my $self = bless { repo => $option{repo} || '.' }, $class;
    $self->{repo_name} ||= basename $self->{repo} eq '.' ? cwd : $self->{repo};

    # Remove the options we used from our options hash. What's left should only be notifiers.
    delete $option{$_} for keys %$self;
    for (keys %option) {
        my $class = "Darcs::Notify::$_";
        $class->isa('Darcs::Notify::Base') or eval "use $class; 1" or die "Couldn't load $_ ($class): $!\n";
        push @{$self->{notifier}}, $class->new(%{$option{$_}});
    }
    die "No notifiers passed to $class->new()! Please read the perldoc Darcs::Notify.\n" unless scalar @{$self->{notifier}};
    $self;
}

sub notify($){
    my ($self) = @_;
    mkdir "$self->{repo}/_darcs/third-party";
    mkdir "$self->{repo}/_darcs/third-party/darcs-notify";

    # This path is only here for legacy repos.
    my $old_inventory = "$self->{repo}/_darcs/third-party/darcs-notify-old-inventory";
    # http://www.mail-archive.com/darcs-users@darcs.net/msg01347.html
    $old_inventory = "$self->{repo}/_darcs/third-party/darcs-notify/old-inventory" unless -f $old_inventory;

    my $pre  = Darcs::Inventory->load($old_inventory);
    my $post = Darcs::Inventory->new($self->{repo}) or die "Couldn't get inventory from $self->{repo}";

    my ($new, $unpull) = Darcs::Inventory::Diff::diff($pre, $post);

    cp($post->file, $old_inventory);
    if (!$pre) {
        warn "Not sending any patch notifications on first run.\n".
            "'echo > \"$old_inventory\"' and re-run darcs-notify if you want notifications for your current ".
            scalar $post->patches, " patches.\n";
        return;
    }

    for (@{$self->{notifier}}) {
        $_->notify($self, $new, $unpull);
    }
    scalar @$new || scalar @$unpull;
}

1;
__END__

=head1 NAME

Darcs::Notify - Do something cool when a Darcs repository has patches added or removed

=head1 SYNOPSIS

 use Darcs::Notify;
 $n = Darcs::Notify->new(repo => "/path/to/my/repo",
                         Email => { # Autoloads Darcs::Notify::Email
                                    to => ["user1@example.com",
                                           "user2@example.com"],
                                    smtp_server => "smtp.example.com" });
 $n->notify;

 # If you have other plug-ins installed you can have many notifiers at once.
 Darcs::Notify->new(repo => "/path/to/my/repo",
                    Email => { # Autoloads Darcs::Notify::Email
                               to => ["user1@example.com",
                                      "user2@example.com"],
                               smtp_server => "smtp.example.com" },
                    IRC => { # Autoloads Darcs::Notify::IRC (if you have it)
                             server => irc.example.com,
                             channel => "#darcs_notify" })
     ->notify;

=head1 DESCRIPTION

B<Darcs::Notify> compares the list of patches in a darcs repository
against a saved backup copy (stored in the file
F<_darcs/third-party/darcs-notify/old-inventory>) and does "something
cool and useful" when it detects added or removed patches. I'm being
cagey about exactly what is done because Darcs::Notify lets you pass
in arbitrary notification methods so that you can customize it to you
liking. L<Darcs::Notify::Email> is the quintessential notifier that
sends email notifications to a list of email addresses.

Normal users will probably just want to use the command line script
L<darcs-notify>, which is a front end to L<Darcs::Notify> and
L<Darcs::Notify::Email>.

=head1 FUNCTIONS

=over 4

=item B<C<new(options, notifiers)>>

This creates a new Darcs::Notify object. All options and notifiers are
passed in hash-style.

The options are:

=over 4

=item B<repo> => "/path/to/my/repo"

Path to the base of the target darcs repository. Don't point to the
F<_darcs> directory, that will be added for you.

=item B<repo_name> => "my_repo"

By default C<&darcs_notify> will guess the name of the repo from the
path name. If you'd like to override its guess, pass in the repo_name
parameter.

=back

The notifiers are passed in the same way, but interpretted
differently. Take the following notify parameter example:

    Email => { smtp_address => "smtp.example.com" }

This will cause Darcs::Notify to try to load
L<Darcs::Notify::Email>. If that succeeds it will call
Darcs::Notify::Email->new(smtp_address => "smtp.example.com") and save the
resulting object in its list of notifiers.

In this manner you can extend Darcs::Notify with arbitrary
notification classes. See L<Darcs::Notify::Base> for more info.

=item B<C<notify()>>

This does the actual notifying. It will compute the differences
between the repo's current inventory and the last saved inventory and
call the notify function of the notifiers that were registered in the
B<new()> function.

=back

=head1 SEE ALSO

L<darcs-notify>, L<Darcs::Notify::Base>, L<Darcs::Notify::Email>,
L<Darcs::Inventory::Patch>, L<Darcs::Inventory>

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Copyright (C) 2007-2009 David Caldwell

=head1 AUTHOR

David Caldwell <david@porkrind.org>

=cut
