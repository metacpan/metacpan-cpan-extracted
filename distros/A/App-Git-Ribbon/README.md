git-ribbon
==========

This Perl script helps you review the latest changes to a git repository.

How to use it
-------------

**First** mark your place with

    ⚡ git ribbon --save

This will place a tag named __ribbon at origin/master.  Basically we are
bookmarking our current spot with a 'ribbon'.

**Next**, pull down the latest changes made by your fellow conspirators from the
remote repository.  

    ⚡ git pull

To review those changes do the following:

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

The script will pause when it prints "press 's' to skip".  This gives you the
opportunity to view the diff with `git difftool` or skip that and move on to
the next revision.  

**Finally**, after you have reviewed all the changes, mark your place again with:

    git ribbon --save


Pro tips
--------

In your .gitconfig add this:

    [diff]
        tool = vimdiff
    
For more, read `git help difftool` and `git help config`.

However the default colors for vimdiff were created by insane clowns.  So try
this instead:

    ⚡ mkdir -p ~/.vim/colors/
    ⚡ wget https://github.com/kablamo/dotfiles/blob/master/links/.vim/colors/iijo.vim -O ~/tmp/iijo.vim
    ⚡ echo "colorscheme iijo" >> ~/.vimrc

Then learn how to use vimdiff:
 - To open and close folds type `zo` and `zo`.  For more help type `:help fold-commands`.
 - To switch windows type `ctl-w l` and `ctl-w h`.  For more help type `:help window-move-cursor`.
 - To quickly exit vimdiff type `ZZ`.  

See also
--------

This script was inspired by
http://gitready.com/advanced/2011/10/21/ribbon-and-catchup-reading-new-commits.html
