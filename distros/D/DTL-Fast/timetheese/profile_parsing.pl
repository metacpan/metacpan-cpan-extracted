#!/usr/bin/perl -I../lib/

use DTL::Fast qw(get_template);

for( my $i = 0; $i < 10000; $i++ )
{
    %DTL::Fast::TEMPLATES_CACHE = ();
    %DTL::Fast::OBJECTS_CACHE = ();
    my $tpl = get_template(
        'root.txt',
        'dirs' => [ './tpl' ]
    );
}

