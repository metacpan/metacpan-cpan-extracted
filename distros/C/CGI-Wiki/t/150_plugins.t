use strict;
use CGI::Wiki::TestLib;
use Test::More;

if ( scalar @CGI::Wiki::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 9 * scalar @CGI::Wiki::TestLib::wiki_info );
}

my $iterator = CGI::Wiki::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    SKIP: {
        eval { require Test::MockObject; };
        skip "Test::MockObject not installed", 9 if $@;

        my $null_plugin = Test::MockObject->new;

        my $plugin = Test::MockObject->new;
        $plugin->mock( "on_register",
                       sub {
                           my $self = shift;
                           $self->{__registered} = 1;
                           $self->{__seen_nodes} = [ ];
                           }
                      );
        eval { $wiki->register_plugin; };
        ok( $@, "->register_plugin dies if no plugin supplied" );
        eval { $wiki->register_plugin( plugin => $null_plugin ); };
        is( $@, "",
     "->register_plugin doesn't die if plugin which can't on_register supplied"
          );
        eval { $wiki->register_plugin( plugin => $plugin ); };
        is( $@, "",
       "->register_plugin doesn't die if plugin which can on_register supplied"
          );
        ok( $plugin->{__registered}, "->on_register method called" );

        my @registered = $wiki->get_registered_plugins;
        is( scalar @registered, 2,
            "->get_registered_plugins returns right number" );
        ok( ref $registered[0], "...and they're objects" );

        my $regref = $wiki->get_registered_plugins;
        is( ref $regref, "ARRAY", "...returns arrayref in scalar context" );

        $plugin->mock( "post_write",
                       sub {
            my ($self, %args) = @_;
            push @{ $self->{__seen_nodes} },
                { name     => $args{node},
                  version  => $args{version},
                  content  => $args{content},
                  metadata => $args{metadata}
                };
                           }
        );

        $wiki->write_node( "Test Node", "foo", undef, {bar => "baz"} )
            or die "Can't write node";
        ok( $plugin->called("post_write"), "->post_write method called" );

        my @seen = @{ $plugin->{__seen_nodes} };
        is_deeply( $seen[0], { name => "Test Node",
                               version => 1,
                               content => "foo",
                               metadata => { bar => "baz" } },
                   "...with the right arguments" );
    }
}
