package App::Git::Ribbon;

our $VERSION = '0.003'; # VERSION

# ABSTRACT: Review the latest changes to a git repository

__END__

=pod

=encoding utf-8

=head1 NAME

App::Git::Ribbon - Review the latest changes to a git repository

=head1 SYNOPSIS

    ⚡ git ribbon --save
    ⚡ git pull
    ⚡ git ribbon
    Eric Johnson 6 weeks ago ecf43db
    Css tweaks.
    root/html/calculator/realCost.tt

    press 's' to skip 

    Eric Johnson 4 weeks ago 9595fa0
    fix css margin class.
    root/css/networth.css
    root/css/style.less
    root/css/style.less.old
    root/html/calculator/realCost.tt
    root/html/fi.tt

    press 's' to skip 

    Eric Johnson 2 weeks ago 5ef0fb2
    Added daysPerYear.
    lib/Networth/Controller/Calculator.pm
    lib/Networth/Out/RealCost.pm
    root/html/calculator/realCost.tt

    press 's' to skip 

    # The script will pause when it prints "press 's' to skip".  If you type
    # any key other than 's', you will be shown the diff using `git difftool`.

=head1 DESCRIPTION

This Perl script helps you review the latest changes to a git repository.

=head1 MOTIVATION

The way I used to review changes was by reading through the `git log`.  I try
to do this every morning at work to keep up with whats going on.  But I was
having a few problems:

=over 4

=item Its hard to know exactly which changes are new.

=item I want to review commits in the order they happened (instead of most recent first).

=item `git log` diff output can be hard to read and may not have enough context
-- sometimes I want a side by side diff like I get from `vimdiff` or `git
difftool`.

=back

Basically I wanted a quick and easy way to review the latest changes in a way
that feels a little more like an RSS feed.  So I wrote this script.

=head1 HOW TO USE IT

First mark your place with

    git ribbon --save

This will place a tag named _ribbon at origin/master.  Basically we are
bookmarking our current spot with a 'ribbon'.

Next, pull down the latest changes made by your fellow conspirators from the
remote repository.  

    git pull

To review those changes do the following:

    git ribbon

After you have reviewed all the changes, mark your place again with:

    git ribbon --save

=head1 PRO TIPS

In your .gitconfig add this:

    [diff]
        tool = vimdiff

For more, read `git help difftool` and `git help config`.

However the default colors for vimdiff were created by strange clowns.  So try
this instead:

    mkdir -p ~/.vim/colors/
    wget https://github.com/kablamo/dotfiles/blob/master/links/.vim/colors/iijo.vim -O ~/tmp/iijo.vim
    echo "colorscheme iijo" >> ~/.vimrc

Then learn how to use vimdiff:

=over 4

=item To open and close folds type `zo` and `zo`.  For more help type `:help fold-commands`.

=item To switch windows type `ctl-w l` and `ctl-w h`.  For more help type `:help window-move-cursor`.

=item To quickly exit vimdiff type `ZZ`.  

=back

=head2 Alternatives to vimdiff

If you don't want to invest the time just yet to learn vim, use an alternative like meld, opendiff,
p4merge, xxdiff, etc.  Side by side diffs are worth it!

=head1 INSTALLATION

L<cpanm|https://metacpan.org/module/App::cpanminus> is the standard tool the
Perl community uses to download and install Perl libraries from the
L<CPAN|https://metacpan.org/>.  The following should get you up and running
quickly:

    curl -L http://cpanmin.us | perl - --sudo App::cpanminus
    cpanm App::Git::Ribbon

=head1 SEE ALSO

This script was inspired by a great L<blog
post|http://gitready.com/advanced/2011/10/21/ribbon-and-catchup-reading-new-commits.html>
on gitready.com which has a number of awesome git tricks for both beginners and
advanced users.

I also ended up writing a L<vim plugin|https://github.com/kablamo/vim-ribbon>
that is probably better user experience if you very comfortable in vim.

=head1 AUTHOR

Eric Johnson <cpan at iijo dot nospamthanks dot org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Eric Johnson.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
