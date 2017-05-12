package Beagle;
our $VERSION = '0.01';

1;

__END__

=head1 NAME

Beagle - an advanced way to manage/track/serve thoughts/articles/posts

=head1 SYNOPSIS

    $ beagle help
    $ beagle config --init
    $ beagle init /path/to/foo.git  --bare

    # if you already have one, you can follow it
    $ beagle follow /path/to/foo.git

    $ beagle article --title foo --body bar
    $ beagle ls
    $ beagle show ID1
    $ beagle update ID1
    $ beagle rm ID1
    $ beagle shell

    $ beagle pull
    $ beagle push

    $ beagle web

=head1 DESCRIPTION

So how do you manage your articles?  Before using C<Beagle>, I managed them
poorly: they were plain files messily living in the hard drive.

That way is not good, as I had to find the file's location before doing
something on it, which could be depressing if I couldn't remember the location
at all(it did happen for a few times), not to mention sharing or the version
control stuff.

L<git|http://git-scm.com/> is a great version control system. With it, you can
version control your files and share them easily, though C<git> itself
can't help you much of finding files' locations.

Things are more bothersome if you use some markup language such as C<Wiki> or
L<Markdown|http://daringfireball.net/projects/markdown/> in your posts.  It
would be awesome if you can get them converted to html automatically and check
if something is wrong before publishing.

C<Beagle> was born for this, and more.

=head1 SEE ALSO

L<Beagle::Manual::Tutorial>, L<Beagle::Manual::Cookbook>

=head1 AUTHOR

sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright 2011 sunnavy@gmail.com

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


