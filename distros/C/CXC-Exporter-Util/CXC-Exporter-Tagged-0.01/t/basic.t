#! perl

use Test2::V0;
use Import::Into;

use feature 'state';
use experimental 'signatures';

sub my::export ( $src, @args ) {
    state $package = 'Package000';
    ++$package;
    $src->import::into( $package, @args );
    $package;
}

our %export_tags;
BEGIN {
    %export_tags = ( 'bar' => ['foo'], default => ['bar'] );
}

package My::Exporter::Implicit {
    use CXC::Exporter::Tagged;
    use Exporter 'import';
    sub foo { 'bar' }
    sub bar { 'foo' }
    # this should get overwritten, so mess things up
    our %EXPORT_TAGS = ( snack => { foo => bar } );
    install_EXPORTS( {%::export_tags} );
}

package My::Exporter::Explicit {
    use CXC::Exporter::Tagged;
    use Exporter 'import';
    sub foo { 'bar' }
    sub bar { 'foo' }
    our %EXPORT_TAGS = %::export_tags;
    install_EXPORTS;
}

++$INC{'My/Exporter/Implicit.pm'};
++$INC{'My/Exporter/Explicit.pm'};

for my $class ( 'My::Exporter::Implicit', 'My::Exporter::Explicit' ) {

    subtest "$class" => sub {
        is( $class->my::export( 'foo' )->foo,        'bar', "symbol" );
        is( $class->my::export( ':bar' )->foo(),     'bar', "tag" );
        is( $class->my::export()->bar(),             'foo', "default" );
        is( $class->my::export( ':default' )->bar(), 'foo', "default tag" );

        like( dies{ $class->my::export( 'foo' )->bar },
              qr/object method "bar"/, "symbol foo doesn't import symbol bar" );

        like( dies{ $class->my::export( ':bar' )->bar },
              qr/object method "bar"/, "tag bar doesn't import symbol bar" );

        like( dies{ $class->my::export( )->foo },
              qr/object method "foo"/, "default doesn't import symbol foo" );

        like( dies{ $class->my::export( ':default' )->foo },
              qr/object method "foo"/, "default tag doesn't import symbol foo" );
    };

}

done_testing;
