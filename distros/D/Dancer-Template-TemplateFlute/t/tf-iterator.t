use strict;
use warnings;
use Test::More tests => 1;
use Template::Flute;
use utf8;
binmode STDOUT, ":encoding(utf-8)";

my $spec =<<'EOF';
<specification>
<value name="select-wishlist" iterator="my_wishlists_dropdown"/>
</specification>
EOF

my $template =<<'EOF';
<select name="select-wishlist" class="select-wishlist btn-large" onchange='this.form.submit()'>
	<option></option>
</select>
EOF

sub iterator {
    return [{ label => "a",
              value => "b" },
            { label => "c",
              value => "d" }]
}


my $flute = Template::Flute->new(specification => $spec,
                                 template => $template,
                                 iterators => {
                                               my_wishlists_dropdown => iterator(),
                                              }
                                 );

eval {
     $flute->process;
};
ok(!$@, "No error with class and name with the same string") || diag $@;
