package LM;
use base qw(Locale::Maketext);

package LM::en;
use base qw(LM);
our %Lexicon = (
    'Hello, [_1]' => 'Hello [_1]'
);

package DL::en;
our %Lexicon = (
    'Hello, [_1]' => 'Hello [_1]'
);

package main;
use strict;
use blib;
use Benchmark qw(cmpthese);
use Data::Localize;

my $loc = Data::Localize->new;
$loc->add_localizer(
    class => 'Namespace',
    namespaces => [ 'DL' ]
);
$loc->languages(['en']);

my $loc_gettext = Data::Localize->new;
$loc_gettext->add_localizer(
    class => 'Gettext',
    paths => [ 'tools/benchmark/gettext/*.po' ],
);
$loc_gettext->languages(['en']);

my $loc_gettext_bdb = Data::Localize->new;
$loc_gettext_bdb->add_localizer(
    class => 'Gettext',
    paths => [ 'tools/benchmark/gettext/*.po' ],
    storage_class => 'BerkeleyDB',
    storage_args => {
        dir => 'tools/benchmark'
    }
);
$loc_gettext_bdb->languages(['en']);
my $handle = LM->get_handle('en');

print "Running benchmarks with\n",
    "  Locale::Maketext: ", $Locale::Maketext::VERSION, "\n",
    "  Data::Localize:   ", $Data::Localize::VERSION, "\n",
;
cmpthese(-1, {
    'L::M' => sub {
        $handle->maketext('Hello, [_1]', 'John Doe');
    },
    'D::L(Namespace)' => sub {
        $loc->localize('Hello, [_1]', 'John Doe');
    },
    'D::L(Gettext)' => sub {
        $loc_gettext->localize('Hello, [_1]', 'John Doe');
    },
    'D::L(Gettext+BDB)' => sub {
        $loc_gettext_bdb->localize('Hello, [_1]', 'John Doe');
    },
});
