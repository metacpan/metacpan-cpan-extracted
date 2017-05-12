package App::Download;
$App::Download::VERSION = '1.0.1';

# ABSTRACT: download files from git version control system.


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Download - download files from git version control system.

=head1 VERSION

version 1.0.1

=head1 DESCRIPTION

Perl library App::Download contains script `download` that allows downloading
source code files from GitHub or some private version control system,
like GitHub Enterprise, Atlassian Stash or GitLab.

I'm using L<Carton> to install all perl libraries for my project, but
unfortunately it can't install perl libraries that are not on CPAN.
(L<https://github.com/perl-carton/carton/issues/132>)

I have some number of private perl libraries that can't be placed to CPAN,
but I need them in my private projects. So this is the workflow I'm using:

 * install everything what is needed for the project and for the private
libraries with L<Carton>

 * use script `download` to download the source code of all my private
libraries that are needed for the project.

So, this how to use this scipt (here I'm using my public library just for
example, in the real usage I use some private url to the library that is not
on CPAN).  If you run in you console:

    download \
        git@github.com:bessarabov/SQL-Easy.git \
        --commit 2.0.0 \
        --include_re ^lib/ \
        --to_dir sql-easy

The output will be something like:

    $ git clone git@github.com:bessarabov/SQL-Easy.git /var/folders/mn/l4xr6hqj1yd3h3tqnzmj4h5w0000gn/T/KXLHicbqif
    Cloning into '/var/folders/mn/l4xr6hqj1yd3h3tqnzmj4h5w0000gn/T/KXLHicbqif'...
    remote: Counting objects: 251, done.
    remote: Compressing objects: 100% (6/6), done.
    remote: Total 251 (delta 15), reused 13 (delta 13), pack-reused 232
    Receiving objects: 100% (251/251), 57.94 KiB | 0 bytes/s, done.
    Resolving deltas: 100% (97/97), done.
    $ cd /var/folders/mn/l4xr6hqj1yd3h3tqnzmj4h5w0000gn/T/KXLHicbqif; git checkout 2.0.0
    Note: checking out '2.0.0'.

    You are in 'detached HEAD' state. You can look around, make experimental
    changes and commit them, and you can discard any commits you make in this
    state without impacting any branches by performing another checkout.

    If you want to create a new branch to retain commits you create, you may
    do so (now or later) by using -b with the checkout command again. Example:

      git checkout -b new_branch_name

    HEAD is now at dc68701... 2.0.0
    Copying files
    lib/SQL/Easy.pm

The `git` binary is needed for the script to work.

=head1 AUTHOR

Ivan Bessarabov <ivan@bessarabov.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ivan Bessarabov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
