use strict;
use warnings;
use utf8;
use Test::More;
use Test::Base;
use Aozora2Epub::XHTML;
use Aozora2Epub::Gensym;
use lib qw/./;
use t::Util;

sub drop_nlsp {
    my $s = shift;
    $s =~ s/\n *//sg;
    $s =~ s/\n$//sg;
    $s;
}

filters {
    html => 'chomp',
    expected => ['chomp', 'drop_nlsp'],
};

run {
    my $block = shift;
    Aozora2Epub::Gensym->reset_counter;
    my $x = Aozora2Epub::XHTML->new_from_string($block->html);
    is($x->bib_info, $block->expected, $block->name);
};

done_testing;

__DATA__

=== normal
--- html
<div class="bibliographical_information">
<hr>
<br>
奥付<br>
ボランティアの皆さんです。<br>
<br>
<br>
</div>
--- expected
奥付<br />
ボランティアの皆さんです。

=== less br
--- html
<div class="bibliographical_information">
<hr>
<br>
底本
<br>
ボランティアの皆さんです。<br>
<br>
</div>
--- expected
底本<br />
ボランティアの皆さんです。

=== zenkaku space indentation
--- html
<div class="bibliographical_information">
<hr>
<br>
底本
<br>
　　　1985<br>
底本の親本<br>
　　　1906<br>
　　　　　　「國木田獨歩全集　第三卷」<br>
ボランティアの皆さんです。<br>
<br>
</div>
--- expected
底本
<br />
　　　1985<br />
底本の親本<br />
　　　1906<br />
　　　　　　「國木田獨歩全集　第三卷」<br />
ボランティアの皆さんです。
