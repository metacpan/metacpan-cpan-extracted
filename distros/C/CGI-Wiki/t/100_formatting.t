use strict;
use CGI::Wiki;
use CGI::Wiki::TestConfig::Utilities;
use Test::More tests => (9 * $CGI::Wiki::TestConfig::Utilities::num_stores);

my %stores = CGI::Wiki::TestConfig::Utilities->stores;

my ($store_name, $store);
while ( ($store_name, $store) = each %stores ) {
    SKIP: {
            skip "$store_name storage backend not configured for testing", 9
            unless $store;

        my ($wiki, $cooked);

        # Test that a Wiki object created without an explicit formatter sets
        # defaults sensibly in its default formatter.
        $wiki = CGI::Wiki->new( store => $store );
        isa_ok( $wiki->formatter, "CGI::Wiki::Formatter::Default",
		"default formatter used if not specified" );
        # White box testing.
        foreach my $want_defined ( qw ( extended_links implicit_links
                                        allowed_tags macros node_prefix ) ) {
            ok( defined $wiki->{_formatter}{"_".$want_defined},
            "...default set for $want_defined" );
        }

        # Test that the implicit_links flag gets passed through right.
        my $raw = "This paragraph has StudlyCaps in.";
        $wiki = CGI::Wiki->new( store           => $store,
                                implicit_links  => 1,
                                node_prefix     => "wiki.cgi?node=" );

        $cooked = $wiki->format($raw);
        like( $cooked, qr!StudlyCaps</a>!,
          "StudlyCaps turned into link when we specify implicit_links=1" );

        $wiki = CGI::Wiki->new( store           => $store,
                                implicit_links  => 0,
                                node_prefix     => "wiki.cgi?node=" );

        $cooked = $wiki->format($raw);
        unlike( $cooked, qr!StudlyCaps</a>!,
            "...but not when we specify implicit_links=0" );

        # Test that we can use an alternative formatter.
        SKIP: {
            eval { require Test::MockObject; };
            skip "Test::MockObject not installed", 1 if $@;
            my $mock = Test::MockObject->new();
            $mock->mock( 'format', sub { my ($self, $raw) = @_;
                                         return uc( $raw );
                                       }
                        );
            $wiki = CGI::Wiki->new( store     => $store,
                                    formatter => $mock );
            $cooked = $wiki->format(
                                "in the [future] there will be <b>robots</b>");
            is( $cooked, "IN THE [FUTURE] THERE WILL BE <B>ROBOTS</B>",
                "can use an alternative formatter" );
        }
    }
}
