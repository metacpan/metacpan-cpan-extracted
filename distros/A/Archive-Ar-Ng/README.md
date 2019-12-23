# Archive::Ar [![Build Status](https://secure.travis-ci.org/jbazik/Archive-Ar.png)](http://travis-ci.org/jbazik/Archive-Ar)

Interface for manipulating ar archives.
New generation for manipulating large archives.

## INSTALL

The usual way

    perl Makefile.PL
    make
    make test
    make install

## SYNOPSIS

    use Archive::Ar::Ng;

    my $ar = Archive::Ar::Ng->new;

    $ar->read('./foo.ar');
    $ar->extract;

    $ar->add_files('./bar.tar.gz', 'bat.pl')
    $ar->add_data('newfile.txt','Some contents');

    $ar->chmod('file1', 0644);
    $ar->chown('file1', $uid, $gid);

    $ar->remove('file1', 'file2');

    my $filehash = $ar->get_content('bar.tar.gz');
    my $data = $ar->get_data('bar.tar.gz');
    my $handle = $ar->get_handle('bar.tar.gz');

    my @files = $ar->list_files();

    my $archive = $ar->write;
    my $size = $ar->write('outbound.ar');

    $ar->error();


## DESCRIPTION

Archive::Ar is a pure-perl way to handle standard ar archives.  

This is useful if you have those types of archives on the system, but it 
is also useful because .deb packages for the Debian GNU/Linux distribution are 
ar archives. This is one building block in a future chain of modules to build, 
manipulate, extract, and test debian modules with no platform or architecture 
dependence.

Archive::Ar::Ng is a storage based version of Archive::Ar

This version is useful, if you need to manipulate large files or Archives. It uses storage to avoid memory problems with those files.

## UPDATE INFORMATION

The new version works with storage instead of memory, so large files can be manipulated without running out of memory. 

## COPYRIGHT

Copyright 2019 - Fazekas Balint <fazekas.balint@mithrandir.hu>

Copyright 2019 - Varadi Gabor <varadi@mithrandir.hu>

Copyright 2009-2014 John Bazik <jbazik@cpan.org>.

Copyright 2003 Jay Bonci <jaybonci@cpan.org>. 

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html
