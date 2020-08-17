#!/usr/local/bin/perl

use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if( $@ );

# pod_file_ok( './lib/CSS/Object.pm' );
# pod_file_ok( './lib/CSS/Object/Builder.pm' );
# pod_file_ok( './lib/CSS/Object/Comment.pm' );
# pod_file_ok( './lib/CSS/Object/Element.pm' );
# pod_file_ok( './lib/CSS/Object/Format.pm' );
# pod_file_ok( './lib/CSS/Object/Format/Inline.pm' );
# pod_file_ok( './lib/CSS/Object/Parser.pm' );
# pod_file_ok( './lib/CSS/Object/Parser/Default.pm' );
# pod_file_ok( './lib/CSS/Object/Parser/Enhanced.pm' );
# pod_file_ok( './lib/CSS/Object/Property.pm' );
# pod_file_ok( './lib/CSS/Object/Rule.pm' );
# pod_file_ok( './lib/CSS/Object/Rule/At.pm' );
# pod_file_ok( './lib/CSS/Object/Rule/Keyframes.pm' );
# pod_file_ok( './lib/CSS/Object/Selector.pm' );
# pod_file_ok( './lib/CSS/Object/Value.pm' );

all_pod_files_ok();